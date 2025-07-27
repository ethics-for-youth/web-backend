# EFY Web Backend Infrastructure

This repository contains the infrastructure code for the EFY Web Backend, including AWS Lambda functions, API Gateway, and supporting resources managed with Terraform. The project implements a serverless architecture with multi-environment support using Terraform workspaces.

## 📁 Repository Structure

```
web-backend/
├── .github/workflows/           # GitHub Actions CI/CD workflows
│   ├── terraform.yml           # Main validation and planning workflow
│   ├── terraform-deploy.yml    # Reusable deployment workflow
│   ├── terraform-plan.yml      # Reusable planning workflow
│   ├── terraform-validate.yml  # Reusable validation workflow
│   ├── deploy-dev.yml          # Dev environment deployment
│   ├── deploy-qa.yml           # QA environment deployment
│   └── deploy-prod.yml         # Production environment deployment
├── docs/                       # Documentation
│   └── api_spec.yaml          # OpenAPI 3.0 specification
├── lambda_functions/           # AWS Lambda function code
│   ├── get_xyz/               # GET /xyz endpoint handler
│   │   ├── index.js           # Function code
│   │   └── package.json       # Dependencies
│   └── post_xyz/              # POST /xyz endpoint handler
│       ├── index.js           # Function code
│       └── package.json       # Dependencies
├── layers/                     # Lambda layers (shared code)
│   ├── dependencies/           # Common dependencies layer
│   │   └── nodejs/
│   │       └── package.json   # Shared dependencies (aws-sdk, lodash, joi, bcrypt)
│   └── utility/               # Utility functions layer
│       └── nodejs/
│           ├── package.json   # Layer configuration
│           └── utils.js       # Shared utility functions
├── scripts/                    # Build and deployment scripts
│   ├── build.sh               # Bash build script (Linux/macOS)
│   └── build.ps1              # PowerShell build script (Windows)
├── terraform/                  # Infrastructure as Code
│   ├── backend-setup/         # Backend infrastructure (S3, DynamoDB)
│   │   ├── workspace.sh       # Backend workspace management (Bash)
│   │   ├── workspace.ps1      # Backend workspace management (PowerShell)
│   │   ├── main.tf           # Backend resources
│   │   ├── variables.tf      # Backend variables
│   │   └── outputs.tf        # Backend outputs
│   ├── modules/               # Reusable Terraform modules
│   │   ├── api_gateway/      # API Gateway module
│   │   ├── lambda/           # Lambda function module
│   │   └── lambda_layer/     # Lambda layer module
│   ├── workspace.sh          # Main workspace management (Bash)
│   ├── workspace.ps1         # Main workspace management (PowerShell)
│   ├── main.tf               # Main infrastructure
│   ├── backend.tf            # Backend configuration
│   ├── variables.tf          # Input variables
│   └── outputs.tf            # Output values
└── README.md                 # This file
```

## 🚀 Quick Start

### Prerequisites

- **Terraform** (v1.0.0 or higher)
- **AWS CLI** (configured with appropriate credentials)
- **Node.js** (for Lambda function development)
- **Git** (for version control)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd web-backend
   ```

2. **Set up backend infrastructure:**
   ```bash
   cd terraform/backend-setup
   ./workspace.sh init dev
   ./workspace.sh apply dev
   ```

3. **Initialize main infrastructure:**
   ```bash
   cd ../../
   cd terraform
   ./workspace.sh init dev
   ```

## 🔄 GitHub Actions CI/CD Pipeline

The repository uses GitHub Actions for automated deployment with manual approval gates. The pipeline is designed for safety and includes comprehensive validation and planning stages.

### Pipeline Overview

#### 1. **Validation & Planning Workflow** (`terraform.yml`)
**Triggers**: Pull requests to `main` and `develop` branches
**Purpose**: Validates Terraform configuration and generates plans for all environments

**Jobs**:
- **Validate**: Runs `terraform validate` on all configurations
- **Plan Dev**: Generates plan for dev environment (triggered on `develop` branch)
- **Plan QA**: Generates plan for qa environment (triggered on `main` branch)
- **Plan Prod**: Generates plan for production environment (triggered on `main` branch)

**Features**:
- ✅ Automatic validation of Terraform configurations
- ✅ Environment-specific planning
- ✅ PR comments with detailed plan outputs
- ✅ Path-based triggers (only runs when relevant files change)

#### 2. **Environment-Specific Deployment Workflows**

##### **Dev Environment** (`deploy-dev.yml`)
**Triggers**:
- Push to `develop` branch
- Manual workflow dispatch

**Features**:
- ✅ Automatic deployment on push to `develop`
- ✅ Manual approval gate (optional)
- ✅ Skip approval option for testing
- ✅ Force deployment option

##### **QA Environment** (`deploy-qa.yml`)
**Triggers**: Push to `main` branch

**Features**:
- ✅ Automatic planning and validation
- ✅ Mandatory manual approval
- ✅ Safe deployment process

##### **Production Environment** (`deploy-prod.yml`)
**Triggers**: Push to `main` branch with `[deploy-prod]` in commit message

**Features**:
- ✅ Special commit message trigger (`[deploy-prod]`)
- ✅ Mandatory manual approval
- ✅ Extra safety measures for production

### Approval Process

All deployments require manual approval from `mohammadn0man`:

| Environment | Approval Required | Trigger |
|-------------|-------------------|---------|
| **Dev** | Optional (can be skipped) | Push to `develop` |
| **QA** | Mandatory | Push to `main` |
| **Production** | Mandatory | Push to `main` + `[deploy-prod]` |

### How to Use the CI/CD Pipeline

#### **For Development (Dev Environment)**

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/new-lambda-function
   ```

2. **Make your changes:**
   ```bash
   # Edit your files
   git add .
   git commit -m "Add new Lambda function"
   ```

3. **Push to develop branch:**
   ```bash
   git push origin develop
   ```
   - ✅ Automatically triggers dev deployment
   - ✅ Optional approval (can be skipped for testing)

#### **For QA Testing**

1. **Merge to main:**
   ```bash
   git checkout main
   git merge feature/new-lambda-function
   git push origin main
   ```
   - ✅ Automatically triggers QA deployment
   - ✅ Requires manual approval from `mohammadn0man`

#### **For Production Deployment**

1. **Commit with special message:**
   ```bash
   git commit -m "Deploy new features to production [deploy-prod]"
   git push origin main
   ```
   - ✅ Only triggers if `[deploy-prod]` is in commit message
   - ✅ Requires manual approval from `mohammadn0man`
   - ✅ Extra safety for production environment

### Manual Workflow Dispatch

You can manually trigger deployments using GitHub's workflow dispatch:

1. **Go to Actions tab** in GitHub repository
2. **Select the workflow** (e.g., "Deploy to Dev Environment")
3. **Click "Run workflow"**
4. **Choose options**:
   - **Skip approval**: For testing (dev only)
   - **Force deploy**: Even if no changes detected
5. **Click "Run workflow"**

### Required GitHub Secrets

The workflows require these secrets to be configured in your GitHub repository:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | ✅ |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | ✅ |
| `GITHUB_TOKEN` | GitHub token (auto-provided) | ✅ |

### Required GitHub Variables

| Variable Name | Description | Required |
|---------------|-------------|----------|
| `AWS_REGION` | AWS region for deployment | ✅ |

### Workflow File Structure

```
.github/workflows/
├── terraform.yml              # Main validation and planning
├── terraform-deploy.yml       # Reusable deployment workflow
├── terraform-plan.yml         # Reusable planning workflow
├── terraform-validate.yml     # Reusable validation workflow
├── deploy-dev.yml             # Dev environment deployment
├── deploy-qa.yml              # QA environment deployment
└── deploy-prod.yml            # Production environment deployment
```

### Workflow Features

#### **Reusable Workflows**
- **`terraform-validate.yml`**: Validates Terraform configurations
- **`terraform-plan.yml`**: Generates Terraform plans
- **`terraform-deploy.yml`**: Applies Terraform changes

#### **Safety Features**
- ✅ **Path-based triggers**: Only runs when relevant files change
- ✅ **Manual approval gates**: Prevents accidental deployments
- ✅ **Environment isolation**: Separate workflows for each environment
- ✅ **Plan review**: Plans are posted as PR comments
- ✅ **Validation**: All changes are validated before deployment

#### **Monitoring and Logging**
- ✅ **Detailed logs**: Full Terraform output in GitHub Actions
- ✅ **Plan artifacts**: Plans are saved as artifacts
- ✅ **Status checks**: Integration with GitHub status checks
- ✅ **Notifications**: Automatic notifications on deployment status

### Troubleshooting CI/CD Issues

#### **Common Issues**

1. **Workflow not triggering:**
   - Check if files changed in monitored paths
   - Verify branch name matches trigger conditions
   - Ensure commit message contains `[deploy-prod]` for production

2. **Approval not working:**
   - Verify `mohammadn0man` is in approvers list
   - Check GitHub token permissions
   - Ensure approval step is not skipped

3. **AWS credentials error:**
   - Verify secrets are properly configured
   - Check AWS credentials have required permissions
   - Ensure AWS region variable is set

#### **Debugging Steps**

1. **Check workflow logs:**
   - Go to Actions tab in GitHub
   - Click on the failed workflow
   - Review step-by-step logs

2. **Verify secrets:**
   - Go to Settings → Secrets and variables → Actions
   - Ensure all required secrets are configured

3. **Test locally:**
   - Run the same commands locally to verify
   - Check AWS credentials and permissions

### Best Practices

1. **Always test in dev first**: Use dev environment for initial testing
2. **Review plans**: Always review Terraform plans before approval
3. **Use descriptive commit messages**: Include `[deploy-prod]` for production
4. **Monitor deployments**: Watch workflow runs for any issues
5. **Keep secrets secure**: Rotate AWS credentials regularly

## 🛠️ Development Workflow

### Using Build Scripts

The repository provides cross-platform build scripts for managing the infrastructure:

#### Linux/macOS:
```bash
# Build Lambda layers
./scripts/build.sh build-layers

# Validate Terraform configuration
./scripts/build.sh validate

# Plan changes for dev environment
./scripts/build.sh plan dev

# Deploy to dev environment
./scripts/build.sh deploy dev

# Clean build artifacts
./scripts/build.sh clean
```

#### Windows:
```powershell
# Build Lambda layers
.\scripts\build.ps1 build-layers

# Validate Terraform configuration
.\scripts\build.ps1 validate

# Plan changes for dev environment
.\scripts\build.ps1 plan dev

# Deploy to dev environment
.\scripts\build.ps1 deploy dev

# Clean build artifacts
.\scripts\build.ps1 clean
```

### Using Workspace Scripts

For direct Terraform operations:

#### Linux/macOS:
```bash
cd terraform

# Initialize workspace for dev environment
./workspace.sh init dev

# Plan changes
./workspace.sh plan dev

# Apply changes
./workspace.sh apply dev

# List workspaces
./workspace.sh list

# Show current workspace
./workspace.sh show
```

#### Windows:
```powershell
cd terraform

# Initialize workspace for dev environment
.\workspace.ps1 init dev

# Plan changes
.\workspace.ps1 plan dev

# Apply changes
.\workspace.ps1 apply dev

# List workspaces
.\workspace.ps1 list

# Show current workspace
.\workspace.ps1 show
```

## 🏗️ Adding New Lambda Functions

### 1. Create Function Directory

```bash
mkdir lambda_functions/my_new_function
cd lambda_functions/my_new_function
```

### 2. Create Function Code

```javascript
// index.js
const { successResponse, errorResponse } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
    try {
        // Your function logic here
        const data = {
            message: 'Function executed successfully!',
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data);
        
    } catch (error) {
        console.error('Error in function:', error);
        return errorResponse(error, 500);
    }
};
```

### 3. Create Package Configuration

```json
// package.json
{
  "name": "my-new-function",
  "version": "1.0.0",
  "description": "My new Lambda function",
  "main": "index.js",
  "dependencies": {}
}
```

### 4. Add Terraform Configuration

Create a new module or add to existing configuration:

```hcl
# terraform/modules/lambda/main.tf
module "my_new_function" {
  source = "../../modules/lambda"
  
  function_name = "my-new-function"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  
  source_dir = "${path.module}/../../lambda_functions/my_new_function"
  
  layers = [
    module.dependencies_layer.layer_arn,
    module.utility_layer.layer_arn
  ]
  
  tags = var.common_tags
}
```

### 5. Update API Gateway (if needed)

```hcl
# terraform/modules/api_gateway/main.tf
resource "aws_api_gateway_resource" "my_resource" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "my-endpoint"
}

resource "aws_api_gateway_method" "my_method" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.my_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "my_integration" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.my_resource.id
  http_method = aws_api_gateway_method.my_method.http_method
  
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = module.my_new_function.invoke_arn
}
```

## 📦 Lambda Layers

### Dependencies Layer

Common Node.js dependencies shared across functions:

```json
{
  "dependencies": {
    "aws-sdk": "^2.1000.0",
    "lodash": "^4.17.21",
    "joi": "^17.6.0",
    "bcrypt": "^5.0.1"
  }
}
```

### Utility Layer

Shared utility functions:

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

## 🌍 Environment Management

### Environment Variables

Each environment has its own configuration:

- **Dev**: `terraform.dev.tfvars`
- **QA**: `terraform.qa.tfvars`
- **Production**: `terraform.prod.tfvars`

### Workspace Management

```bash
# Switch between environments
cd terraform
./workspace.sh list
./workspace.sh show
./workspace.sh plan dev
./workspace.sh plan qa
./workspace.sh plan prod
```

## 🔧 Troubleshooting

### Common Issues

1. **Terraform initialization errors:**
   ```bash
   cd terraform
   terraform init
   ```

2. **Provider cache issues:**
   ```bash
   rm -rf .terraform
   terraform init
   ```

3. **Workspace conflicts:**
   ```bash
   terraform workspace list
   terraform workspace select <environment>
   ```

### Validation Commands

```bash
# Fast validation (main only)
./scripts/build.sh validate

# Complete validation (backend + main)
./scripts/build.sh validate-all
```

## 📚 Documentation

- **API Specification**: `docs/api_spec.yaml` - OpenAPI 3.0 specification
- **Terraform Documentation**: `terraform/README.md`
- **Backend Setup**: `terraform/backend-setup/README.md`

## 🤝 Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Test with `./scripts/build.sh validate`
4. Create a pull request
5. Wait for CI validation and approval

## 📞 Support

For questions or issues:
- Create an issue in the repository
- Contact the infrastructure team
- Check the documentation in `docs/` directory

---

**Note**: Always test changes in the dev environment before deploying to production. The CI/CD pipeline includes approval gates to ensure safe deployments. 
