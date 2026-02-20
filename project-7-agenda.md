# Project 7: Host a Dynamic Web Application on AWS with GitHub Actions (CI/CD)

🟢 **Goal:** Learn how to implement a complete CI/CD pipeline using GitHub Actions to automate the deployment of a containerized web application on AWS ECS, including infrastructure provisioning with Terraform, Docker image building, vulnerability scanning, automated deployments, health checks, rollback capabilities, and Slack notifications.

---

## 1️⃣ Start Here

**Objective:** Introduce the project and CI/CD concepts.

- Review architecture from previous projects (Terraform with ECS deployment)
- Understand the benefits of CI/CD automation
- Understand GitHub Actions workflow concepts
- Overview of the complete pipeline:
  - Build AWS Infrastructure (Terraform)
  - Build, Scan, and Push Docker Image to ECR
  - Create New Task Definition Revision
  - Restart ECS Fargate Service
  - Test Application Health
  - Monitor ECS Deployment
  - Rollback on Failure
  - Send Slack Notification

---

## 2️⃣ Update Terraform Configuration

**Objective:** Prepare Terraform code for CI/CD integration.

- Remove profile from backend configuration
- Remove profile from provider configuration
- Update to use environment variables for AWS credentials
- Verify Terraform can authenticate without local AWS profile

---

## 3️⃣ Update ECS Module Outputs

**Objective:** Expose ECS resource information for the pipeline.

- Add `ecs_cluster_name` output to ECS module
- Add `ecs_task_definition_name` output to ECS module
- Add `ecs_service_name` output to ECS module
- Verify outputs are accessible from root module

---

## 4️⃣ Update Project Main Outputs

**Objective:** Export all required values for CI/CD pipeline.

- Add `domain_name` output to main.tf
- Add `rds_endpoint` output to main.tf
- Add `ecs_task_definition_name` output to main.tf
- Add `ecs_cluster_name` output to main.tf
- Add `ecs_service_name` output to main.tf
- Run `terraform apply` to verify outputs

---

## 5️⃣ Create GitHub Workflows Directory

**Objective:** Set up GitHub Actions workflow structure.

- Create `.github/workflows` directory in project repository
- Understand GitHub Actions directory structure
- Plan workflow file organization

---

## 6️⃣ Generate SSH Key Pair for Deploy Key

**Objective:** Enable secure access to private Terraform modules repository.

- Generate SSH key pair locally:
  ```bash
  ssh-keygen -t ed25519 -C "github-actions" -f deploy_key -N ""
  ```
- Understand the purpose of deploy keys for private repository access
- Secure the private key file

---

## 7️⃣ Configure Deploy Key on Modules Repository

**Objective:** Allow GitHub Actions to clone private modules.

- Navigate to modules repository on GitHub
- Go to **Settings → Deploy keys → Add deploy key**
- Paste the public key (`deploy_key.pub`)
- Enable read access only
- Save the deploy key

---

## 8️⃣ Create Slack Webhook for Notifications

**Objective:** Set up Slack integration for pipeline notifications.

- **Create a Slack App:**
  - Go to [api.slack.com/apps](https://api.slack.com/apps)
  - Click **Create New App** → choose **From scratch**
  - Give it a name (e.g., "GitHub Actions Notifications")
  - Select your workspace
- **Enable Incoming Webhooks:**
  - In app settings, go to **Incoming Webhooks** in the left sidebar
  - Toggle **Activate Incoming Webhooks** to **On**
- **Add a Webhook to a Channel:**
  - Click **Add New Webhook to Workspace**
  - Select the channel for deployment notifications
  - Click **Allow**
- **Copy the Webhook URL:**
SLACK_WEBHOOK_URL_REMOVED
  - Store it securely (treat it like a secret)

---

## 9️⃣ Configure GitHub Repository Secrets

**Objective:** Store sensitive credentials securely in GitHub.

- Navigate to workflow repository on GitHub
- Go to **Settings → Secrets and variables → Actions**
- Add the following repository secrets:

| Secret Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for deployment |
| `PERSONAL_ACCESS_TOKEN` | GitHub PAT for repository access |
| `RDS_DB_PASSWORD` | Database password for RDS |
| `SSH_PRIVATE_KEY` | Private key for modules repository access |
| `SLACK_WEBHOOK_URL` | Slack webhook URL for notifications |

- Verify all secrets are added

---

## 🔟 Organize Build Scripts

**Objective:** Restructure scripts for manual and automated workflows.

- Create `manual` folder in docker scripts directory
- Move existing manual build and push scripts to `manual` folder
- Verify manual scripts still work when needed

---

## 1️⃣1️⃣ Create Pipeline Build and Push Scripts

**Objective:** Create automated scripts for CI/CD pipeline.

**Build Image Script:**
- Create `build-image.sh` for pipeline use
- Configure script to:
  - Accept environment variables (`DOMAIN_NAME`, `RDS_ENDPOINT`, `RDS_DB_PASSWORD`, `PERSONAL_ACCESS_TOKEN`)
  - Build Docker image with appropriate tags
- Make script executable

**Push Image Script:**
- Create `push-image.sh` for pipeline use
- Configure script to:
  - Authenticate with Amazon ECR
  - Tag Docker image with ECR repository URI
  - Push image to ECR repository
- Make script executable

---

## 1️⃣2️⃣ Create GitHub Actions Workflow File

**Objective:** Define the complete CI/CD pipeline configuration.

**Workflow Configuration:**
- Create pipeline YAML file in `.github/workflows` directory
- Configure workflow name and triggers:
  - Push to `main` branch
  - Path filters for workflow, docker, and terraform files

**Environment Variables:**
- Define global environment variables:
  - AWS credentials (from secrets)
  - AWS region and account ID
  - Terraform action (apply/destroy)
  - Project name and environment
  - Domain and record name
  - GitHub repository details
  - RDS database configuration
  - Docker image name and tag

---

## 1️⃣3️⃣ Pipeline Job 1: Deploy AWS Infrastructure

**Objective:** Automate Terraform infrastructure deployment.

- Checkout repository
- Configure SSH access for Terraform modules:
  - Create `.ssh` directory
  - Add private key from secrets
  - Add GitHub to known hosts
- Set up Terraform
- Run `terraform init`
- Run `terraform plan`
- Run `terraform apply` or `terraform destroy` (based on `TERRAFORM_ACTION`)
- Export Terraform outputs:
  - `domain_name`
  - `rds_endpoint`
  - `ecs_task_definition_name`
  - `ecs_cluster_name`
  - `ecs_service_name`
- Configure job outputs for downstream jobs

---

## 1️⃣4️⃣ Pipeline Job 2: Build, Scan, and Push Docker Image

**Objective:** Automate Docker image build with security scanning.

- Checkout repository
- Build Docker image using build script
- Pass environment variables from Terraform outputs
- Scan Docker image for vulnerabilities using Trivy:
  - Check for CRITICAL and HIGH severity vulnerabilities
  - Generate vulnerability report (JSON)
  - Exit with error in production if vulnerabilities found
- Generate vulnerability summary for notifications
- Push Docker image to ECR using push script
- Configure job outputs (`scan_summary`)

---

## 1️⃣5️⃣ Pipeline Job 3: Create New Task Definition Revision

**Objective:** Update ECS task definition with new image.

- Get current task definition revision
- Create new task definition revision:
  - Fetch existing task definition
  - Update container image to new ECR image
  - Remove metadata fields (ARN, revision, status, etc.)
  - Register new task definition
- Store both current and new revision numbers for rollback capability
- Configure job outputs for downstream jobs

---

## 1️⃣6️⃣ Pipeline Job 4: Restart ECS Fargate Service

**Objective:** Deploy new task definition to ECS service.

- Update ECS service with new task definition revision
- Force new deployment
- Wait for service to stabilize using `aws ecs wait services-stable`

---

## 1️⃣7️⃣ Pipeline Job 5: Test Application Health

**Objective:** Validate application is accessible and healthy.

- Wait for service to stabilize (30 seconds buffer)
- Check application health using `curl`:
  - Make HTTP request to application URL
  - Verify HTTP status code is 200
  - Fail job if health check fails

---

## 1️⃣8️⃣ Pipeline Job 6: Monitor ECS Deployment

**Objective:** Verify ECS tasks are running correctly.

- Check ECS service running task count
- Compare running count vs desired count
- Verify all tasks are running successfully
- Fail job if task count mismatch

---

## 1️⃣9️⃣ Pipeline Job 7: Rollback on Failure

**Objective:** Automatically rollback to previous version on failure.

- Trigger only if previous jobs fail
- Rollback ECS service to previous task definition revision
- Force new deployment with previous revision
- Wait for service to stabilize
- Log rollback completion

---

## 2️⃣0️⃣ Pipeline Job 8: Send Slack Notification

**Objective:** Notify team of deployment status.

- Trigger always (success or failure)
- Send Slack notification with:
  - Deployment status (Success ✅ or Failed ❌)
  - Project name and environment
  - Docker image name and tag
  - Triggered by (GitHub actor)
  - Security scan summary
  - Link to pipeline run
- Use Slack GitHub Action with incoming webhook

---

## 2️⃣1️⃣ Test CI/CD Pipeline

**Objective:** Validate the complete pipeline workflow.

- Commit and push workflow file to trigger pipeline
- Monitor workflow execution in GitHub Actions tab
- Verify each job completes successfully:
  - Infrastructure deployment
  - Image build and push
  - Task definition update
  - Service restart
  - Health check pass
  - Monitoring pass
  - Slack notification received
- Test rollback by intentionally breaking deployment
- Verify Slack notifications for both success and failure

---

## 2️⃣2️⃣ Project Wrap-Up

**Objective:** Finalize, document, and clean up.

- Validate application is accessible via custom domain
- Verify new deployments trigger automatically on code push
- Test destroy workflow by changing `TERRAFORM_ACTION` to "destroy"
- Document pipeline workflow and configuration
- Complete Assignment
