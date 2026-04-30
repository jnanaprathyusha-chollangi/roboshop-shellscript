#!/bin/bash

SG_ID = "sg-059610db1385bb7db"
AMI_ID = "ami-0220d79f3f480ecf5"
instance_id = "i-039ccb02d1c79abfc"
ZONE_ID = Z10250571FYTWGH7ZIEN
DOMAIN_NAME = devopsd88s.online

for instance in $@
do
    instance_id = $(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyInstance}]' \
    --query 'Instances[0].PrivateIpAddress' \
    --output text)

    if [ $instance == "frontend" ]; then
        IP = $( aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[*].Instances[*].PublicIpAddress' \
            --output text)
        RECORD_NAME = "$DOMAIN_NAME" #devopsd88s.online
    else
        IP = $( aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[*].Instances[*].PrivateIpAddress' \
            --output text)
        RECORD_NAME = "$instance.DOMAIN_NAME" #Mongodb.devopsd88s.online
    fi
    echo "ID Address: $IP"
     aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating IP for the web server",
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'RECORD_NAME'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [
                    {
                        "Value": "'$IP'"
                    }
                    ]
            }
            }
        ]
    }
   '

done
