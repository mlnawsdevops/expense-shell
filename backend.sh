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
    echo -e "expense user is already added, nothing to do...$Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting backend application code"

npm install &>>$LOG_FILE

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing Mysql"

mysql -h mysql.daws100s.online -u root -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema Loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabling backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarted backend"

systemctl status backend | tee -a $LOG_FILE
VALIDATE $? "Backend status"

netstat -lntp &>>$LOG_FILE
VALIDATE $? "Backend port 8080"

ps -ef | grep nodejs &>>$LOG_FILE
VALIDATE $? "Backend process"





