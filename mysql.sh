#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(basename "$0" .sh)
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOGS_FOLDER

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT() {
    if [ $USERID -ne 0 ]; then
        echo -e "${R}Please run this script with root privileges${N}"
        exit 1
    fi
}

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 ... FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G $2 ... SUCCESS $N" | tee -a $LOG_FILE
    fi
}

CHECK_ROOT

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

dnf list installed mysql

if [ $? -ne 0 ]
then
    echo "Mysql is $R not installed, going to install it... $N"
    dnf install mysql-server -y &>>$LOG_FILE
    VALIDATE $? "Installing MySQL Server"

    systemctl enable mysqld &>>$LOG_FILE
    VALIDATE $? "Enabling MySQL Service"

    systemctl start mysqld &>>$LOG_FILE
    VALIDATE $? "Starting MySQL Service"
else
    echo "Mysql is already $Y installed, nothing to do...$N"
fi

mysql -h mysql.daws100s.online -u root -pExpenseApp@1 -e "show databases;" &>>$LOG_FILE

if [ $? -ne 0 ]; then
    echo "MySQL root password not set. Setting now..." | tee -a $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
    VALIDATE $? "Setting MySQL root password"
else
    echo -e "$Y MySQL root password already set... skipping $N" | tee -a $LOG_FILE
fi
