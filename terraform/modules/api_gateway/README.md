# API Gateway Module

This Terraform module creates AWS API Gateway REST API with Lambda integrations, proper permissions, and deployment configuration.

## Features

- **REST API Creation**: Creates API Gateway REST API with proper naming
- **Lambda Integration**: Integrates Lambda functions with API Gateway
- **Method Configuration**: Supports GET and POST methods
- **CORS Support**: CORS headers configured in Lambda responses
- **Deployment Management**: Automatic deployment and stage management
- **Permission Management**: Proper Lambda permissions for API Gateway invocation
- **Resource Tagging**: Proper resource tagging for cost tracking

## Usage

```hcl
module "api_gateway" {
  source = "./modules/api_gateway"
  
  api_name        = "my-api"
  get_lambda_arn  = module.get_function.invoke_arn
  post_lambda_arn = module.post_function.invoke_arn
  region          = "ap-south-1"
  
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
| api_name | Name of the API Gateway REST API | `string` | n/a | yes |
| get_lambda_arn | Invocation ARN of the GET Lambda function | `string` | n/a | yes |
| post_lambda_arn | Invocation ARN of the POST Lambda function | `string` | n/a | yes |
| region | AWS region for the API Gateway | `string` | n/a | yes |
| tags | Map of tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_id | ID of the API Gateway REST API |
| api_arn | ARN of the API Gateway REST API |
| execution_arn | Execution ARN of the API Gateway |
| invoke_url | Invoke URL for the API Gateway |

## API Endpoints

The module creates the following endpoints:

### GET /xyz
- **Method**: GET
- **Path**: `/xyz`
- **Integration**: Lambda function (GET handler)
- **Authorization**: NONE (public access)

### POST /xyz
- **Method**: POST
- **Path**: `/xyz`
- **Integration**: Lambda function (POST handler)
- **Authorization**: NONE (public access)

## Examples

### Basic API Gateway

```hcl
module "basic_api" {
  source = "./modules/api_gateway"
  
  api_name        = "basic-api"
  get_lambda_arn  = module.get_function.invoke_arn
  post_lambda_arn = module.post_function.invoke_arn
  region          = "ap-south-1"
}
```

### API Gateway with Tags

```hcl
module "tagged_api" {
  source = "./modules/api_gateway"
  
  api_name        = "tagged-api"
  get_lambda_arn  = module.get_function.invoke_arn
  post_lambda_arn = module.post_function.invoke_arn
  region          = "ap-south-1"
  
  tags = {
    Project     = "my-project"
    Environment = "production"
    CostCenter  = "development"
    ManagedBy   = "terraform"
  }
}
```

## Lambda Permissions

The module automatically creates Lambda permissions for API Gateway invocation:

```hcl
resource "aws_lambda_permission" "get_xyz" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.get_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
```

## Deployment and Stages

The module automatically:

1. **Creates Deployment**: Deploys the API Gateway configuration
2. **Creates Stage**: Creates a "default" stage for the API
3. **Manages Dependencies**: Ensures proper deployment order

## CORS Configuration

CORS headers are handled in the Lambda function responses:

```javascript
// Example CORS headers in Lambda response
headers: {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
}
```

## API Gateway Resources

The module creates the following resources:

1. **REST API**: Main API Gateway REST API
2. **Resource**: `/xyz` resource
3. **Methods**: GET and POST methods for `/xyz`
4. **Integrations**: Lambda integrations for both methods
5. **Permissions**: Lambda permissions for API Gateway invocation
6. **Deployment**: API Gateway deployment
7. **Stage**: Default stage for the API

## Best Practices

1. **Use Descriptive Names**: Use descriptive API names for easy identification
2. **Proper Tagging**: Always tag resources for cost tracking
3. **CORS Handling**: Handle CORS in Lambda responses for flexibility
4. **Error Handling**: Implement proper error handling in Lambda functions
5. **Monitoring**: Set up CloudWatch monitoring for API Gateway

## Security Considerations

- **Public Access**: API endpoints are publicly accessible (no authorization)
- **Lambda Permissions**: Only API Gateway can invoke the Lambda functions
- **CORS**: CORS is handled in Lambda responses for flexibility
- **Logging**: API Gateway logs are sent to CloudWatch

## Dependencies

- AWS Provider (version ~> 5.0)

## Notes

- The module creates a "default" stage for the API
- Lambda permissions are automatically created for API Gateway invocation
- CORS is handled in Lambda responses rather than API Gateway configuration
- All resources are properly tagged for management
- The API is deployed automatically when created

## Troubleshooting

### Common Issues

1. **Lambda Permission Errors**: Ensure Lambda functions exist before creating API Gateway
2. **Deployment Issues**: Check that all integrations are properly configured
3. **CORS Issues**: Verify CORS headers are set in Lambda responses

### Testing the API

```bash
# Test GET endpoint
curl -X GET https://{api-id}.execute-api.{region}.amazonaws.com/default/xyz

# Test POST endpoint
curl -X POST https://{api-id}.execute-api.{region}.amazonaws.com/default/xyz \
  -H "Content-Type: application/json" \
  -d '{"name": "test"}'
``` 