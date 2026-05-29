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

echo "Installing python"
dnf install python3 gcc python3-devel -y
validate $? "Python installation"

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

rm -rf /tmp/payment.zip &>>$LOG_FILE
validate $? "Removed  zip"

mkdir -p /app &>>$LOG_FILE

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
cd /app
unzip /tmp/payment.zip &>>$LOG_FILE
validate $? "downloaded and extracted code"

cd /app
pip3 install -r requirements.txt
validate $? "Dependencies installation"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/
validate $? "copied system service"

systemctl daemon-reload &>>$LOG_FILE
validate $? "deamon-reload"
systemctl enable payment &>>$LOG_FILE
systemctl start payment &>>$LOG_FILE
validate $? "enabling payment"
