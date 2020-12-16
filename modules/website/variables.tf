variable "env" {}

variable "aws" {
  type    = any
  default = {}
}

variable "dns" {
  type    = any
  default = {}
}

variable "front" {
  type    = any
  default = {}
}

variable "custom_tags" {
  type    = map(any)
  default = {}
}

variable "project" {
  default = ""
}

variable "prefix" {
  default = ""
}

variable "dynamic_custom_origin_config" {
  type    = list(any)
  default = []
}

variable "dynamic_ordered_cache_behavior" {
  type    = list(any)
  default = []
}

variable "ssm_referer_key" {
  default = "/cloudfront/default/referer"
}
