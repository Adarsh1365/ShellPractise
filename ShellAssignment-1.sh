#!/bin/bash
Mentor=$1
echo "Hello, World!"
echo "Today is $(date)"
echo "Current user: $(id -u)"
#echo "Current directory: $(pwd)"
#echo "Files in current directory:"
echo "$Mentor is the mentor"
echo "$Mentor : please enter your username"
read username
echo "$username : please enter your password"
read -s password
echo "Username: $username"
echo "Password: $password"