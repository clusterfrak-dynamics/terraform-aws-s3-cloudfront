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
  type    = map
  default = {}
}

variable "project" {
  default = ""
}

variable "prefix" {
  default = ""
}

variable "dynamic_custom_origin_config" {
  type    = list
  default = []
}

variable "dynamic_ordered_cache_behavior" {
  type    = list
  default = []
}
