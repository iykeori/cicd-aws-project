#!/bin/bash

# ================================================================
# Define Docker image push variables
# ================================================================

ECR_REPO_NAME="nest"
LOCAL_IMAGE_NAME="nest"  
IMAGE_TAG="latest"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="202202722931"

# ================================================================
# Create ECR repository (if needed)
# ================================================================

aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" 2>/dev/null || \
    aws ecr create-repository --repository-name "$ECR_REPO_NAME" --region "$AWS_REGION"

# ================================================================
# Tag the image
# ================================================================

docker tag "${LOCAL_IMAGE_NAME}:${IMAGE_TAG}" "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"

# ================================================================
# Authenticate Docker to ECR
# ================================================================

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# ================================================================
# Push the image to ECR
# ================================================================

docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"