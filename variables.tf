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
