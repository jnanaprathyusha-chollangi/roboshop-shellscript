#!/bin/bash
ZONE_ID="Z10250571FYTWGH7ZIEN"

for instance in $@
do 
    INSTANCE_IDS=$(aws ec2 describe-instances \
        --filters \
        "Name=tag:Name,Values=$instance" \
        "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)

    if [ -z "$INSTANCE_IDS" ] ; then
        echo "No running instance found with name: $instance"
        exit 1
    else
        echo "Terminating instances: $INSTANCE_IDS"
        aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
    fi
    
done

CHANGE_BATCH=$(aws route53 list-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --query "ResourceRecordSets[?Type!='NS' && Type!='SOA']" \
    --output json | jq '{Changes: map({Action: "DELETE", ResourceRecordSet: .})}')

CHANGES_COUNT=$(echo "$CHANGE_BATCH" | jq '.Changes | length')

if [ "$CHANGES_COUNT" -eq 0 ]; then
    echo "No Route53 records to delete"
else
    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch "$CHANGE_BATCH"

    echo "Deleted all Route53 records except NS and SOA"
fi