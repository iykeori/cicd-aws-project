module "vpc" {
  source = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//vpc"
  # Environment
  region            = "us-east-1"
  project_name      = "nest"
  environment       = "dev"
  project_directory = "nest-app-infrastructure"

  # VPC
  vpc_cidr                     = "10.0.0.0/16"
  public_subnet_az1_cidr       = "10.0.0.0/24"
  public_subnet_az2_cidr       = "10.0.1.0/24"
  private_app_subnet_az1_cidr  = "10.0.2.0/24"
  private_app_subnet_az2_cidr  = "10.0.3.0/24"
  private_data_subnet_az1_cidr = "10.0.4.0/24"
  private_data_subnet_az2_cidr = "10.0.5.0/24"
}

module "security-groups" {
  source       = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//security-groups"
  environment  = module.vpc.environment
  project_name = module.vpc.project_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
}

module "acm" {
  source            = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//acm"
  domain_name       = "iykeori.com"
  alternative_names = "*.iykeori.com"
}

module "alb" {
  source                = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//alb"
  environment           = module.vpc.environment
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security-groups.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  target_type           = "ip"
  vpc_id                = module.vpc.vpc_id
  health_check_path     = "/index.php"
  certificate_arn       = module.acm.certificate_arn

}

module "route53" {
  source                             = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//route53"
  domain_name                        = module.acm.domain_name
  record_name                        = "www"
  application_load_balancer_zone_id  = module.alb.application_load_balancer_zone_id
  application_load_balancer_dns_name = module.alb.application_load_balancer_dns_name
}

module "data_migrate_ec2" {
  source                              = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//data-migrate"
  amazon_linux_ami_id                 = "ami-07ff62358b87c7116"
  ec2_instance_type                   = "t2.micro"
  private_app_subnet_az1_id           = module.vpc.private_app_subnet_az1_id
  db_migrate_server_security_group_id = module.security-groups.db_migrate_server_security_group_id
  ec2_instance_profile_role_name      = module.iam-ec2_instance_profile.ec2_instance_profile_role_name
  flyway_version                      = "11.19.1"
  sql_script_s3_uri                   = "s3://dev-iykenote-app-webfiles/Project2/V1__nest.sql"
  rds_endpoint                        = module.rds.rds_endpoint
  rds_db_name                         = module.secret-manager.rds_db_name
  rds_db_username                     = module.secret-manager.rds_db_username
  rds_db_password                     = module.secret-manager.rds_db_password
  environment                         = module.vpc.environment
  project_name                        = module.vpc.project_name

}

module "eice" {
  source                    = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//eice"
  private_app_subnet_az2_id = module.vpc.private_app_subnet_az2_id
  eice_security_group_id    = module.security-groups.eice_security_group_id
  environment               = module.vpc.environment
  project_name              = module.vpc.project_name

}

module "iam-ec2_instance_profile" {
  source       = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//iam/ec2-instance-profile"
  environment  = module.vpc.environment
  project_name = module.vpc.project_name
}

module "ecs-role" {
  source       = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//iam/ecs-role"
  project_name = module.vpc.project_name
  environment  = module.vpc.environment
}

module "nat-gateway" {
  source                     = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//nat-gateway"
  environment                = module.vpc.environment
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id

}

module "rds" {
  source                     = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//rds"
  environment                = module.vpc.environment
  project_name               = module.vpc.project_name
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
  database_engine            = "mysql"
  multi_az_deployment        = false
  database_instance_class    = "db.t3.micro"
  rds_db_username            = module.secret-manager.rds_db_username
  rds_db_password            = module.secret-manager.rds_db_password
  rds_db_name                = module.secret-manager.rds_db_name
  database_security_group_id = module.security-groups.database_security_group_id
  availability_zone_1        = module.vpc.availability_zone_1
  publicly_accessible        = false

}

module "secret-manager" {
  source      = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//secrets-manager"
  secret_name = "dev-secrets"

}

module "ecs" {
  source                       = "git::ssh://git@github.com/iykeori/aos_cohort_terraform_module_git.git//ecs"
  environment                  = module.vpc.environment
  project_name                 = module.vpc.project_name
  ecs_task_execution_role_arn  = module.ecs-role.ecs_task_execution_role_arn
  ecs_task_role_arn            = module.ecs-role.ecs_task_role_arn
  architecture                 = "X86_64"
  container_image              = "202202722931.dkr.ecr.us-east-1.amazonaws.com/nest:latest"
  region                       = module.vpc.region
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  app_server_security_group_id = module.security-groups.app_server_security_group_id
  alb_target_group_arn         = module.alb.alb_target_group_arn

  depends_on = [module.data_migrate_ec2]
}

# website URL
output "website_url" {
  value = join("", ["https://", module.route53.record_name, ".", module.acm.domain_name])
}

output "domain_name" {
  value = module.acm.domain_name
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "ecs_task_definition_name" {
  value = module.ecs.ecs_task_definition_name
}

output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.ecs.ecs_service_name
}



