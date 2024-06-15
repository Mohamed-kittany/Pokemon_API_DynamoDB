#!/bin/bash

# Set variables
REGION="us-west-2"
AMI_ID="ami-0b20a6f09484773af"
INSTANCE_TYPE="t2.micro"
KEY_NAME="MyKeyPair"
REPO_URL="https://github.com/Mohamed-kittany/Pokemon_API_DynamoDB.git"
TABLE_NAME="PokemonTable"
HOSTNAME="pokemon-instance"
IAM_POLICY_NAME="DynamoDBCRUDPolicy"
IAM_ROLE_NAME="DynamoDBAccessRole"
IAM_INSTANCE_PROFILE_NAME="DynamoDBAccessInstanceProfile"

# Tags
INSTANCE_TAG="PokemonAppInstance"
VPC_TAG="PokemonVPC"
SUBNET_TAG="PokemonSubnet"
SECURITY_GROUP_TAG="PokemonSecurityGroup"
IGW_TAG="PokemonIGW"
ROUTE_TABLE_TAG="PokemonRouteTable"

# Create a new key pair
echo "Creating a new key pair..."
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem
echo "Key pair $KEY_NAME created."

# Create a new VPC
echo "Creating a new VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $REGION --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_TAG
echo "VPC created with ID: $VPC_ID and Name: $VPC_TAG"

# Create a subnet with auto-assign public IP enabled
echo "Creating a new subnet..."
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --region $REGION --query 'Subnet.SubnetId' --output text)
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=$SUBNET_TAG
echo "Subnet created with ID: $SUBNET_ID and Name: $SUBNET_TAG"

# Create a security group
echo "Creating a new security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name MySecurityGroup --description "My security group" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
aws ec2 create-tags --resources $SECURITY_GROUP_ID --tags Key=Name,Value=$SECURITY_GROUP_TAG
echo "Security group created with ID: $SECURITY_GROUP_ID and Name: $SECURITY_GROUP_TAG"

# Authorize security group ingress
echo "Authorizing security group ingress..."
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Security group ingress authorized for port 22."

# Create an Internet Gateway
echo "Creating an Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=$IGW_TAG
echo "Internet Gateway created with ID: $IGW_ID and Name: $IGW_TAG"

# Create a route table
echo "Creating a route table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $ROUTE_TABLE_ID --tags Key=Name,Value=$ROUTE_TABLE_TAG
echo "Route table created with ID: $ROUTE_TABLE_ID and Name: $ROUTE_TABLE_TAG"

# Create a route to the Internet Gateway
echo "Creating a route to the Internet Gateway..."
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Route created to the Internet Gateway."

# Associate the route table with the subnet
echo "Associating the route table with the subnet..."
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID
echo "Route table associated with subnet."

# Create IAM policy
echo "Creating IAM policy..."
aws iam create-policy --policy-name $IAM_POLICY_NAME --policy-document file://dynamodb_crud_policy.json
echo "IAM policy $IAM_POLICY_NAME created."

# Create IAM role
echo "Creating IAM role..."
aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document file://<(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
)
echo "IAM role $IAM_ROLE_NAME created."

# Attach policy to role
echo "Attaching policy to IAM role..."
aws iam attach-role-policy --role-name $IAM_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/$IAM_POLICY_NAME
echo "Policy $IAM_POLICY_NAME attached to role $IAM_ROLE_NAME."

# Create IAM instance profile
echo "Creating IAM instance profile..."
aws iam create-instance-profile --instance-profile-name $IAM_INSTANCE_PROFILE_NAME
aws iam add-role-to-instance-profile --instance-profile-name $IAM_INSTANCE_PROFILE_NAME --role-name $IAM_ROLE_NAME
echo "IAM instance profile $IAM_INSTANCE_PROFILE_NAME created and role $IAM_ROLE_NAME added."

# User data script to set hostname, install software, and display usage information
USER_DATA=$(cat <<EOF
#!/bin/bash

# Set the hostname
hostnamectl set-hostname $HOSTNAME

# Install necessary software
yum update -y
yum install -y python3-pip git
pip3 install boto3 requests

# Clone the repository and run the main script
cd /home/ec2-user
git clone $REPO_URL
cd Pokemon_API_DynamoDB
python3 main.py

# Add usage explanation to /etc/motd
echo "Welcome to the Pokemon API DynamoDB instance!" > /etc/motd
echo "To use this server, follow these steps:" >> /etc/motd
echo "1. The main script 'main.py' is located in the 'Pokemon_API_DynamoDB' directory." >> /etc/motd
echo "2. You can start the script by navigating to the directory and running 'python3 main.py'." >> /etc/motd
echo "3. Hope you enjoy ツ." >> /etc/motd
EOF
)

# Create an EC2 instance
echo "Creating an EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --region $REGION --iam-instance-profile Name=$IAM_INSTANCE_PROFILE_NAME --user-data "$USER_DATA" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_TAG}]" --query 'Instances[0].InstanceId' --output text)
echo "EC2 instance created with ID: $INSTANCE_ID and Name: $INSTANCE_TAG"

echo "Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Get the public DNS name of the instance
PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[*].Instances[*].PublicDnsName" --output text)
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

if [ -z "$PUBLIC_DNS" ]; then
  echo "Public DNS is empty. Instance might not have an associated public DNS name."
else
  echo "Instance is running. Public DNS is $PUBLIC_DNS"
fi

echo "Instance is running. Public IP is $PUBLIC_IP"

# Create DynamoDB table
echo "Creating DynamoDB table..."
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=name,AttributeType=S \
    --key-schema AttributeName=name,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION
echo "DynamoDB table $TABLE_NAME created."

echo "Deployment completed. Connect to the instance with: ssh -i '$KEY_NAME.pem' ec2-user@$PUBLIC_IP"
