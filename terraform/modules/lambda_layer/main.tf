# Use pre-built layer zip with reproducible timestamps
# The zip is created by build.sh script with SOURCE_DATE_EPOCH=1
# This ensures the hash only changes when actual content changes, not timestamps

locals {
  # Extract just the layer name (e.g., "dependencies-layer" or "utility-layer")
  layer_base_name = replace(var.layer_name, "/^.*-(dependencies|utility)-layer$/", "$1-layer")
  zip_path        = "${path.root}/builds/${local.layer_base_name}.zip"
}

# Compute hash from the pre-built zip file
data "local_file" "layer_zip" {
  filename = local.zip_path
}

resource "aws_lambda_layer_version" "this" {
  filename    = local.zip_path
  layer_name  = var.layer_name
  description = var.description

  compatible_runtimes = var.compatible_runtimes
  # Use filebase64sha256 to compute hash from the pre-built zip
  source_code_hash = filebase64sha256(local.zip_path)

  lifecycle {
    create_before_destroy = true
  }

  # Ensure the zip file exists before trying to create the layer
  depends_on = [data.local_file.layer_zip]
}
