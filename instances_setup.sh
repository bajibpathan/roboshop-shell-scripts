#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0d72167c5d5dfcb1b"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch", "frontend")
# INSTANCES=("mongodb" "catalogue" "frontend")
ZONE_ID="Z04638081NLZ031HSLG68"
DOMAIN_NAME="robodevops.store"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

# To verify if we are able to connect to CLI
aws s3 ls &> /dev/null

if [ $? -ne 0 ]
then
    echo -e  "$RED ERROR:: Please verify aws access keys configuration $NOCOLOR"
else
    echo -e "$GREEN Connected to AWS..Instances creation is started. $NOCOLOR"

    for instance in ${INSTANCES[@]}
    do
        # create Instance
        INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t2.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)
        # echo "Instance ID ... $INSTANCE_ID"

        # obtain IP address of the instance
        if [ $instance != "frontend" ]
        then
            IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
            RECORD_NAME="$instance.$DOMAIN_NAME"
        else
            IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
            RECORD_NAME="$DOMAIN_NAME"
        fi
        echo "$instance IP address: $IP"
        echo "Record Name: $RECORD_NAME"

        # update the Domian Records
        aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
        {
            "Comment": "Creating or Updating a record set for cognito endpoint"
            ,"Changes": [{
            "Action"              : "UPSERT"
            ,"ResourceRecordSet"  : {
                "Name"              : "'$RECORD_NAME'"
                ,"Type"             : "A"
                ,"TTL"              : 1
                ,"ResourceRecords"  : [{
                    "Value"         : "'$IP'"
                }]
            }
            }]
        }'
    done
fi