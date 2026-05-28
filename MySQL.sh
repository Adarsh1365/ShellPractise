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
    echo "$2 failed....exiting now"
    exit 1
  else
    echo "$2 is successful"
  fi
}



dnf list installed mysql &>> $Logfile

if [ $? -eq 0 ] ; then
  echo "Mysql is already is installed....skipping now"
else
  echo "Installing mysql-server now"
  dnf install mysql-server -y &>> $Logfile
  Validate $? "Mysql installing"

  systemctl enable mysqld
  systemctl start mysqld
  validate $? "Mysql starting"
fi