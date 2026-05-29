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

echo "disabling default nodejs" | tee -a $LOG_FILE
dnf module disable nodejs -y &>>$LOG_FILE
echo "disabled default nodejs" | tee -a $LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "enabling nodejs:20" | tee -a $LOG_FILE

echo "Installing nodejs" | tee -a $LOG_FILE
dnf install nodejs -y &>>$LOG_FILE
validate $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
  echo "Creating roboshop user" | tee -a $LOG_FILE
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  validate $? "Roboshop user created"
else
   echo "Roboshop user already exits...SKIPPING" | tee -a $LOG_FILE
fi

rm -rf /app &>>$LOG_FILE
validate $? "Removing existing code"

rm -rf /tmp/catalogue.zip &>>$LOG_FILE
validate $? "Removed catalogue zip"

mkdir -p /app &>>$LOG_FILE

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "downloaded and extracted code"

cd /app
npm install &>>$LOG_FILE
validate $? "Nodejs Dependencies installed"

cp catalogue.service /etc/systemd/system/
validate $? "copied system service service"

systemctl daemon-reload &>>$LOG_FILE
validate $? "deamon-reload"
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
validate $? "enabling catalouge"

cp mongo.repo /etc/yum.repos.d/
validate $? "copied mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
validate $? "Installing mongo clinet"

INDEX=$(mongosh --host mongodb.adarshdevopslearn.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $INDEX -lt 0 ]; then
    mongosh --host mongodb.adarshdevopslearn.online </app/db/master-data.js &>>$LOG_FILE
    validate $? "Load Products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

systemctl enable catalogue &>>$LOG_FILE
systemctl restart catalogue &>>$LOG_FILE
validate $? "Restarting catalogue"