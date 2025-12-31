#!/bin/bash

LOGS_FOLDER=/var/log/expense
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%H-%M-%S)

mkdir -p $LOGS_FOLDER

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

USERID=$(id -u)

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then 
        echo "Please run this script with root privileges."
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

dnf list installed nginx &>>$LOG_FILE

if [ $? -ne 0 ]
then
    echo "Nginx is not installed, going to install it" | tee -a $LOG_FILE
    dnf install nginx -y &>>$LOG_FILE
    VALIDATE $? "Nginx installation"
else
    echo "Nginx is already installed, nothing to do...$Y SKIPPING $N" | tee -a $LOG_FILE
fi

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enablling nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removed files inside nginx path"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend application code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting frontend application code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting the nginx"

systemctl status nginx &>>$LOG_FILE
VALIDATE $? "Nginx status"

netstat -lntp &>>$LOG_FILE
VALIDATE $? "Frontend port 80 is running"

telnet backend.daws100s.online 8080 
VALIDATE $? "Frontend is connected to Backend"

ping backend.daws100s.online &>>$LOG_FILE
VALIDATE $? "Backend pinging"

ps -ef | grep nginx
VALIDATE $? "Frontend process nginx"