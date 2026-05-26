terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Challenge   = "1"
      ManagedBy   = "Terraform"
    }
  }

  ignore_tags {
    keys = ["CreatedAt"]
  }
}

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
}

