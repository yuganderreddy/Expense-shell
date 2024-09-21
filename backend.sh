#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

LOGS_FOLDER="/var/log/backend"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOGS_FOLDER

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N"  | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo -e "Script started executing at: $G $(date)$N" | tee -a $LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "User expense is not exists, $R Creating now $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Creating user expense"
else
    echo -e "User expense already exists... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "created /app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloaded the backend application code to temp directory"

cd /app
rm -rf /app/*  #remove the existing code
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting the backend application code to temp directory"

npm install &>>$LOG_FILE
cp /home/ec2-user/Expense-shell/backend.service /etc/systemd/system/backend.service

#load the data before running backend
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installed mysql client"

mysql -h mysql.yuganderreddym.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reloaded"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enabled backend"

systemctl restart backend
VALIDATE $? "restarted backend"