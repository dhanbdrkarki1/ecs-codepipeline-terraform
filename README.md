# Terraform for AWS Infrastructure

## Overview

This project includes different modules to setup AWS Infrastructure for ECS with EC2 launch type. Also, added Blue/Green Deployment Support.

Modules included:

- Amazon Certificate Manager (ACM)
- Application Load Balancer (ALB)
- Auto Scaling Group (ASG)
- CloudWatch
- CodeDeploy
- RDS
- DynamoDB
- EC2
- ECR
- IAM
- S3
- Security Groups (sg)
- SNS
- VPC

## Prerequisites

- Terraform installed. [Install Terraform](https://developer.hashicorp.com/terraform/install).
- AWS CLI configured with appropriate credentials. [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions).

## Setting Up the AWS Profile (Optional)

**If you don't already have an AWS profile configured, follow these steps:**

1. **Configure the AWS profile using the AWS CLI:**

   Open your terminal and run the following command, replacing `YOUR_PROFILE_NAME`, `YOUR_ACCESS_KEY_ID`, `YOUR_SECRET_ACCESS_KEY`, and `DEFAULT_REGION` with your actual AWS credentials:

   ```bash
   aws configure --profile YOUR_PROFILE_NAME \
       --access-key-id YOUR_ACCESS_KEY_ID \
       --secret-access-key YOUR_SECRET_ACCESS_KEY \
       --region DEFAULT_REGION
   ```

## Directory Structure

```bash
terraform-custom-dhan/
├── live/
│ └── dev/
│ ├── locals.tf
│ └── other terraform files...
```

## Setup

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone https://github.com/CloudTechService/terraform-custom-dhan.git
cd terraform-custom-dhan/
git checkout blue-green-demo
```

### 2. Creating S3 Bucket for Terraform Remote State Management

```bash
cd terraform-custom-dhan/remote-state/dev
```

Update providers.tf file:

```
provider "aws" {
  region  = "<aws_account_region-e.g. us-east-1>"
  profile = "<YOUR_PROFILE_NAME>"
  default_tags {
    tags = {
      OwnedBy    = "<Name of the Owner>"
      Department = "<Name of the Department>"
      ManagedBy  = "Terraform"
      // can add more tags here...
    }
  }
}
```

Update terraform.tfvars file:

```
bucket_name = "<Name_of_the_S3_Bucket_for_remote_state>"
table_name  = "<Name_of_the_DynamoDb_Table_for_state_locking>"
```

To create s3 bucket and dynamodb table,

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

### 3. Creating Infrastructure

Before creating infrastructure, take these steps into consideration:

#### Update providers.tf

Navigate to,

```bash
cd terraform-custom-dhan/dev
```

Update the providers.tf with the above created bucket name and dynamodb table, displayed in terraform console output and AWS profile.

```bash
profile = "<YOUR_PROFILE_NAME>"
region         = "<aws_account_region>"
bucket = "<Name_of_the_S3_Bucket_for_remote_state>"
dynamodb_table  = "<Name_of_the_DynamoDb_Table_for_state_locking>"
```

#### Running Infrastructure

This project uses Terraform command to provision infrastructure across all modules.

```bash
terraform init
terraform plan
terraform apply
```

#### Customizing the Infrastructure (Optional)

You can customize various AWS resources by modifying their respective `.tf` files in the root module. Below are the key customization options for each resource type:

##### 1. terraform.tfvars Configuration

This file contains environment-specific variables. Customize these values based on your requirements:

```hcl
project_name       = "dhan-custom"
availability_zones = ["us-east-2a", "us-east-2b"]
environment        = "dev"
```

##### 2. locals.tf Configuration

This file contains local variables used across multiple resources. Look through it and make a change accordingly.

To change the resource attributes of other .tf file in the root module, for example, if you want to change the name of the vpc, go to vpc.tf "vpc" module block and update name:

```
name                       = "<Desired VPC Name>"
...
```

Likewise, you can modify for other resources.

## Important Notes

Don't forget to manually create ACM certificate in AWS ACM and update the domain name in locals.tf.
Also, update the CNAME name and value in your domain provider.

## Destroying Infrastructure Resources (Optional)

⚠️ Be careful with this destructive command since this destroy all the existing infrastructure in AWS.

```bash
terraform destroy -auto-approve
```
