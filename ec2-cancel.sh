#!/bin/bash

# Cancel an SPOT instance

if [ -z "$1" ]; then
  echo -e "\e[1;31mInput is missing\e[0m"
  exit 1
fi

COMPONENT=$1
ENV=$2

if [ ! -z "$ENV" ]; then
  ENV="-${ENV}"
fi

ZONE_ID=Z025090326LF7AZJH4M51

CANCEL_INSTANCE() {
  ## Check if instance is already Cancelled

  INSTID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${COMPONENT}" | jq .Reservations[].Instances[].InstanceId | sed 's/"//g' | grep -v null)
  echo -e "${INSTID}"
  aws ec2 describe-instances --filters "Name=tag:Name,Values=${COMPONENT}" | jq .Reservations[].Instances[].State.Name | sed 's/"//g' | grep E 'running|stopped'
  if [ $? -eq -0 ]; then
    aws ec2 terminate-instances --instance-ids ${INSTID}
  else
    echo -e "\e[1;33mInstance is already cancelled\e[0m"
  fi

  SPOTINSTID=$(aws ec2 describe-spot-instance-requests --filters "Name=tag:Name,Values=${COMPONENT}" | jq .SpotInstanceRequests[].SpotInstanceRequestId | sed 's/"//g' | grep -v null)
#  INSTID=$(aws ec2 describe-spot-instance-requests --filters "Name=tag:Name,Values=${COMPONENT}" | jq .SpotInstanceRequests[].InstancetId | sed 's/"//g' | grep -v null)
  aws ec2 describe-spot-instance-requests --filters "Name=tag:Name,Values=${COMPONENT}" | jq .SpotInstanceRequests[].State | sed 's/"//g' | grep -E 'active'
  if [ $? -eq -0 ]; then
    aws ec2 cancel-spot-instance-requests --spot-instance-request-ids ${SPOTINSTID}
  else
    echo -e "\e[1;33mInstance is already cancelled\e[0m"
  fi

  sleep 10
  IPADDRESS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${COMPONENT}" | jq .Reservations[].Instances[].PrivateIpAddress | sed 's/"//g' | grep -v null)

  # Update the DNS record
  sed -e "s/IPADDRESS/${IPADDRESS}/" -e "s/COMPONENT/${COMPONENT}/" record.json >/tmp/recordD.json
  aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/recordD.json | jq
}

if [ "$COMPONENT" == "all" ]; then
  for comp in frontend mongodb catalogue redis user cart mysql shipping rabbitmq payment dispatch ; do
    COMPONENT=$comp$ENV
    CANCEL_INSTANCE
  done
else
  COMPONENT=$COMPONENT$ENV
  CANCEL_INSTANCE
fi