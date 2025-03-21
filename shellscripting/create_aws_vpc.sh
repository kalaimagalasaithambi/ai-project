#!bin/bash

##############################
# Create AWS VPC
# - create a VPC with a public subnet
# - Check if the user has AWS CLI installed and configured, user may be using linux, mac or windows
# - Read the input from the user if "create", check VPC existing or not and create if not
# - Read the input from the user if "teardown", check VPC existing or not and delete if existing
####################################

# variables
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.3.0/24"
REGION="us-east-1"
VPC_NAME="ai-asssis-vpc"
SUBNET_NAME="ai-assist-subnet"
SUBNET_AZ="us-east-1a"

# Verify if AWS CLI is installed 
if ! command -v aws &> /dev/null
then
    echo "AWS CLI could not be found. Please install it and configure it."
    exit
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null
then
    echo "AWS CLI is not configured. Please configure it using 'aws configure'."
    exit
fi

#check if user wants to create or teardown
if [ "$1" == "teardown" ]; then
    echo "Tearing down VPC..."
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text)
    if [ "$VPC_ID" == "None" ]; then
        echo "VPC with name $VPC_NAME does not exist."
        exit
    fi
    # Delete Subnet
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$SUBNET_NAME" --query 'Subnets[0].SubnetId' --output text)
    if [ "$SUBNET_ID" != "None" ]; then
        aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
        echo "Subnet with name $SUBNET_NAME deleted."
    fi
    # Delete VPC
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
    echo "VPC with name $VPC_NAME deleted."
    exit
fi

if [ "$1" == "create" ]; then
    echo "Creating VPC..."
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text)
    if [ "$VPC_ID" != "None" ]; then
        echo "VPC with name $VPC_NAME already exists."
        exit
    fi
    # Create VPC
    VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME --region $REGION
    echo "VPC with name $VPC_NAME created with ID $VPC_ID."
    # Create Subnet
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --availability-zone $SUBNET_AZ --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=$SUBNET_NAME --region $REGION
    echo "Subnet with name $SUBNET_NAME created with ID $SUBNET_ID."
    exit
fi

# end of script