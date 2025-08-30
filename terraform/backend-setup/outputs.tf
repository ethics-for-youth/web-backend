output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "backend_configuration" {
  description = "Backend configuration block for your main Terraform config"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.bucket}"
        key            = "terraform.tfstate"
        region         = "${var.aws_region}"
        encrypt        = true
        use_lockfile   = true
      }
    }
  EOT
}
