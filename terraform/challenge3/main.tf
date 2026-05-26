# Challenge 3: EC2 observability (requires Challenge 2 EC2 instances to be running)
data "terraform_remote_state" "challenge2" {
  backend = "local"

  config = {
    path = var.challenge2_state_path
  }
}

module "ec2_cloudwatch" {
  source = "../modules/ec2_cloudwatch"

  project_name              = var.project_name
  instance_ids              = data.terraform_remote_state.challenge2.outputs.ec2_instance_ids
  cloudwatch_log_group_name = var.cloudwatch_log_group_name
}
