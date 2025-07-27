# Main Terraform Infrastructure - Multi-Environment with Workspaces

This directory contains the main Terraform configuration for the EFY web backend infrastructure, including Lambda functions, API Gateway, and supporting resources. It uses Terraform workspaces to manage multiple environments (dev, qa, prod).

## Prerequisites

Before using this configuration, you must set up the backend infrastructure first:

```powershell
# Navigate to backend-setup directory
cd terraform/backend-setup

# Set up backend infrastructure for dev environment
.\workspace.ps1 init dev
.\workspace.ps1 apply dev

# Set up backend infrastructure for qa environment
.\workspace.ps1 init qa
.\workspace.ps1 apply qa

# Set up backend infrastructure for prod environment
.\workspace.ps1 init prod
.\workspace.ps1 apply prod
```

## Infrastructure Components

### Lambda Layers
- **Dependencies Layer**: Shared dependencies for Lambda functions (aws-sdk, lodash, joi, bcrypt)
- **Utility Layer**: Shared utility functions for Lambda functions (response helpers, validation, JSON parsing)

### Lambda Functions
- **get-xyz**: GET /xyz endpoint handler
  - Returns success response with message, requestId, and timestamp
  - Uses utility layer for standardized response formatting
- **post-xyz**: POST /xyz endpoint handler
  - Accepts JSON body with required 'name' field
  - Validates input using utility functions
  - Returns success response with received data

### API Gateway
- REST API with `/xyz` endpoint
- GET and POST methods
- Lambda integration with proper permissions
- CORS headers configured in utility layer

## Workspace Management

This setup uses Terraform workspaces to manage different environments. Each workspace corresponds to an environment and maintains its own state.

### Using the Workspace Management Script

#### Windows (PowerShell)
```powershell
# Navigate to the terraform directory
cd terraform

# Initialize and set up workspace for dev environment
.\workspace.ps1 init dev

# Plan changes for dev environment
.\workspace.ps1 plan dev

# Apply changes for dev environment
.\workspace.ps1 apply dev

# List all workspaces
.\workspace.ps1 list

# Show current workspace
.\workspace.ps1 show

# Destroy resources for dev environment
.\workspace.ps1 destroy dev
```

#### Linux/Mac (Bash)
```bash
# Navigate to the terraform directory
cd terraform

# Make script executable (first time only)
chmod +x workspace.sh

# Initialize and set up workspace for dev environment
./workspace.sh init dev

# Plan changes for dev environment
./workspace.sh plan dev

# Apply changes for dev environment
./workspace.sh apply dev

# List all workspaces
./workspace.sh list

# Show current workspace
./workspace.sh show

# Destroy resources for dev environment
./workspace.sh destroy dev
```

### Manual Workspace Commands

If you prefer to use Terraform commands directly:

```bash
# Initialize Terraform
terraform init

# Create and select workspace for dev
terraform workspace new dev
terraform workspace select dev

# Create and select workspace for qa
terraform workspace new qa
terraform workspace select qa

# Create and select workspace for prod
terraform workspace new prod
terraform workspace select prod

# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Plan and apply for current workspace
terraform plan
terraform apply
```

## Environment-Specific Configuration

The configuration automatically detects the current workspace and applies environment-specific settings:

- **Resource Naming**: Resources are automatically named with the workspace/environment prefix
- **Tags**: Each environment gets specific tags including CostCenter
- **Validation**: Only valid workspaces (dev, qa, prod) are allowed

## Resource Naming Convention

All resources follow this naming pattern:
```
{project-name}-{environment}-{resource-type}
```

Examples:
- `efy-web-backend-dev-get-xyz` (Lambda function)
- `efy-web-backend-dev-dependencies-layer` (Lambda layer)
- `efy-web-backend-dev-api` (API Gateway)

## Workspace State Management

Each workspace maintains its own state file:
- `terraform.tfstate.d/dev/terraform.tfstate` - Dev environment state
- `terraform.tfstate.d/qa/terraform.tfstate` - QA environment state  
- `terraform.tfstate.d/prod/terraform.tfstate` - Production environment state

## Backend Configuration

The configuration uses the S3 backend and DynamoDB table created by the backend-setup:

```hcl
backend "s3" {
  bucket         = "efy-web-backend-{environment}-terraform-state-123456"
  key            = "main-infrastructure/terraform.tfstate"
  region         = "ap-south-1"
  encrypt        = true
  dynamodb_table = "efy-web-backend-{environment}-terraform-locks"
}
```

## Deployment Workflow

### 1. Set Up Backend Infrastructure (One-time)
```powershell
cd terraform/backend-setup
.\workspace.ps1 init dev
.\workspace.ps1 apply dev
```

### 2. Deploy Main Infrastructure
```powershell
cd terraform
.\workspace.ps1 init dev
.\workspace.ps1 plan dev
.\workspace.ps1 apply dev
```

### 3. Deploy to Other Environments
```powershell
# QA Environment
.\workspace.ps1 init qa
.\workspace.ps1 apply qa

# Production Environment
.\workspace.ps1 init prod
.\workspace.ps1 apply prod
```

## Current Lambda Functions

### GET /xyz Function
```javascript
// lambda_functions/get_xyz/index.js
const { successResponse, errorResponse } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Sample business logic
        const data = {
            message: 'GET XYZ function executed successfully!',
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data);
        
    } catch (error) {
        console.error('Error in get_xyz function:', error);
        return errorResponse(error, 500);
    }
};
```

### POST /xyz Function
```javascript
// lambda_functions/post_xyz/index.js
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        // Validate required fields (example)
        validateRequired(body, ['name']);
        
        // Sample business logic
        const data = {
            message: 'POST XYZ function executed successfully!',
            receivedData: body,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Data created successfully');
        
    } catch (error) {
        console.error('Error in post_xyz function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};
```

## Shared Utility Functions

The utility layer provides common functions used across Lambda functions:

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

const validateRequired = (obj, fields) => {
    const missing = fields.filter(field => !obj[field]);
    if (missing.length > 0) {
        throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }
};

const parseJSON = (str) => {
    try {
        return JSON.parse(str);
    } catch (e) {
        throw new Error('Invalid JSON format');
    }
};
```

## Outputs

After applying the configuration, you'll get:

- **Environment**: Current workspace/environment
- **Lambda ARNs**: ARNs of deployed Lambda functions
- **Layer ARNs**: ARNs of Lambda layers
- **API Gateway ID**: ID of the API Gateway
- **API Gateway URL**: Invoke URL for the API
- **Common Tags**: Tags applied to all resources

## Important Notes

1. **Backend Setup**: Always set up the backend infrastructure first
2. **Unique Names**: Ensure bucket names in backend-setup are globally unique
3. **Workspace Validation**: Only `dev`, `qa`, and `prod` workspaces are allowed
4. **State Isolation**: Each workspace has completely isolated state
5. **Resource Tags**: All resources are properly tagged for cost tracking and management

## Security Features

- **Encryption**: S3 backend uses server-side encryption
- **State Locking**: DynamoDB table prevents concurrent modifications
- **IAM Roles**: Lambda functions use least-privilege IAM roles
- **API Gateway**: Proper Lambda permissions and integrations
- **CORS**: Proper CORS headers configured in utility layer

## Troubleshooting

### Common Issues

1. **Backend not set up**: Make sure to run backend-setup first
2. **Invalid workspace**: Use only dev, qa, or prod workspaces
3. **Bucket name conflicts**: Ensure backend bucket names are unique
4. **Permission issues**: Check AWS credentials and permissions

### Getting Help

```powershell
# Show script help
.\workspace.ps1 help

# Show current workspace
terraform workspace show

# List all workspaces
terraform workspace list

# Check backend configuration
terraform init -reconfigure
```

## File Structure

```
terraform/
├── main.tf                 # Main infrastructure configuration
├── backend.tf              # Backend configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── workspace.ps1           # Workspace management script (Windows)
├── workspace.sh            # Workspace management script (Linux/Mac)
├── modules/                # Terraform modules
│   ├── lambda/            # Lambda function module
│   ├── lambda_layer/      # Lambda layer module
│   └── api_gateway/       # API Gateway module
└── README.md              # This file
```

## Next Steps

1. Update the backend bucket names in `backend.tf` to match your actual backend setup
2. Customize the Lambda function code in `../lambda_functions/`
3. Add additional resources as needed
4. Set up CI/CD pipeline for automated deployments 