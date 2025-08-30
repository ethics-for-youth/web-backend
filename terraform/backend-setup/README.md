# Terraform Backend Setup - Multi-Environment with Workspaces

This directory contains Terraform configuration for setting up the backend infrastructure (S3 bucket and DynamoDB table) for multiple environments using Terraform workspaces. This is a prerequisite for the main infrastructure deployment.

## Environments Supported

- **dev** - Development environment
- **qa** - Quality Assurance environment  
- **prod** - Production environment

## Files Structure

- `main.tf` - Main Terraform configuration with workspace support
- `variables.tf` - Variable definitions with environment validation
- `outputs.tf` - Output values (bucket names, table names)
- `terraform.tfvars` - Default configuration
- `workspace.sh` - Bash script for workspace management (Linux/Mac)
- `workspace.ps1` - PowerShell script for workspace management (Windows)
- `terraform.dev.tfvars` - Development environment specific values (legacy)
- `terraform.qa.tfvars` - QA environment specific values (legacy)
- `terraform.prod.tfvars` - Production environment specific values (legacy)

## Infrastructure Components

### S3 Bucket
- **Purpose**: Stores Terraform state files
- **Features**: 
  - Server-side encryption (AES256)
  - Versioning (optional, enabled by default)
  - Public access blocked
  - Environment-specific naming
- **Naming**: `efy-web-backend-{environment}-terraform-state-{account-id}`

### DynamoDB Table
- **Purpose**: Provides state locking to prevent concurrent modifications
- **Features**:
  - Pay-per-request billing
  - LockID as hash key
  - Environment-specific naming
- **Naming**: `efy-web-backend-{environment}-terraform-locks`

## Workspace Management

This setup uses Terraform workspaces to manage different environments. Each workspace corresponds to an environment and maintains its own state.

### Using the Workspace Management Scripts

#### Windows (PowerShell)
```powershell
# Navigate to the backend-setup directory
cd terraform/backend-setup

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
# Navigate to the backend-setup directory
cd terraform/backend-setup

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

### Current Environment Configurations

```hcl
environment_configs = {
  dev = {
    state_bucket_name   = "efy-web-backend-dev-terraform-state-123456"
    dynamodb_table_name = "efy-web-backend-dev-terraform-locks"
    tags = {
      Environment = "dev"
      CostCenter  = "development"
    }
  }
  qa = {
    state_bucket_name   = "efy-web-backend-qa-terraform-state-123456"
    dynamodb_table_name = "efy-web-backend-qa-terraform-locks"
    tags = {
      Environment = "qa"
      CostCenter  = "testing"
    }
  }
  prod = {
    state_bucket_name   = "efy-web-backend-prod-terraform-state-123456"
    dynamodb_table_name = "efy-web-backend-prod-terraform-locks"
    tags = {
      Environment = "prod"
      CostCenter  = "production"
    }
  }
}
```

## Workspace State Management

Each workspace maintains its own state file:
- `terraform.tfstate.d/dev/terraform.tfstate` - Dev environment state
- `terraform.tfstate.d/qa/terraform.tfstate` - QA environment state  
- `terraform.tfstate.d/prod/terraform.tfstate` - Production environment state

## Security Features

### S3 Bucket Security
- **Encryption**: Server-side encryption with AES256
- **Versioning**: Enabled by default (configurable)
- **Public Access**: Completely blocked
- **Access Control**: IAM-based access control only

### DynamoDB Table Security
- **Encryption**: Server-side encryption enabled
- **Access Control**: IAM-based access control
- **Billing**: Pay-per-request to minimize costs

### Resource Tagging
All resources are properly tagged for:
- **Cost Tracking**: CostCenter tags for each environment
- **Resource Management**: Environment and project identification
- **Compliance**: Proper resource categorization

## Important Notes

1. **Unique Bucket Names**: Make sure to change the `state_bucket_name` in the `environment_configs` variable to globally unique names. S3 bucket names must be unique across all AWS accounts.

2. **Workspace Validation**: The configuration includes validation to ensure only valid workspaces (dev, qa, prod) are used.

3. **Resource Naming**: Resources are automatically named with the workspace prefix for easy identification.

4. **Tags**: Each environment has specific tags including CostCenter for better resource management.

5. **Security**: All resources include proper security configurations:
   - S3 bucket versioning enabled
   - Server-side encryption enabled
   - Public access blocked
   - DynamoDB table for state locking

6. **State Isolation**: Each workspace has completely isolated state, preventing accidental cross-environment changes.

## Migration from Legacy tfvars Files

If you were previously using the environment-specific tfvars files, you can migrate to workspaces:

1. **Backup your current state**: `terraform state pull > backup.tfstate`
2. **Create workspaces**: Use the workspace management scripts
3. **Migrate state**: Copy relevant resources to the appropriate workspace state

## Customization

You can customize the configuration by modifying the `environment_configs` variable in `variables.tf`. Each environment can have different:
- Bucket names
- DynamoDB table names
- Tags
- Feature flags

### Configuration Options

```hcl
variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}
```

## Outputs

After applying the configuration, you'll get the S3 bucket name and DynamoDB table name that you can use in your main Terraform configuration's backend configuration:

```hcl
# Example outputs
output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}
```

## Troubleshooting

### Common Issues

1. **Invalid workspace**: Make sure you're using one of the valid workspaces (dev, qa, prod)
2. **Bucket name conflicts**: Ensure bucket names are globally unique
3. **Permission issues**: Make sure your AWS credentials have the necessary permissions

### Getting Help

```bash
# Show script help
.\workspace.ps1 help  # Windows
./workspace.sh help   # Linux/Mac

# Show current workspace
terraform workspace show

# List all workspaces
terraform workspace list
```

## Next Steps

After setting up the backend infrastructure:

1. **Update Main Configuration**: Update the backend configuration in `../backend.tf` with the actual bucket and table names
2. **Deploy Main Infrastructure**: Navigate to the main terraform directory and deploy the infrastructure
3. **Verify Setup**: Test the backend configuration with a simple terraform plan

## File Structure

```
terraform/backend-setup/
├── main.tf                 # Main backend infrastructure
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── workspace.ps1           # Workspace management (Windows)
├── workspace.sh            # Workspace management (Linux/Mac)
├── terraform.tfvars        # Default configuration
├── terraform.dev.tfvars    # Dev environment config (legacy)
├── terraform.qa.tfvars     # QA environment config (legacy)
├── terraform.prod.tfvars   # Prod environment config (legacy)
└── README.md              # This file
``` 