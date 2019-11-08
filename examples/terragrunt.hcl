include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/clusterfrak-dynamics/terraform-aws-s3-cloudfront.git?ref=v1.0.0"
}

locals {
  aws_region   = basename(dirname(get_terragrunt_dir()))
  env         = "production"
  project     = "myproject"
  custom_tags = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))
}

inputs = {

  env = local.env
  project = local.project

  aws = {
    "region" = local.aws_region
  }

  dns = {
    use_route53    = false
    hosted_zone_id = "zone_id"
    hostname       = "frontend.domain.name"
  }

  custom_tags = merge(
    {
      Env = local.env
    },
    local.custom_tags
  )

  front = {
    bucket_name                    = "${local.env}-static-site"
    s3_origin_id                   = "s3-front-${local.env}"
    origin_access_identity_comment = "Origin Access Identity for ${title(local.env)} environment"
    aliases                        = ["domain.name"]
    cloudfront_price_class         = "PriceClass_100"
    acm_arn                        = null
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }
}
