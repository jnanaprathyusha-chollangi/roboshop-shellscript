#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop-shellscript"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}




dnf install mysql-server -y &>>$LOGS_FILE
VALIDATE $? "installing mysql server"

systemctl enable mysqld &>>$LOGS_FILE
VALIDATE $? "Enabling the mysql"

systemctl start mysqld  &>>$LOGS_FILE
VALIDATE $? "starting the mysql"

#get the password from the root user
mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Set up root password"


