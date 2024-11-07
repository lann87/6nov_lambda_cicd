![Alt Text](https://github.com/lann87/cloud_infra_eng_ntu_coursework_alanp/blob/main/.misc/ntu_logo.png)  

# DevSecOps - Assignment 3.12 - Continuous Deployment Serverless

## Individual Assignment - Implement CI with Terraform

**Date**: 6 Nov  
**Author**: Alan Peh  

## Lambda deployment with Terraform and CICD pipeline



### 1. Structure  

Directories for Terraform, Docker, and workflows, automating infrastructure management and containerized application deployment.  

```sh
.
├── terraform/
│   ├── lambda.tf       # Defines AWS Lambda function configuration
│   ├── iam.tf          # IAM roles and policies required for Lambda
│   ├── provider.tf     # Sets up AWS provider and TF dependencies
│   ├── backend.tf      # S3 backend for TF state storage
│   └── output.json     # Lambda function invocation output
├── python/
│   ├── lambda_function.py      # Python code for Lambda function logic
│   └── lambda_function.zip     # Zipped Python code and dependencies for Lambda deployment
├── .github/
│   └── workflows/
│       ├── checkov.yaml        # Security scans with Checkov on TF code
│       ├── ci-lambda.yaml      # Continuous Integration: Terraform fmt/init/validate/lint on pull requests
│       └── cd-lambda.yaml      # Continuous Deployment: Terraform plan on PRs, apply on merge to main
├── resource/
│   └── screenshots             # Folder for screenshots, e.g., for documentation
└── README.md                   # Documentation for the project and submission
```

### 2. Terraform files  

Configures a Lambda function call.  

**lambda.tf**  

```tf
resource "aws_lambda_function" "ap-lambda-fn" {
  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  function_name = "ap-lambda-function-6nov"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"

  # Configure code signing for additional security
  code_signing_config_arn = aws_lambda_code_signing_config.ap-lambda-codesigning.arn

  # Set max number of concurrent executions
  reserved_concurrent_executions = 50

  # Configure dead letter queue for failed invocations
  dead_letter_config {
    target_arn = aws_sns_topic.lambda_dead_letter_topic.arn
  }

  # Enable active tracing for better obervability
  tracing_config {
    mode = "Active"
  }

  # Specify location of the lambda function code
  filename         = "${path.module}/../python/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../python/lambda_function.zip")
}

# Creating code signing configuration for the lambda function
resource "aws_lambda_code_signing_config" "ap-lambda-codesigning" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.ap-lambda-signerprof.arn]
  }
}

# Creating a signing profile for the lambda function
resource "aws_signer_signing_profile" "ap-lambda-signerprof" {
  name_prefix = "apsigner"
  platform_id = "AWSLambda-SHA384-ECDSA"
}

# Creating SNS topic for the lambda function's dead letter queue
resource "aws_sns_topic" "lambda_dead_letter_topic" {
  name              = "lambda-dead-letter-topic"
  kms_master_key_id = "alias/aws/sns"
}
```

**iam.tf**  

```
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  # Define the trust policy to allow Lambda to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Define inline policy to allow Lambda function to publish to SNS topic
# This is a mandatory res for dead letter queue functionality
resource "aws_iam_role_policy" "sns_publish_policy" {
  name = "SNSPublishPolicy"
  role = aws_iam_role.lambda_exec_role.name

  # Specify the policy document to grant necessary permissions
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.lambda_dead_letter_topic.arn
      }
    ]
  })
}



# Attached AWS managed policy for basic Lambda execution permission
resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

**provider.tf**  

```tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
```

**backend.tf**  

```tf
terraform {
  backend "s3" {
    bucket = "sctp-ce7-tfstate"
    key    = "terraform-simple-cicd-action-ap-30oct.tfstate"
    region = "us-east-1"
  }
}
```

**output.json**  

```json
{"statusCode": 200, "body": "\"Good day, Alan!! I cannot wait to go to Tokyo for my holidays in December!!\""}
```

### 3. GitHub Actions Workflows  

Workflows automate code formatting, Terraform linting, Docker vulnerability scanning, and plan checks, ensuring quality and security.  

**Workflows Summmary**  

![Alt Text](https://github.com/lann87/30oct-ap-cicd-pipeline/blob/main/resource/30oct-github-workflows-sum.png)

**Pull Request**  

![Alt Text](https://github.com/lann87/30oct-ap-cicd-pipeline/blob/main/resource/30oct-pullrequest.png)

**checkov.yaml**  

```yaml

```

**docker-checks.yaml**  

```yaml

```

**terraform-checks.yaml**  

```yaml

```

**terraform-plan.yaml**  

```yaml

```

### Additions - Github Credential Personal Access Token for Trivy  

![Alt Text](https://github.com/lann87/30oct-ap-cicd-pipeline/blob/main/resource/30oct-pat-trivy-cicd.png)

![Alt Text](https://github.com/lann87/30oct-ap-cicd-pipeline/blob/main/resource/30oct-pat-for-trivy.png)