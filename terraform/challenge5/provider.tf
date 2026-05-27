terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Challenge   = "5"
      ManagedBy   = "Terraform"
    }
  }
}

# ACM certificates for CloudFront must be in us-east-1
provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}
