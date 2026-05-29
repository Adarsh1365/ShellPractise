#!/bin/bash

LOGDIR="/home/ec2-user/shell-logs"
sudo mkdir -p $LOGDIR
sudo chown -R ec2-user:ec2-user $LOGDIR
sudo chmod -R 755 $LOGDIR
sudo touch $LOGDIR/$0.log
LOG_FILE="$LOGDIR/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

USER=$(id -u)

if [ $USER -ne 0 ]; then
  echo -e "$TIMESTAMP $R [ERROR] $N Please run script using root access" | tee -a $LOG_FILE
  exit 1
fi

validate(){
  if [ $1 -ne 0 ]; then
    echo -e " $TIMESTAMP $R [ERROR] $N $2..is FAILED" | tee -a $LOG_FILE
    exit 1
  else
    echo -e "$TIMESTAMP $G [SUCCESS] $N $2 ..is SUCCESS" | tee -a $LOG_FILE
  fi
}


cp rabbitmq.repo /etc/yum.repos.d/
validate $? "Adding repo file"

echo "Installing rabbitmq-server"
dnf install rabbitmq-server -y &>> $LOG_FILE
validate $? "Installing rabbitmq"

systemctl enable rabbitmq-server &>> $LOG_FILE
systemctl start rabbitmq-server &>> $LOG_FILE
validate $? "Enabling and starting rabbitmq"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "creating rabbitmq user"