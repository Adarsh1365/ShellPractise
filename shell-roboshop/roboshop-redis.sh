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
echo "Disabling default redis"
dnf module disable redis -y &>>$LOG_FILE
echo "Disabled default redis"
echo "Enabling redis:7"
dnf module enable redis:7 -y &>>$LOG_FILE
validate $? "Enabling redis:7"

echo "Installing redis" | tee -a $LOG_FILE
dnf install redis -y &>>$LOG_FILE
validate $? "Installing redis:7"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "Setting/allowing remote access ip config and changing protected mode"

systemctl enable redis &>>$LOG_FILE
systemctl start redis &>>$LOG_FILE
validate $? "Starting redis"