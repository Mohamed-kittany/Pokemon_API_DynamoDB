
# Pokemon API DynamoDB Project

This project demonstrates how to interact with the PokeAPI to fetch Pokemon data and store it in an Amazon DynamoDB table. It involves setting up AWS infrastructure using a Bash script, deploying an EC2 instance, configuring it to run a Python application, and managing DynamoDB interactions.

## Project Overview

1. **AWS Infrastructure Setup**: Automating the creation of AWS resources using a Bash script.
2. **EC2 Instance Configuration**: Setting up the instance with the necessary software and scripts to run the application.
3. **Python Application**: Fetching and storing Pokemon data from the PokeAPI.
4. **DynamoDB Integration**: Storing and retrieving Pokemon data from DynamoDB.
5. **User Interaction**: Providing a user-friendly interface to interact with the application.

## Setup and Deployment

### Prerequisites

- AWS CLI installed and configured with appropriate credentials.
- Bash shell to run the deployment script.

### Step-by-Step Guide

1. **Run the Deployment Script**

   The deployment script (`deployment.sh`) performs the following tasks:
   
   - Creates a Key Pair and saves it locally for SSH access.
   - Creates a VPC, Subnet, Internet Gateway, Route Table, and Security Group.
   - Launches an EC2 instance with the specified AMI and instance type.
   - Installs necessary software on the EC2 instance (AWS CLI, Python, Git).
   - Clones the project repository and runs the Python application.
   - Configures DynamoDB and sets up the application to interact with it.
   - Customizes the `/etc/motd` file to provide usage instructions.


   ```bash
   ./deployment.sh
   ```

## Connecting to the EC2 Instance

### SSH into the Instance

```bash
ssh -i "MyKeyPair.pem" ec2-user@<PUBLIC_IP>
```

### Configure AWS CLI on the Instance

```bash
aws configure
```

Provide your AWS Access Key, Secret Access Key, region, and output format.

## Running the Application

The application is set up to run automatically upon instance initialization. You can interact with the application by following the instructions provided in the `/etc/motd` file. If needed, you can manually start the application:

```bash
cd Pokemon_API_DynamoDB
python3 main.py
```

## Application Features

- **Fetching Pokemon Data**: The application fetches Pokemon data from the PokeAPI.
- **Storing Data in DynamoDB**: It stores the fetched Pokemon data in a DynamoDB table.
- **Retrieving Data from DynamoDB**: It can retrieve and display stored Pokemon data.
- **User Interaction**: The application prompts the user to fetch and store new Pokemon data.

## Teardown

To clean up the AWS resources created by the deployment script, run the `teardown.sh` script:

```bash
./teardown.sh
```

This script will delete the EC2 instance, DynamoDB table, and other AWS resources created during the deployment.
