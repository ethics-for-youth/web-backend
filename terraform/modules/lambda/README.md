# Lambda Function Module

This Terraform module creates AWS Lambda functions with proper IAM roles, permissions, and configuration.

## Features

- **Automatic ZIP creation**: Automatically creates deployment packages from source directories
- **IAM Role Management**: Creates least-privilege IAM roles for Lambda execution
- **Layer Support**: Supports Lambda layers for shared code and dependencies
- **Environment Variables**: Configurable environment variables
- **Tags**: Proper resource tagging for cost tracking and management
- **Source Code Hashing**: Automatic updates when source code changes

## Usage

```hcl
module "my_lambda_function" {
  source = "./modules/lambda"
  
  function_name = "my-function"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/my_function"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "info"
  }
  
  tags = {
    Project     = "my-project"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| function_name | Name of the Lambda function | `string` | n/a | yes |
| handler | Lambda function handler (e.g., "index.handler") | `string` | n/a | yes |
| runtime | Lambda runtime (e.g., "nodejs18.x") | `string` | n/a | yes |
| source_dir | Path to the source code directory | `string` | n/a | yes |
| layers | List of Lambda layer ARNs to attach | `list(string)` | `[]` | no |
| environment_variables | Map of environment variables | `map(string)` | `{}` | no |
| tags | Map of tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_name | Name of the Lambda function |
| function_arn | ARN of the Lambda function |
| invoke_arn | Invocation ARN of the Lambda function |
| role_arn | ARN of the IAM role |

## Examples

### Basic Lambda Function

```hcl
module "simple_lambda" {
  source = "./modules/lambda"
  
  function_name = "simple-function"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/simple"
}
```

### Lambda Function with Layers

```hcl
module "function_with_layers" {
  source = "./modules/lambda"
  
  function_name = "function-with-layers"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/with_layers"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
}
```

### Lambda Function with Environment Variables

```hcl
module "function_with_env" {
  source = "./modules/lambda"
  
  function_name = "function-with-env"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/with_env"
  
  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "debug"
    API_URL     = "https://api.example.com"
  }
  
  tags = {
    Project     = "my-project"
    Environment = "prod"
    CostCenter  = "development"
  }
}
```

## IAM Permissions

The module creates an IAM role with the following permissions:

- **Basic Execution Role**: `arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole`
  - CloudWatch Logs permissions for logging
  - Basic Lambda execution permissions

## Source Code Management

The module automatically:

1. **Creates ZIP files**: Uses `archive_file` data source to create deployment packages
2. **Detects changes**: Uses `source_code_hash` to detect source code changes
3. **Excludes files**: Automatically excludes `.zip` files from the package
4. **Outputs to builds directory**: Places ZIP files in `./builds/` directory

## Best Practices

1. **Use Layers**: Place shared dependencies in Lambda layers
2. **Environment Variables**: Use environment variables for configuration
3. **Proper Tagging**: Always tag resources for cost tracking
4. **Source Organization**: Keep source code organized in separate directories
5. **Handler Naming**: Use descriptive handler names (e.g., "index.handler")

## Dependencies

- AWS Provider (version ~> 5.0)
- Archive Provider (version ~> 2.2)

## Notes

- The module automatically creates the `./builds/` directory if it doesn't exist
- Source code changes trigger automatic Lambda function updates
- IAM roles are created with least-privilege permissions
- All resources are properly tagged for management 