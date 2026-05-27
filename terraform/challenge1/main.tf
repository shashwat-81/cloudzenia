module "vpc" {
  source = "../modules/vpc"

  vpc_cidr           = var.vpc_cidr
  project_name       = var.project_name
  environment        = var.environment
  availability_zones = var.availability_zones
}

module "security" {
  source = "../modules/security"

  vpc_id                      = module.vpc.vpc_id
  project_name                = var.project_name
  wordpress_container_port    = var.wordpress_container_port
  microservice_container_port = var.microservice_container_port
  vpc_cidr                    = var.vpc_cidr
}

module "rds" {
  source = "../modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  db_name            = var.rds_db_name
  db_username        = var.rds_username
  db_password        = var.rds_password
  instance_class     = var.rds_instance_class
  allocated_storage  = var.rds_allocated_storage
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.rds_security_group_id
}

module "secrets" {
  source = "../modules/secrets"

  project_name = var.project_name
  rds_endpoint = module.rds.rds_endpoint
  rds_port     = module.rds.rds_port
  db_name      = var.rds_db_name
  db_username  = var.rds_username
  db_password  = var.rds_password
}

module "iam" {
  source = "../modules/iam"

  project_name = var.project_name
  secrets_arn  = module.secrets.secret_arn
}

module "ecr" {
  source = "../modules/ecr"

  project_name            = var.project_name
  repository_name         = "microservice"
  use_existing_repository = var.use_existing_ecr_repository
}

module "ecs" {
  source = "../modules/ecs"

  project_name                = var.project_name
  environment                 = var.environment
  ecs_cluster_name            = var.ecs_cluster_name
  private_subnet_ids          = module.vpc.private_subnet_ids
  ecs_security_group_id       = module.security.ecs_security_group_id
  task_execution_role_arn     = module.iam.ecs_task_execution_role_arn
  task_role_arn               = module.iam.ecs_task_role_arn
  task_cpu                    = var.ecs_task_cpu
  task_memory                 = var.ecs_task_memory
  desired_count               = var.ecs_desired_count
  wordpress_image_url         = var.wordpress_image_url
  wordpress_container_port    = var.wordpress_container_port
  microservice_container_port = var.microservice_container_port
  microservice_image_url      = "${module.ecr.repository_url}:latest"
  rds_endpoint                = module.rds.rds_endpoint
  rds_port                    = module.rds.rds_port
  rds_database_name           = var.rds_db_name
  secrets_arn                 = module.secrets.secret_arn
  autoscaling_min_capacity    = var.autoscaling_min_capacity
  autoscaling_max_capacity    = var.autoscaling_max_capacity
  autoscaling_target_cpu      = var.autoscaling_target_cpu
  autoscaling_target_memory   = var.autoscaling_target_memory
  vpc_id                      = module.vpc.vpc_id
  wordpress_subdomain         = var.wordpress_subdomain
  wordpress_domain            = var.domain_name
  https_listener_arn          = module.alb.https_listener_arn
}

module "alb" {
  source = "../modules/alb"

  project_name                  = var.project_name
  public_subnet_ids             = module.vpc.public_subnet_ids
  alb_security_group_id         = module.security.alb_security_group_id
  domain_name                   = var.domain_name
  wordpress_subdomain           = var.wordpress_subdomain
  microservice_subdomain        = var.microservice_subdomain
  wordpress_target_group_arn    = module.ecs.wordpress_target_group_arn
  microservice_target_group_arn = module.ecs.microservice_target_group_arn
  route53_zone_id               = var.route53_zone_id
}

