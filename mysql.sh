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

echo "Enter roo password"
read -s MYSQL_ROOT_PASSWORD
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

dnf install mysql-server -y
VALIDATE $? "Installing  MySql Server"

systemctl enable mysqld
systemctl start mysqld  
VALIDATE $? "Enabling and Starting MySql Server"


mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD
VALIDATE $? "Setting MySQL root password"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "Script execution completed successfully, $YELLOW time taken: $TOTAL_TIME seconds $NOCOLOR" | tee -a $LOG_FILE
