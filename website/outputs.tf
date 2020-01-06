output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}

output "s3_user_access_key_id" {
  value = aws_iam_access_key.s3_front_user_key.id
}

output "s3_user_secret_access_key" {
  value     = aws_iam_access_key.s3_front_user_key.secret
  sensitive = true
}
