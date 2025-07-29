# Automatically create zip file from source directory
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/builds/${var.layer_name}.zip"

  # This ensures Terraform detects code changes
  excludes = ["*.zip"]
}

resource "aws_lambda_layer_version" "this" {
  filename    = data.archive_file.layer_zip.output_path
  layer_name  = var.layer_name
  description = var.description

  compatible_runtimes = var.compatible_runtimes
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256

  lifecycle {
    create_before_destroy = true
  }
}
