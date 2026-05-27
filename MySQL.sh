#!/bin/bash

User=$(id -u)

if [ $User -ne 0 ]; then
  echo "Please run as a sudo user"
  exit 1
else
  echo "installing mysql"
fi

