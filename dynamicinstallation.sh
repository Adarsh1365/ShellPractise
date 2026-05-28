#!/bin/bash

LogDir="/home/ec2-user/shell-logs"
Logfile="$LogDir/mysql.log"
USER=$(id -u)

if [ $USER -ne 0 ]; then
    echo "please run the script using root access"
    exit 1
fi

if [ $# eq 0]; then
   echo "Please provide softwares to install as a parameters"
   echo "USAGE command sh $0 <software-1> <software-2>"
   exit 1
fi

validate()
{
  if [$1 -ne 0]; then
    echo "$2 is FAILED" | tee -a $Logfile
  else
    echo "$2 is SUCESS" | tee -a $Logfile
    exit 1
}


for software in $@
do
    dnf list installed $software &>> $Logfile
    if[ $? -ne 0]; then
      dnf install $software -y  &>> $Logfile
      validate $? "$software installation"
      systemctl enable mysqld &>> $Logfile
      systemctl start mysqld
      validate $? "$software starting"
    else
      echo "$software already installed...SKIPPNG" | tee -a $Logfile
    fi

done
