#!/bin/bash

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
