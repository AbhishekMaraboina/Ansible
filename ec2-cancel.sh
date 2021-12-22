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

CANCEL_INSTANCE() {
  ## Check if instance is already there

  SPOTINSTID=$(aws ec2 describe-spot-instance-requests --filters "Name=tag:Name,Values=${COMPONENT}" | jq .SpotInstanceRequests[].SpotInstanceRequestId | sed 's/"//g' | grep -v null)

  aws ec2 describe-spot-instance-requests --filters "Name=tag:Name,Values=${COMPONENT}" | jq .SpotInstanceRequests[].State | sed 's/"//g' | grep -E 'active'
  if [ $? -eq -0 ]; then
    aws ec2 cancel-spot-instance-requests --spot-instance-request-ids ${SPOTINSTID}
  else
    echo -e "\e[1;33mInstance is already cancelled\e[0m"
  fi

  sleep 10
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