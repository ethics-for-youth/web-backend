# S3 Bucket for static website hosting
resource "aws_s3_bucket" "static_hosting" {
  bucket = var.bucket_name

  tags = var.tags
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# S3 Bucket Policy for public read access
resource "aws_s3_bucket_policy" "static_hosting" {
  bucket     = aws_s3_bucket.static_hosting.id
  depends_on = [aws_s3_bucket_public_access_block.static_hosting]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_hosting.arn}/*"
      }
    ]
  })
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "static_hosting" {
  count  = var.enable_cors ? 1 : 0
  bucket = aws_s3_bucket.static_hosting.id

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}