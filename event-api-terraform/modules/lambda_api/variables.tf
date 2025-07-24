variable "lambda_name" {}
variable "lambda_zip" {}
variable "handler" {}
variable "runtime" {}
variable "lambda_role" {}
variable "rest_api_id" {}
variable "resource_id" {}
variable "http_method" {}
variable "api_execution_arn" {}
variable "resource_path" {
  default = "events"
}
variable "lambda_layers" {
  type    = list(string)
  default = []
}