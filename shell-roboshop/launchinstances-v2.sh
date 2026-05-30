#!/bin/bash
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID=Z00019002BVH3LOQYO0Q7
DOMAIN_NAME="adarshdevopslearn.online"
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
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ $USER -ne 0 ]; then
  echo "$TIMESTAMP $R[ERROR]$N Please run using sudo access" | tee -a $LOG_FILE
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "$TIMESTAMP $R[ERROR]$N Please provide atleast two parameters" | tee -a $LOG_FILE
  echo "USAGE sh $0 <create/delete> <instance1> <instance2> ..."
  exit 1
fi


validate(){
  if [ $1 -ne 0 ]; then
    echo "$TIMESTAMP $R[ERROR]$N $2...FAILED" | tee -a $LOG_FILE
    exit 1
  else
    echo "$TIMESTAMP $G[SUCCESS]$N $2...SUCCESS" | tee -a $LOG_FILE
  fi
}


if [ "$1" != "create" ] && [ "$1" != "destroy" ]; then
      echo "$TIMESTAMP $R[ERROR]$N first parameter should be either create or destroy" | tee -a $LOG_FILE
fi

Action=$1
shift

Get_Instanceid=$(aws ec2 describe-instances \
                     --filters "Name=tag:Name,Values=roboshop-$1" "Name=instance-state-name,Values=running" \
                     --query "Reservations[].Instances[].InstanceId" \
                     --output text)
for instance in $@
do
  Instance_id=$(Get_Instanceid $instance)
  if [ "$Action" == "create" ]; then
      if [ $Instance_id == "none" ]; then
        echo "$TIMESTAMP $instance is launching..." | tee -a $LOG_FILE
        INSTANCE_ID=$(aws ec2 run-instances \
                         --image-id $AMI_ID \
                         --instance-type t3.micro \
                         --security-groups "roboshop-common" "roboshop-$instance"  \
                         --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
                         --query 'Instances[0].InstanceId' \
                         --output text
                      )
        aws ec2 wait instance-running --instance-ids $INSTANCE_ID
      else
        echo "$TIMESTAMP $instance is already running with id: $Instance_id..nothing to do" | tee -a $LOG_FILE
      fi

      if [ "$instnace" == "frontend" ]; then
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
          echo "updated R53 record for: $instance"
  else
    if [ "$Instance_id" == "none" ]; then
      echo "$TIMESTAMP $instance is not available..nothing to do" | tee -a $LOG_FILE
      exit 1
    else
      echo "$TIMESTAMP Terminating $instance with $Instance_id" | tee -a $LOG_FILE
      aws ec2 terminate-instances \
          --instance-ids $Instance_id
    fi
  fi
done
