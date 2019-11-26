provider "aws" {
  region = var.aws["region"]
}

terraform {
  backend "s3" {
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
