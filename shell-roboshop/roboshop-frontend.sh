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

echo "Installing NGINX"
dnf module disable nginx -y &>>$LOG_FILE
dnf module enable nginx:1.24 -y &>>$LOG_FILE
dnf install nginx -y &>>$LOG_FILE &>>$LOG_FILE
validate $? "nginx installation"

rm -rf /usr/share/nginx/html/*
validate $? "Removing ngnix default page"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $LOG_FILE
validate $? "downloaded and extracted code"

rm -rf /etc/nginx/nginx.conf
validate $? "Removed Default conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
validate $? "Copied roboshop nginx conf"

systemctl daemon-reload &>>$LOG_FILE
validate $? "deamon-reload"
systemctl restart nginx &>>$LOG_FILE
systemctl enable nginx &>>$LOG_FILE
validate $? "enabling nginx"
