#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%h-%m-%s)

LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOGS_FOLDER

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "Please run this script with root priveleges" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$R $2 is...FAILED $N" | tee -a $LOG_FILE
    else
        echo -e "$G $2 is...SUCCESS $N" | tee -a $LOG_FILE
    fi
}

CHECK_ROOT

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

dnf install mysql-server -y &>> $LOG_FILE
VALIDATE $? "Installing Mysql-server"

systemctl enable mysqld &>> $LOG_FILE
VALIDATE $? "Enabled Mysql-server"

systemctl start mysqld &>> $LOG_FILE
VALIDATE $? "started Mysql-sever"

mysql -h mysql.daws100s.online -u root -pExpenseApp@1 -e 'show databases;' &>> $LOG_FILE

if [ $? -ne 0 ]
then 
    echo "MYSQL root password is not setup, setting now" &>> $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "setting up root password"
else
    echo -e "Mysql root password is already Setup...$Y skipping $N" | tee -a $LOG_FILE
fi