locals {
  s3_origin_id = var.front["s3_origin_id"]
  common_tags  = {}
}

resource "aws_route53_record" "s3_distribution_v4" {
  count   = var.dns["use_route53"] ? 1 : 0
  zone_id = var.dns["hosted_zone_id"]
  name    = var.dns["hostname"]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "s3_distribution_v6" {
  count   = var.dns["use_route53"] ? 1 : 0
  zone_id = var.dns["hosted_zone_id"]
  name    = var.dns["hostname"]
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "log_bucket" {
  count  = var.front["log_bucket_name"] == "" ? 0 : 1
  bucket = var.front["log_bucket_name"]
  acl    = "log-delivery-write"

  tags = merge(local.common_tags, var.custom_tags)

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = var.front["log_bucket_expiration_days"]
    }
  }
}

resource "aws_s3_bucket" "front" {
  bucket = var.front["bucket_name"]
  acl    = "private"

  website {
    index_document = var.front["index_document"]
    error_document = var.front["error_document"]
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(local.common_tags, var.custom_tags)
}

resource "aws_s3_bucket_policy" "front" {
  bucket = aws_s3_bucket.front.id

  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":
  [
    {
      "Effect":"Allow",
      "Principal":
      {
        "AWS":"${aws_iam_user.s3_front_user.arn}"
      },
      "Action":"s3:listbucket",
      "Resource":"${aws_s3_bucket.front.arn}"
    },
    {
      "Effect":"Allow",
      "Principal":
      {
        "AWS":"${aws_iam_user.s3_front_user.arn}"
      },
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObjectAcl"
      ],
      "Resource":"${aws_s3_bucket.front.arn}/*"
    },
    {
      "Sid": "Allow get requests originating cloudfront referer",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.front.arn}/*",
      "Condition": {
        "StringLike": {
          "aws:Referer": "${data.aws_ssm_parameter.referer.value}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  origin {
    domain_name = aws_s3_bucket.front.website_endpoint
    origin_id   = local.s3_origin_id

    custom_header {
      name  = "Referer"
      value = data.aws_ssm_parameter.referer.value
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols    = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2"
      ]
    }
  }

  dynamic "origin" {
    for_each                 = [for i in "${var.dynamic_custom_origin_config}" : {
      name                   = i.domain_name
      id                     = i.origin_id
      path                   = i.origin_path
      http_port              = i.http_port
      https_port             = i.https_port
      origin_protocol_policy = i.origin_protocol_policy
      origin_ssl_protocols   = i.origin_ssl_protocols
      custom_headers         = i.custom_headers
    }]
    content {
      domain_name    = origin.value.name
      origin_id      = origin.value.id
      origin_path    = origin.value.path
      custom_origin_config {
        http_port                = origin.value.http_port
        https_port               = origin.value.https_port
        origin_protocol_policy   = origin.value.origin_protocol_policy
        origin_ssl_protocols     = origin.value.origin_ssl_protocols
      }
      dynamic "custom_header" {
        for_each = [ for j in "${origin.value.custom_headers}" : {
          name   = j.name
          value  = j.value
        }]
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  wait_for_deployment = var.front["wait_for_deployment"]
  web_acl_id          = var.front["web_acl_id"]

  aliases = var.front["aliases"] != [] ? var.front["aliases"] : null

  dynamic "logging_config" {
    for_each = var.front["log_bucket_name"] == "" ? [] : list("logging_config")
    content {
      include_cookies = false
      bucket          = aws_s3_bucket.log_bucket[0].bucket_domain_name
    }
  }

  dynamic "custom_error_response" {
    for_each = var.front["custom_error_response"]
    content {
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
      error_code            = lookup(custom_error_response.value, "error_code", null)
      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    compress         = true
    smooth_streaming = false

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 1350
    max_ttl                = 31536000
  }

  dynamic "ordered_cache_behavior" {
    for_each = [for i in "${var.dynamic_ordered_cache_behavior}" : {
      path_pattern           = i.path_pattern
      allowed_methods        = i.allowed_methods
      cached_methods         = i.cached_methods
      target_origin_id       = i.target_origin_id
      compress               = i.compress
      query_string           = i.query_string
      cookies_forward        = i.cookies_forward
      headers                = i.headers
      viewer_protocol_policy = i.viewer_protocol_policy
      min_ttl                = i.min_ttl
      default_ttl            = i.default_ttl
      max_ttl                = i.max_ttl
    }]
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      target_origin_id = ordered_cache_behavior.value.target_origin_id
      compress         = ordered_cache_behavior.value.compress

      forwarded_values {
        query_string = ordered_cache_behavior.value.query_string
        cookies {
          forward = ordered_cache_behavior.value.cookies_forward
        }
        headers = ordered_cache_behavior.value.headers
      }
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      min_ttl                = ordered_cache_behavior.value.min_ttl
      default_ttl            = ordered_cache_behavior.value.default_ttl
      max_ttl                = ordered_cache_behavior.value.max_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = var.front["cloudfront_price_class"]

  tags = merge(local.common_tags, var.custom_tags)

  viewer_certificate {
    acm_certificate_arn            = var.front["acm_arn"]
    cloudfront_default_certificate = var.front["acm_arn"] == null ? true : false
    minimum_protocol_version       = var.front["minimum_protocol_version"]
    ssl_support_method             = var.front["acm_arn"] == null ? null : var.front["ssl_support_method"]
  }
}

resource "aws_iam_user" "s3_front_user" {
  name = "tf-${var.prefix}-${var.project}-${var.env}-s3-front-user"
}

resource "aws_iam_access_key" "s3_front_user_key" {
  user = aws_iam_user.s3_front_user.name
}

resource "aws_iam_policy" "s3_front_user" {
  name        = "tf-${var.prefix}-${var.project}-${var.env}-s3-front-user-policy"
  path        = "/"
  description = "S3 front access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
     "Resource": [
        "${aws_s3_bucket.front.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
         "${aws_s3_bucket.front.arn}/*"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ],
      "Resource":"${aws_cloudfront_distribution.s3_distribution.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "s3_front_user" {
  user       = aws_iam_user.s3_front_user.name
  policy_arn = aws_iam_policy.s3_front_user.arn
}
