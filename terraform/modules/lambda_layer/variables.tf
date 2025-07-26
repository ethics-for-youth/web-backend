variable "layer_name" {
  description = "Name of the Lambda layer"
  type        = string
}

variable "layer_zip_path" {
  description = "Path to the layer zip file"
  type        = string
}

variable "description" {
  description = "Description of the layer"
  type        = string
}

variable "compatible_runtimes" {
  description = "List of compatible runtimes"
  type        = list(string)
  default     = ["nodejs18.x", "nodejs20.x"]
}
