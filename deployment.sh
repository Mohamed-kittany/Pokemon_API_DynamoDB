#!/bin/bash

# deployment.sh

# Set variables
KEY_NAME="MyKeyPair"
AMI_ID="ami-0b20a6f09484773af"
INSTANCE_TYPE="t2.micro"
REPO_URL="https://github.com/Mohamed-kittany/Pokemon_API_DynamoDB.git"
INSTANCE_TAG="PokemonAppInstance"
TABLE_NAME="PokemonTable"
REGION="us-west-2"
VPC_TAG="PokemonVPC"
SUBNET_TAG="PokemonSubnet"
SECURITY_GROUP_TAG="PokemonSecurityGroup"
IGW_TAG="PokemonIGW"
ROUTE_TABLE_TAG="PokemonRouteTable"

# Create a new key pair
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem

# Create a new VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $REGION --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_TAG

# Create a subnet
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --region $REGION --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=$SUBNET_TAG

# Create a security group
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name MySecurityGroup --description "My security group" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
aws ec2 create-tags --resources $SECURITY_GROUP_ID --tags Key=Name,Value=$SECURITY_GROUP_TAG

# Authorize security group ingress
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create an Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=$IGW_TAG

# Create a route table
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $ROUTE_TABLE_ID --tags Key=Name,Value=$ROUTE_TABLE_TAG

# Create a route to the Internet Gateway
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# Associate the route table with the subnet
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID

# Create an EC2 instance
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --region $REGION --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_TAG}]" --query 'Instances[0].InstanceId' --output text)

echo "Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# # Get the public IP address of the instance
# PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
# echo "Instance is running. Public IP is $PUBLIC_IP"

# Get the public DNS name of the instance
PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[*].Instances[*].PublicDnsName" --output text)

echo "Instance is running. Public DNS is $PUBLIC_DNS"

# Create DynamoDB table
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=name,AttributeType=S \
    --key-schema AttributeName=name,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

echo "DynamoDB table $TABLE_NAME created."

# Connect to the instance and install necessary software
ssh -o StrictHostKeyChecking=no -i "$KEY_NAME.pem" ec2-user@$PUBLIC_DNS << EOF
sudo yum update -y
sudo yum install -y python3-pip git
pip3 install boto3 requests
git clone $REPO_URL
cd Pokemon_API_DynamoDB
python3 main.py
EOF

echo "Deployment completed. Connect to the instance with: ssh -i '$KEY_NAME.pem' ec2-user@$PUBLIC_DNS"
