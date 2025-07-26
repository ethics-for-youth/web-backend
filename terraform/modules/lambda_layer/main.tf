resource "aws_lambda_layer_version" "this" {
  filename         = var.layer_zip_path
  layer_name       = var.layer_name
  description      = var.description
  
  compatible_runtimes = var.compatible_runtimes
  source_code_hash   = filebase64sha256(var.layer_zip_path)
  
  lifecycle {
    create_before_destroy = true
  }
}
