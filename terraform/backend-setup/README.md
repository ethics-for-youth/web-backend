# Terraform Backend Setup - Multi-Environment with Workspaces

This directory contains Terraform configuration for setting up the backend infrastructure (S3 bucket and DynamoDB table) for multiple environments using Terraform workspaces.

## Environments Supported

- **dev** - Development environment
- **qa** - Quality Assurance environment  
- **prod** - Production environment

## Files Structure

- `main.tf` - Main Terraform configuration with workspace support
- `variables.tf` - Variable definitions with environment validation
- `terraform.tfvars` - Default configuration
- `workspace.sh` - Bash script for workspace management (Linux/Mac)
- `workspace.ps1` - PowerShell script for workspace management (Windows)
- `terraform.dev.tfvars` - Development environment specific values (legacy)
- `terraform.qa.tfvars` - QA environment specific values (legacy)
- `terraform.prod.tfvars` - Production environment specific values (legacy)

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

## Workspace State Management

Each workspace maintains its own state file:
- `terraform.tfstate.d/dev/terraform.tfstate` - Dev environment state
- `terraform.tfstate.d/qa/terraform.tfstate` - QA environment state  
- `terraform.tfstate.d/prod/terraform.tfstate` - Production environment state

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

## Outputs

After applying the configuration, you'll get the S3 bucket name and DynamoDB table name that you can use in your main Terraform configuration's backend configuration.

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