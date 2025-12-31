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

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then    
        echo "$2 is...Failed" | tee -a $LOG_FILE
        exit 1
    else
        echo "$2 is...Success" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs:20"

dnf list installed nodejs &>>$LOG_FILE

if [ $? -ne 0 ]
then
    echo "nodejs is not installed...going to install it" | tee -a $LOG_FILE
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing nodejs"
else
    echo -e "nodejs is already $Y installed, nothing to do...$N" | tee -a $LOG_FILE
fi

id expense | tee -a $LOG_FILE

if [ $? -ne 0 ]
then 
    echo "expense user is not added, going to added it..." | tee -a $LOG_FILE
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Expense user added"
else
    echo "expense user is already added, nothing to do..." | tee -a $LOG_FILE
fi


