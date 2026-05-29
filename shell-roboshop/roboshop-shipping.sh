#!/bin/bash

MYSQL_HOST="mysql.adarshdevopslearn.online"
LOGDIR="/home/ec2-user/shell-logs"
sudo mkdir -p $LOGDIR
sudo chown -R ec2-user:ec2-user $LOGDIR
sudo chmod -R 755 $LOGDIR
sudo touch $LOGDIR/$0.log
LOG_FILE="$LOGDIR/$0.log"
SCRIPT_DIR=$PWD

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


dnf install maven -y
validate $? "Maven installing"

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

rm -rf /tmp/shipping.zip &>>$LOG_FILE
validate $? "Removed  zip"

mkdir -p /app &>>$LOG_FILE

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
cd /app
unzip /tmp/shipping.zip &>>$LOG_FILE
validate $? "downloaded and extracted code"

cd /app
mvn clean package &>>$LOG_FILE
validate $? "Maven dependies installed"
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
validate $? "Maven build application jar"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/
validate $? "copied system service"

systemctl daemon-reload &>>$LOG_FILE
validate $? "deamon-reload"
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
validate $? "enabling cart"

echo "Mysql client installing" | tee -a $LOG_FILE
dnf install mysql -y &>>$LOG_FILE
validate $? "mysql client installation"

mysql -h $MYSQL_HOST -u root -pAdarsh@1365 -e "use cities" &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
    validate $? "Data loaded"
else
    echo -e "Data already loaded ... $Y SKIPPING $N"
fi

systemctl enable shipping &>>$LOG_FILE
systemctl restart shipping &>>$LOG_FILE
validate $? "Restarting Shipping"