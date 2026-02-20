#!/bin/bash

# ================================================================
# Define ECR registry
# ================================================================

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# ================================================================
# Create ECR repository (if needed)
# ================================================================

aws ecr describe-repositories --repository-names "$IMAGE_NAME" --region "$AWS_REGION" 2>/dev/null || \
    aws ecr create-repository --repository-name "$IMAGE_NAME" --region "$AWS_REGION"

# ================================================================
# Tag the image
# ================================================================

docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# ================================================================
# Authenticate Docker to ECR
# ================================================================

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# ================================================================
# Push the image to ECR
# ================================================================

docker push "${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
