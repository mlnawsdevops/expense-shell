#!/bin/bash

LOGS_FOLDER=/var/log/expense
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%H-%M-%S)

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOGS_FOLDER

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "Please run this script with root privileges"
    fi
}

CHECK_ROOT

VALIDATE(){
    if [ $1 -ne 0 ]
    then    
        echo "$2 is...Failed"
    else
        echo "$2 is...Success"
    fi
}

dnf module disable nodejs -y

dnf module enable nodejs:20 -y

dnf list installed nodejs

if [ $? -ne 0 ]
then
    echo "nodejs is not installed...going to install it"
    dnf install nodejs -y
    VALIDATE $? "Installing nodejs"
else
    echo "nodejs is already installed, nothing to do..."
fi



