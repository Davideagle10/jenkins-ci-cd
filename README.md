🚀 CI/CD Pipeline – Jenkins + AWS ECR

A complete CI/CD pipeline implementation using Jenkins, Docker, AWS ECR, and Packer. It automates building, testing, security scanning, and deploying a Python Flask application.

📋 Table of Contents

Architecture

Prerequisites

Project Structure

Jenkins Configuration

Packer AMI

Jenkins Pipeline

Python Application

Required Credentials

Pipeline Execution

Troubleshooting

Future Improvements

🏗️ Architecture

Flow:
User → GitHub → Jenkins Master → EC2 Worker (AMI Packer)
→ CI/CD Pipeline → Checkout → Tests → Build → Security Scan → Push to AWS ECR
→ Docker Image stored in ECR.

Main Components

Jenkins Master – Orchestrates the pipeline

EC2 Worker – Instance with tools (Docker, Java, AWS CLI, Python, Trivy)

Packer AMI – Preconfigured image for Jenkins workers

AWS ECR – Private Docker registry

Python Application – Flask app with health and system endpoints

📁 Project Structure
.
├── Dockerfile                 # Multi-stage Docker build
├── Jenkinsfile                # CI/CD pipeline definition
├── README.md                  # Documentation
├── app/
│   ├── __init__.py
│   └── main.py                # Flask app: /, /health, /status
├── packer/
│   └── worker_image.pkr.hcl   # Packer AMI configuration
├── requirements.txt           # Python dependencies
└── tests/
    └── test_app.py            # Unit tests

⚙️ Prerequisites
1. AWS Account

Required AWS permissions:

EC2 (instances, AMIs)

ECR (repository operations)

VPC/Networking

Create an ECR repository:

python-ci-cd

2. Jenkins Installed With Plugins

Pipeline

Amazon EC2 Plugin

Git

Docker Pipeline

JUnit

HTML Publisher (optional)

3. Local Development Tools

Git

AWS CLI

Docker

Python 3.7+

Packer

🔧 Jenkins Configuration
1. Required Credentials

Name: aws-account-id
Type: Secret Text
Value: Your AWS Account ID

Name: ecr-uri
Type: Secret Text
Value: Full ECR repository URI

2. Configure Amazon EC2 Cloud

Name: worker-ecr-pipeline

Region: us-east-1

AMI ID: AMI created with Packer

Instance Type: t3.medium

Security Group: Allows SSH (22) and outbound internet

Remote User: ec2-user

Remote FS Root: /home/ec2-user

Labels: docker&&linux

Idle Termination: 10 minutes

3. Create Pipeline

Pipeline → “Pipeline script from SCM”

SCM: Git

Repository URL: https://github.com/Davideagle10/jenkins-ci-cd


Script Path: Jenkinsfile

🖼️ Packer AMI
File: packer/worker_image.pkr.hcl

Creates an Amazon Linux 2 image with all the required tools.

Installed Tools

Docker + Docker Compose

AWS CLI v2

Python 3.7 + pip3

Trivy (security scanner)

Git, curl, wget, jq, htop

Java 17

Terraform (optional)

Build Commands
cd packer/
packer init worker_image.pkr.hcl
packer validate worker_image.pkr.hcl
packer build worker_image.pkr.hcl

Networking
vpc_id    = "your-vpc-id"
subnet_id = "your-subnet-id"
region    = "us-east-1"

🔄 Jenkins Pipeline
Pipeline Stages (Jenkinsfile)
1. Checkout
checkout scm

2. Environment Validation

Checks versions of Java, Docker, AWS CLI, Python, Trivy.

3. Run Tests
pip3 install -r requirements.txt
python3 -m pytest tests/ -v \
    --cov=app --cov-report=xml \
    --junitxml=test-results.xml


Outputs:

coverage.xml

test-results.xml

4. Lint Code
python3 -m py_compile app/*.py

5. Build Docker Image
docker build -t python-ci-cd:${BUILD_ID} .
docker tag python-ci-cd:${BUILD_ID} python-ci-cd:latest

6. Security Scan (Trivy)
trivy image --severity HIGH,CRITICAL python-ci-cd:${BUILD_ID}

7. Push to AWS ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

docker tag python-ci-cd:${BUILD_ID} ${ECR_URI}:${BUILD_ID}
docker tag python-ci-cd:${BUILD_ID} ${ECR_URI}:latest

docker push ${ECR_URI}:${BUILD_ID}
docker push ${ECR_URI}:latest

Pipeline Environment Variables
environment {
    ECR_URI        = credentials('ecr-uri')
    AWS_ACCOUNT_ID = credentials('aws-account-id')
    AWS_REGION     = 'us-east-1'
    IMAGE_TAG      = "${env.BUILD_ID}"
}

🐍 Python Application
Features

Framework: Flask 2.0.3

Python Versions:

Worker: 3.7

Docker image: 3.9

Endpoints

GET / – System info

GET /health – CPU, memory, disk metrics

GET /status – Service status

requirements.txt
Flask==2.0.3
psutil==5.9.5
gunicorn==20.1.0
pytest==7.4.2
pytest-cov==4.1.0

Dockerfile (Multi-Stage)
FROM python:3.9-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.9-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

🔐 Required Credentials
AWS Permissions

ecr:GetAuthorizationToken

ecr:BatchCheckLayerAvailability

ecr:CompleteLayerUpload

ecr:InitiateLayerUpload

ecr:PutImage

ecr:UploadLayerPart

Jenkins Secrets

aws-account-id

ecr-uri

🚀 Pipeline Execution
Automatic Flow (Recommended)

Push to main branch

GitHub triggers Jenkins via webhook

Jenkins launches EC2 worker

Pipeline runs

Docker image pushed to ECR

Manual Execution

Jenkins → Your Pipeline → Build Now

Validate ECR Images
aws ecr describe-images \
  --repository-name python-ci-cd \
  --region us-east-1

🐛 Troubleshooting
Common Issues
1. Worker does not connect

Check Security Group (port 22)

Validate IAM role

Inspect System Logs

2. pip: command not found

Use pip3 in Amazon Linux 2.

3. No test reports found

Ensure pytest generates:

--junitxml=test-results.xml

4. ECR authentication failure

Validate Jenkins credentials

Ensure repository exists

Check IAM permissions

5. Python version issues

Flask ≥2.3 requires Python ≥3.8

Use:

Flask==2.0.3

Debug Commands
docker --version
aws --version
python3 --version
trivy --version

📈 Metrics and Monitoring
Pipeline Metrics

Duration: 5–8 minutes

Unit Tests: 3

Vulnerability Scan: HIGH+CRITICAL

Docker Image: 150–200MB

Application Metrics (/health)

CPU usage

Memory usage

Disk usage

Free disk space