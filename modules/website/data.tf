data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "referer" {
  name = var.ssm_referer_key
}
