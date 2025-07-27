# Web Backend Infrastructure

This repository contains the infrastructure code for the EFY Web Backend, including AWS Lambda functions, API Gateway, and supporting resources managed with Terraform.

## 📁 Repository Structure

```
web-backend/
├── .github/workflows/           # GitHub Actions CI/CD workflows
│   ├── terraform.yml           # Main validation and planning workflow
│   ├── terraform-deploy.yml    # Reusable deployment workflow
│   ├── deploy-dev.yml          # Dev environment deployment
│   ├── deploy-qa.yml           # QA environment deployment
│   └── deploy-prod.yml         # Production environment deployment
├── docs/                       # Documentation
│   └── api_spec.yaml          # API specification
├── lambda_functions/           # AWS Lambda function code
│   ├── get_xyz/               # Example Lambda function
│   │   ├── index.js           # Function code
│   │   └── package.json       # Dependencies
│   └── post_xyz/              # Another example function
│       ├── index.js
│       └── package.json
├── layers/                     # Lambda layers (shared code)
│   ├── dependencies/           # Common dependencies layer
│   │   └── nodejs/
│   │       └── package.json
│   └── utility/               # Utility functions layer
│       └── nodejs/
│           ├── package.json
│           └── utils.js
├── scripts/                    # Build and deployment scripts
│   ├── build.sh               # Bash build script (Linux/macOS)
│   └── build.ps1              # PowerShell build script (Windows)
├── terraform/                  # Infrastructure as Code
│   ├── backend-setup/         # Backend infrastructure (S3, DynamoDB)
│   │   ├── workspace.sh       # Backend workspace management (Bash)
│   │   ├── workspace.ps1      # Backend workspace management (PowerShell)
│   │   └── main.tf           # Backend resources
│   ├── modules/               # Reusable Terraform modules
│   │   ├── api_gateway/      # API Gateway module
│   │   ├── lambda/           # Lambda function module
│   │   └── lambda_layer/     # Lambda layer module
│   ├── workspace.sh          # Main workspace management (Bash)
│   ├── workspace.ps1         # Main workspace management (PowerShell)
│   ├── main.tf               # Main infrastructure
│   ├── variables.tf          # Input variables
│   └── outputs.tf            # Output values
└── README.md                 # This file
```

## 🚀 Quick Start

### Prerequisites

- **Terraform** (v1.5.0 or higher)
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

## 🔄 CI/CD Pipeline

The repository uses GitHub Actions for automated deployment with manual approval gates.

### Pipeline Overview

1. **Validation & Planning** (`terraform.yml`)
   - Runs on pull requests
   - Validates Terraform configuration
   - Plans changes for each environment
   - Comments on PR with plan results

2. **Environment-Specific Deployments**
   - **Dev**: `deploy-dev.yml` - Deploys on push to `develop` branch
   - **QA**: `deploy-qa.yml` - Deploys on push to `main` branch
   - **Production**: `deploy-prod.yml` - Deploys on push to `main` with `[deploy-prod]` in commit message

### Approval Process

All deployments require manual approval from `mohammadn0man`:
- Dev deployments: Automatic approval gate
- QA deployments: Manual approval required
- Production deployments: Manual approval required

### Triggering Deployments

```bash
# Deploy to dev (automatic on develop branch)
git push origin develop

# Deploy to qa (requires approval)
git push origin main

# Deploy to production (requires approval + special commit message)
git commit -m "Update infrastructure [deploy-prod]"
git push origin main
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
const { someUtil } = require('/opt/utility/utils');

exports.handler = async (event) => {
    try {
        // Your function logic here
        const result = someUtil(event);
        
        return {
            statusCode: 200,
            body: JSON.stringify(result)
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
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
  "dependencies": {
    "aws-sdk": "^2.1000.0"
  }
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
  
  source_path = "${path.module}/../../lambda_functions/my_new_function"
  
  environment_variables = {
    ENVIRONMENT = var.environment
  }
  
  tags = var.common_tags
}
```

### 5. Update API Gateway (if needed)

```hcl
# terraform/modules/api_gateway/main.tf
resource "aws_api_gateway_resource" "my_resource" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "my-endpoint"
}

resource "aws_api_gateway_method" "my_method" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.my_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "my_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
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

```bash
# Add a dependency to the layer
cd layers/dependencies/nodejs
npm install aws-sdk
```

### Utility Layer

Shared utility functions:

```javascript
// layers/utility/nodejs/utils.js
exports.someUtil = (data) => {
    // Shared utility logic
    return processedData;
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

- **API Specification**: `docs/api_spec.yaml`
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
