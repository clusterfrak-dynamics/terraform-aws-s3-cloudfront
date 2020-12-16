# terraform-aws-s3-cloudfront

[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/terraform-aws-s3-cloudfront)
[![terraform-kubernetes-addons](https://github.com/particuleio/terraform-aws-s3-cloudfront/workflows/terraform-aws-s3-cloudfront/badge.svg)](https://github.com/particuleio/terraform-aws-s3-cloudfront/actions?query=workflow%3Aterraform-aws-s3-cloudfront)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws | n/a | `any` | `{}` | no |
| custom\_tags | n/a | `map(any)` | `{}` | no |
| dns | n/a | `any` | `{}` | no |
| env | n/a | `any` | n/a | yes |
| front | n/a | `any` | `{}` | no |
| prefix | n/a | `string` | `""` | no |
| project | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudfront\_distribution\_id | n/a |
| cloudfront\_domain\_name | n/a |
| s3\_user\_access\_key\_id | n/a |
| s3\_user\_secret\_access\_key | n/a |
