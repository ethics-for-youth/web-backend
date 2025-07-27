# Lambda Layer Module

This Terraform module creates AWS Lambda layers for sharing code and dependencies across multiple Lambda functions.

## Features

- **Automatic ZIP creation**: Automatically creates deployment packages from source directories
- **Layer Management**: Creates Lambda layers with proper naming and versioning
- **Source Code Hashing**: Automatic updates when source code changes
- **Resource Tagging**: Proper resource tagging for cost tracking and management
- **Flexible Source**: Supports any source directory structure

## Usage

```hcl
module "dependencies_layer" {
  source = "./modules/lambda_layer"
  
  layer_name  = "my-dependencies-layer"
  source_dir  = "../layers/dependencies"
  description = "Shared dependencies for Lambda functions"
  
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
| layer_name | Name of the Lambda layer | `string` | n/a | yes |
| source_dir | Path to the source code directory | `string` | n/a | yes |
| description | Description of the Lambda layer | `string` | `""` | no |
| tags | Map of tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| layer_name | Name of the Lambda layer |
| layer_arn | ARN of the Lambda layer |
| layer_version | Version of the Lambda layer |

## Examples

### Dependencies Layer

```hcl
module "dependencies_layer" {
  source = "./modules/lambda_layer"
  
  layer_name  = "dependencies-layer"
  source_dir  = "../layers/dependencies"
  description = "Shared Node.js dependencies for Lambda functions"
  
  tags = {
    Project     = "my-project"
    Environment = "prod"
    Purpose     = "dependencies"
  }
}
```

### Utility Layer

```hcl
module "utility_layer" {
  source = "./modules/lambda_layer"
  
  layer_name  = "utility-layer"
  source_dir  = "../layers/utility"
  description = "Shared utility functions for Lambda functions"
  
  tags = {
    Project     = "my-project"
    Environment = "prod"
    Purpose     = "utilities"
  }
}
```

## Layer Structure

Lambda layers should follow this directory structure:

```
layers/
├── dependencies/
│   └── nodejs/
│       ├── package.json
│       └── node_modules/
└── utility/
    └── nodejs/
        ├── package.json
        └── utils.js
```

### Node.js Layer Structure

For Node.js layers, the code should be placed in a `nodejs/` subdirectory:

```
layers/my_layer/
└── nodejs/
    ├── package.json
    ├── utils.js
    └── node_modules/
```

## Source Code Management

The module automatically:

1. **Creates ZIP files**: Uses `archive_file` data source to create deployment packages
2. **Detects changes**: Uses `source_code_hash` to detect source code changes
3. **Excludes files**: Automatically excludes `.zip` files from the package
4. **Outputs to builds directory**: Places ZIP files in `./builds/` directory

## Best Practices

1. **Layer Organization**: Organize layers by purpose (dependencies, utilities, etc.)
2. **Descriptive Names**: Use descriptive layer names for easy identification
3. **Proper Tagging**: Always tag resources for cost tracking
4. **Source Organization**: Keep source code organized in separate directories
5. **Version Management**: Let Terraform handle layer versioning automatically

## Common Layer Types

### Dependencies Layer

Contains shared Node.js dependencies:

```json
// layers/dependencies/nodejs/package.json
{
  "name": "lambda-dependencies",
  "version": "1.0.0",
  "description": "Shared dependencies for Lambda functions",
  "dependencies": {
    "aws-sdk": "^2.1000.0",
    "lodash": "^4.17.21",
    "joi": "^17.6.0",
    "bcrypt": "^5.0.1"
  }
}
```

### Utility Layer

Contains shared utility functions:

```javascript
// layers/utility/nodejs/utils.js
const response = (statusCode, body, headers = {}) => {
    return {
        statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
            ...headers
        },
        body: JSON.stringify(body)
    };
};

const successResponse = (data, message = 'Success') => {
    return response(200, { success: true, message, data });
};

const errorResponse = (error, statusCode = 400) => {
    return response(statusCode, { 
        success: false, 
        error: error.message || error 
    });
};

module.exports = {
    response,
    successResponse,
    errorResponse
};
```

## Using Layers in Lambda Functions

To use layers in Lambda functions:

```hcl
module "my_lambda" {
  source = "./modules/lambda"
  
  function_name = "my-function"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  source_dir    = "../lambda_functions/my_function"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
}
```

In your Lambda function code:

```javascript
// Access dependencies from layers
const AWS = require('aws-sdk');
const _ = require('lodash');

// Access utility functions from layers
const { successResponse, errorResponse } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
    try {
        // Your function logic here
        return successResponse({ message: 'Success' });
    } catch (error) {
        return errorResponse(error, 500);
    }
};
```

## Dependencies

- AWS Provider (version ~> 5.0)
- Archive Provider (version ~> 2.2)

## Notes

- The module automatically creates the `./builds/` directory if it doesn't exist
- Source code changes trigger automatic layer updates
- Layer versions are managed automatically by Terraform
- All resources are properly tagged for management
- Layers are automatically attached to Lambda functions when specified

## Troubleshooting

### Common Issues

1. **Layer Not Found**: Ensure the layer exists before attaching to Lambda functions
2. **Import Errors**: Check that the layer structure follows the correct pattern
3. **Version Conflicts**: Let Terraform handle layer versioning automatically

### Layer Size Limits

- **Maximum size**: 250 MB unzipped
- **Maximum layers per function**: 5 layers
- **Maximum total size**: 250 MB across all layers

### Best Practices for Layer Management

1. **Keep layers small**: Only include necessary dependencies
2. **Use descriptive names**: Make layer purposes clear
3. **Version control**: Let Terraform handle versioning
4. **Test thoroughly**: Test layers with actual Lambda functions
5. **Monitor usage**: Track layer usage and costs 