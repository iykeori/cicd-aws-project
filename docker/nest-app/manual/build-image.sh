#!/bin/bash

# ================================================================
# Define Docker build arguments
# ================================================================

PROJECT_NAME="nest"
ENVIRONMENT="dev"
RECORD_NAME="www"
DOMAIN_NAME="iykeori.com"
GITHUB_USERNAME="iykeori"
REPOSITORY_NAME="application-codes"
SERVICE_PROVIDER_FILE_NAME="AppServiceProvider"
APPLICATION_CODE_FILE_NAME="nest"
RDS_ENDPOINT="dev-nest-db.cs3zjdpya7zx.us-east-1.rds.amazonaws.com"
RDS_DB_NAME="applicationdb"
RDS_DB_USERNAME="admin"
IMAGE_NAME="nest"
IMAGE_TAG="latest"
SECRET_NAME="dev-secrets"
AWS_REGION="us-east-1"

# ================================================================
# Retrieve secrets from AWS Secrets Manager
# ================================================================

SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $AWS_REGION --query SecretString --output text)
PERSONAL_ACCESS_TOKEN=$(echo $SECRET_JSON | jq -r '.personal_access_token')
RDS_DB_PASSWORD=$(echo $SECRET_JSON | jq -r '.password')

# ================================================================
# Enable BuildKit and set secrets
# ================================================================

export DOCKER_BUILDKIT=1
export PERSONAL_ACCESS_TOKEN_SECRET=$PERSONAL_ACCESS_TOKEN
export RDS_DB_PASSWORD_SECRET=$RDS_DB_PASSWORD

# ================================================================
# Build Docker image
# ================================================================

docker build \
    --secret id=personal_access_token,env=PERSONAL_ACCESS_TOKEN_SECRET \
    --secret id=rds_db_password,env=RDS_DB_PASSWORD_SECRET \
    --build-arg PROJECT_NAME="$PROJECT_NAME" \
    --build-arg ENVIRONMENT="$ENVIRONMENT" \
    --build-arg RECORD_NAME="$RECORD_NAME" \
    --build-arg DOMAIN_NAME="$DOMAIN_NAME" \
    --build-arg GITHUB_USERNAME="$GITHUB_USERNAME" \
    --build-arg REPOSITORY_NAME="$REPOSITORY_NAME" \
    --build-arg SERVICE_PROVIDER_FILE_NAME="$SERVICE_PROVIDER_FILE_NAME" \
    --build-arg APPLICATION_CODE_FILE_NAME="$APPLICATION_CODE_FILE_NAME" \
    --build-arg RDS_ENDPOINT="$RDS_ENDPOINT" \
    --build-arg RDS_DB_NAME="$RDS_DB_NAME" \
    --build-arg RDS_DB_USERNAME="$RDS_DB_USERNAME" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

# ================================================================
# Cleanup
# ================================================================

unset PERSONAL_ACCESS_TOKEN_SECRET RDS_DB_PASSWORD_SECRET