#!/bin/bash

LogDir="/ec2-user/shell-logs"
Logfile="$LoDir/MysqlInstallingLog.log"

User=$(id -u)

Validate()
{
  if [ $1 -ne 0 ] ; then
    echo "$2 installation failed....exiting now"
    exit 1
  else
    echo "$2 installation is successful"
  fi
}

if [ $User -ne 0 ]; then
  echo "Please run using root acess"
  exit 1
fi

dnf list installed mysql &>> $Logfile

if [ $? -ne 0 ] ; then
  echo "Mysql is already is installed....skipping now"
else
  echo "Installing mysql now"
  dnf install mysql-server -y &>> $Logfile
  Validate $? "Mysql"
fi