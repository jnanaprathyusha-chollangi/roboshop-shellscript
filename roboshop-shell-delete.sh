#!/bin/bash
ZONE_ID=Z10250571FYTWGH7ZIEN

for instance in $@
do 
    INSTANCE_IDS=$(aws ec2 describe-instances \
        --filters \
        "Name=tag:Name,Values=$NAME" \
        "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)

    if [ -z "$INSTANCE_IDS" ] ; then
        echo "No running instance found with name: $NAME"
        exit 1
    else
        echo "Terminating instances: $INSTANCE_IDS"
        aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
    fi
    
done

aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch "$(aws route53 list-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --query "ResourceRecordSets[?Type!='NS' && Type!='SOA']" \
        --output json | jq '{Changes: map({Action: "DELETE", ResourceRecordSet: .})}')"

echo "Deleted all R53 Records other than NS and SOA Types"