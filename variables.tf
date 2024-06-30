variable "region" {
  default = "us-east-1"
}

variable "apiname" {
  description = "The name of api gateway"
  type        = string
}

variable "apidescription" {
  description = "The description of api gateway"
  type        = string
}

variable "environment" {
  description = "The description of environment"
  type        = string
}

variable "userpoolarn" {
  description = "The arn of userpool"
  type        = string
}

variable "sg_ids" {
  description = "Security group ids array"
  type = list(string)
}

variable "subnets_ids" {
  description = "Subnet ids array"
  type = list(string)
}

variable "gx_client_id" {
  description = "Genexus Client Id"
  type = string
}

variable "cognito_user_pool_id" {
  description = "Cognito user pool"
  type = string
}

variable "cognito_client_id" {
  description = "Cognito client id"
  type = string
}