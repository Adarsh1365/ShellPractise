#!/bin/bash

LOGDIR="/home/ec2-user/shell-logs"
sudo mkdir -p $LOGDIR
sudo chown -R ec2-user:ec2-user $LOGDIR
sudo chmod -R 755 $LOGDIR
sudo touch $LOGDIR/$0.log
LOG_FILE= "$LOGDIR/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "%Y-%m-%d %H:%M:%S")

USER=$(id -u)

if [ $USER -ne 0 ]; then
  echo -e "$TIMESTAMP $R [ERROR] $N Please run script using root access" | tee $LOG_FILE
  exit 1
fi

validate(){
  if [ $1 -eq 0]; then
    echo -e " $TIMESTAMP $R [ERROR] $N $2..is FAILED" | tee $LOG_FILE
    exit 1
  else
    echo -e "$TIMESTAMP $G [SUCCESS] $N $2 ..is SUCCESS" | tee $LOG_FILE
  fi
}


cp mongo.repo /etc/yum.repos.d/
validate $? "Adding repo file"

dnf install mongodb-org -y &>> $LOG_FILE
validate $? "Installing Mongodb"

systemctl enable --now mongod &>> $LOG_FILE
validate $? "Enabling Mongodb"

sed -i '/s/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "Setting/allowing remote access ip config"

systemctl restart mongod
validate $? "Restarting mongodb"