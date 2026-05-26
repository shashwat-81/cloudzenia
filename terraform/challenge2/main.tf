module "vpc" {
  source = "../modules/vpc"

  vpc_cidr           = var.vpc_cidr
  project_name       = var.project_name
  environment        = var.environment
  availability_zones = var.availability_zones
}

module "ec2_nginx_instances" {
  source = "../modules/ec2_nginx_instances"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_security_group_id = module.ec2_alb.alb_security_group_id

  domain_name = var.domain_name
  certbot_email = var.certbot_email
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name

  ec2_instance1_subdomain = var.ec2_instance1_subdomain
  ec2_docker1_subdomain   = var.ec2_docker1_subdomain
  ec2_instance2_subdomain = var.ec2_instance2_subdomain
  ec2_docker2_subdomain   = var.ec2_docker2_subdomain

  ec2_alb_instance_subdomain = var.ec2_alb_instance_subdomain
  ec2_alb_docker_subdomain   = var.ec2_alb_docker_subdomain
}

module "ec2_alb" {
  source = "../modules/ec2_alb"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  domain_name = var.domain_name
  ec2_alb_instance_subdomain = var.ec2_alb_instance_subdomain
  ec2_alb_docker_subdomain   = var.ec2_alb_docker_subdomain

  target_instance_ids = module.ec2_nginx_instances.instance_ids
}

