#!/bin/bash

# Set variables
KEY_NAME="MyKeyPair"
REGION="us-west-2"
INSTANCE_TAG="PokemonAppInstance"
TABLE_NAME="PokemonTable"
VPC_TAG="PokemonVPC"
SUBNET_TAG="PokemonSubnet"
SECURITY_GROUP_TAG="PokemonSecurityGroup"
IGW_TAG="PokemonIGW"
ROUTE_TABLE_TAG="PokemonRouteTable"

# Function to delete EC2 instances
delete_instances() {
    echo "Deleting EC2 instances..."
    INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_TAG" "Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text --region $REGION)
    if [ -n "$INSTANCE_IDS" ]; then
        aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION
        aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region $REGION
        echo "EC2 instances terminated: $INSTANCE_IDS"
    else
        echo "No EC2 instances found with tag: $INSTANCE_TAG in non-terminated states."
    fi
}

# Function to delete DynamoDB table
delete_dynamodb_table() {
    echo "Deleting DynamoDB table..."
    if aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION; then
        aws dynamodb delete-table --table-name $TABLE_NAME --region $REGION
        aws dynamodb wait table-not-exists --table-name $TABLE_NAME --region $REGION
        echo "DynamoDB table $TABLE_NAME deleted."
    else
        echo "DynamoDB table $TABLE_NAME not found."
    fi
}

# Function to delete Internet Gateway
delete_internet_gateway() {
    echo "Deleting Internet Gateway..."
    IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=$IGW_TAG" --query "InternetGateways[*].InternetGatewayId" --output text --region $REGION)
    for IGW_ID in $IGW_IDS; do
        # Detach the Internet Gateway from the VPC
        VPC_ID=$(aws ec2 describe-internet-gateways --internet-gateway-ids $IGW_ID --query "InternetGateways[*].Attachments[*].VpcId" --output text --region $REGION)
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
        # Delete the Internet Gateway
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
        echo "Internet Gateway deleted: $IGW_ID"
    done
}

# Function to delete route tables
delete_route_tables() {
    echo "Deleting route tables..."
    ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=$ROUTE_TABLE_TAG" --query "RouteTables[*].RouteTableId" --output text --region $REGION)
    for RT_ID in $ROUTE_TABLE_IDS; do
        # Disassociate the route table
        ASSOCIATIONS=$(aws ec2 describe-route-tables --route-table-ids $RT_ID --query "RouteTables[*].Associations[*].RouteTableAssociationId" --output text --region $REGION)
        for ASSOC in $ASSOCIATIONS; do
            aws ec2 disassociate-route-table --association-id $ASSOC --region $REGION
        done
        # Delete the route table
        aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION
        echo "Route table deleted: $RT_ID"
    done
}

# Function to delete security groups
delete_security_groups() {
    echo "Deleting security groups..."
    SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=$SECURITY_GROUP_TAG" --query "SecurityGroups[*].GroupId" --output text --region $REGION)
    for SG_ID in $SECURITY_GROUP_IDS; do
        aws ec2 delete-security-group --group-id $SG_ID --region $REGION
        echo "Security group deleted: $SG_ID"
    done
}

# Function to delete subnets
delete_subnets() {
    echo "Deleting subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$SUBNET_TAG" --query "Subnets[*].SubnetId" --output text --region $REGION)
    for SUBNET_ID in $SUBNET_IDS; do
        aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
        echo "Subnet deleted: $SUBNET_ID"
    done
}

# Function to delete VPCs
delete_vpcs() {
    echo "Deleting VPCs..."
    VPC_IDS=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_TAG" --query "Vpcs[*].VpcId" --output text --region $REGION)
    for VPC_ID in $VPC_IDS; do
        aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
        echo "VPC deleted: $VPC_ID"
    done
}

# Function to delete key pair
delete_key_pair() {
    echo "Deleting key pair..."
    aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION
    rm -f "$KEY_NAME.pem"
    echo "Key pair $KEY_NAME deleted."
}

# Run the functions to delete resources in the correct order
delete_instances
delete_internet_gateway
delete_route_tables
delete_security_groups
delete_subnets
delete_vpcs
delete_dynamodb_table
delete_key_pair

echo "Teardown completed. All resources have been deleted."
