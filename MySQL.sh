#!/bin/bash

LogDir="/home/ec2-user/shell-logs"
Logfile="$LogDir/mysql.log"

User=$(id -u)
if [ $User -ne 0 ]; then
  echo "Please run using root acess"
  exit 1
fi

Validate()
{
  if [ $1 -ne 0 ] ; then
    echo "$2 FAILED....exiting now" | tee -a $Logfile
    exit 1
  else
    echo "$2 is SUCCESS" | tee -a $Logfile
  fi
}



dnf list installed mysql-server &>> $Logfile

if [ $? -eq 0 ] ; then
  echo "Mysql is already is installed....SKIPPING" | tee -a $Logfile
else
  echo "Installing mysql-server now" | tee -a $Logfile
  dnf install mysql-server -y &>> $Logfile
  Validate $? "Mysql installing"

  systemctl enable mysqld &>> $Logfile
  systemctl start mysqld
  Validate $? "Mysql starting"
fi