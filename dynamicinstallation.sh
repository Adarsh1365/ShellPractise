#!/bin/bash

LogDir="/home/ec2-user/shell-logs"
Logfile="$LogDir/mysql.log"
TIMESTAMP= $("date +%y-%m-%d %H-%M-%S" )
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[30m"

USER=$(id -u)

if [ $USER -ne 0 ]; then
    echo $TIMESTAMP $R [ERROR] $N "please run the script using root access" | tee -a $Logfile
    exit 1
fi

if [ $# -eq 0 ]; then
   echo $TIMESTAMP $R [ERROR] $N "Please provide softwares to install as a parameters" | tee -a $Logfile
   echo "USAGE command sh $0 <software-1> <software-2>"
   exit 1
fi

validate()
{
  if [ $1 -ne 0 ]; then
    echo $TIMESTAMP $R [ERROR] $N "$2 is $R FAILED " | tee -a $Logfile
    exit 1
  else
    echo $TIMESTAMP $G [SUCCESS] $N "$2 is $G SUCESS" | tee -a $Logfile
  fi
}


for software in $@
do
    dnf list installed $software &>> $Logfile
    if [ $? -ne 0 ]; then
      echo "$software installation started"
      dnf install $software -y  &>> $Logfile
      validate $? "$software installation"
      systemctl enable mysqld &>> $Logfile
      systemctl start mysqld
      validate $? "$software starting"
    else
      echo "$software already installed...$Y SKIPPNG" | tee -a $Logfile
    fi

done

echo "Script ended running in $SECONDS seconds"