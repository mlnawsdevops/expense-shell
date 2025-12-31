#!/bin/bash

LOGS_FOLDER=/var/log/expense
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%H-%M-%S)

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

USERID=$(id -u)

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then 
        echo "Please run this script with root privileges"
        exit 1
    fi
}

CHECK_ROOT

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo "$2 is...Failed" | tee -a $LOG_FILE
    else
        echo "$2 is...Success" | tee -a $LOG_FILE
    fi
}

echo "Script started execution at: $(date)" | tee -a $LOG_FILE

dnf list installed nginx 

if [ $? -ne 0 ]
then
    echo "Nginx is not installed, going to install it"
    dnf install nginx -y
    VALIDATE $? "Nginx installation"
else
    echo "Nginx is already installed, nothing to do...$Y SKIPPING $N"
fi

systemctl enable nginx
VALIDATE $? "Enablling nginx"

systemctl start nginx
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removed files inside nginx path"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "Downloading frontend application code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting frontend application code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf

systemctl restart nginx
VALIDATE $? "Restarting the nginx"

netstat -lntp 
VALIDATE $? "Frontend port 80 is running"

telnet backend.daws100s.online 8080
VALIDATE $? "Frontend is connected to Backend"

ping backend.daws100s.online
VALIDATE $? "Backend pinging"

ps -ef | grep nginx
VALIDATE $? "Frontend process nginx"