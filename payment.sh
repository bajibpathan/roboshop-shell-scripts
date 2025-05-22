#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

# Check if the user has proper privileges to run the script
if [ $USERID -ne 0 ]
then
    echo -e "$RED ERROR:: Please run this script with root access $NOCOLOR" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access"  | tee -a $LOG_FILE
fi

# Create log folder
mkdir -p $LOGS_FOLDER
echo "Script started executing: $(date)" | tee -a $LOG_FILE

########################
# Funtion: Validation
# Purpose: Validate if the given package is installed or not
# Argument: Exit status & Package name
########################
VALIDATE(){
    if [ $? -eq 0 ]
    then
        echo -e "$2 is ... $GREEN SUCCESS $NOCOLOR"  | tee -a $LOG_FILE
    else
        echo -e "$2 is ...$RED FAILURE $NOCOLOR"  | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing Python3"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating a roboshop system user"
else
    echo -e "System user roboshop already created ... $YELLOW SKIPPING $NOCOLOR" 
fi


mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o  /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment code to temp directory"

rm -rf /app/*
cd /app 
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Extracting the payment code to /app directory"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing requirements"

cp $SCRIPT_DIR/services/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment.service to systemd"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd"

systemctl enable payment &>>$LOG_FILE
systemctl start payment &>>$LOG_FILE
VALIDTE $? "Enabling & starting Payment service"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "Script execution completed successfully, $YELLOW time taken: $TOTAL_TIME seconds $NOCOLOR" | tee -a $LOG_FILE
