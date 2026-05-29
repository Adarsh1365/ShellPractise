#!/bin/bash
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID=Z00019002BVH3LOQYO0Q7
DOMAIN_NAME="adarshdevopslearn.online "
LOGDIR="\home\ec2-user\shell-logs"
sudo mkdir -p $LOGDIR
sudo chown -R ec2-user:ec2-user $LOGDIR
sudo chmod -R 755 $LOGDIR
sudo touch $LOGDIR/$0.log
LOG_FILE="$LOGDIR/$0.log"

USER=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "%Y-%m-%d %H:%M:%S")

if [ $USER -ne 0 ]; then
  echo "$TIMESTAMP $R[ERROR]$N Please run using sudo access" | tee -a $LOG_FILE
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "$TIMESTAMP $R[ERROR]$N Please provide atleast one instance names as parameters" | tee -a $LOG_FILE
  exit 1
fi

validate(){
  if [ $1 -ne 0 ]; then
    echo "$TIMESTAMP $R[ERROR]$N $2...FAILED" | tee -a $LOG_FILE
    exit 1
  else
    echo "$TIMESTAMP $G[SUCCESS]$N $$2...SUCCESS" | tee -a $LOG_FILE
  fi
}

for INSTANCE in $@
do
  echo "lanuching $INSTANCE instance now...."
  INSTANCE_ID=$(aws ec2 run-instances \
                 --image-id $AMI_ID \
                 --instance-type t3.micro \
                 --security-groups "roboshop-common" "roboshop-$INSTANCE"  \
                 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$INSTANCE}]" \
                 --query 'Instances[0].InstanceId' \
                 --output text
              )
  echo "Instance id: $INSTANCE_ID" | tee -a $LOG_FILE

  if [ -z $INSTANCE_ID ]; then
    echo "$TIMESTAMP $R[ERROR]$N Instance creation Failed" | tee -a $LOG_FILE
    exit 1
  fi
  if [ $INSTANCE == frontend ]; then
          IP=$(aws ec2 describe-instances \
          --instance-ids $INSTANCE_ID \
          --query "Reservations[].Instances[].PublicIpAddress" \
          --output text
          )
          echo "IP adress: $IP"
          S3RECORD="$DOMAIN_NAME"
          echo "$S3RECORD"
  else
         IP=$(aws ec2 describe-instances \
                --instance-ids $INSTANCE_ID \
                --query "Reservations[].Instances[].PrivateIpAddress" \
                --output text
                )
          echo "IP adress: $IP"
          S3RECORD="$INSTANCE.$DOMAIN_NAME"
          echo "$S3RECORD"
  fi

  aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch '
      {
          "Comment": "Update a record to new IP",
          "Changes": [
          {
              "Action": "UPSERT",
              "ResourceRecordSet": {
                  "Name": "'$S3RECORD'",
                  "Type": "A",
                  "TTL": 1,
                  "ResourceRecords": [
                      { "Value": "'$IP'" }
                  ]
              }
          }]
      }'

done