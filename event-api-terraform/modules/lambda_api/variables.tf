variable "lambda_name" {}
variable "lambda_zip" {}
variable "handler" {}
variable "runtime" {}
variable "lambda_role" {}
variable "api_id" {}
variable "route_key" {}
variable "api_execution_arn" {}
variable "lambda_layers" {
  type    = list(string)
  default = []
}
