#!/bin/bash

# Build Script for EFY Web Backend Infrastructure
# This script builds Lambda layers and prepares the infrastructure for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  clean           - Clean build artifacts"
    echo "  validate        - Validate Terraform configuration (main only)"
    echo "  validate-all    - Validate both backend and main Terraform configuration"
    echo "  plan <env>      - Plan Terraform changes for environment (dev|qa|prod)"
    echo "  apply <env> [plan-file] - Apply Terraform changes for environment (optionally with plan file)"
    echo "  destroy <env>   - Destroy resources for environment"
    echo "  deploy <env>    - Deploy to environment"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build-layers"
    echo "  $0 plan dev"
    echo "  $0 deploy dev"
    echo "  $0 clean"
}

# Function to check if required tools are installed
check_requirements() {
    print_header "Checking Requirements"
    
    # Check if zip is available
    if ! command -v zip &> /dev/null; then
        print_error "zip command not found. Please install zip."
        exit 1
    fi
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        print_error "terraform command not found. Please install Terraform."
        exit 1
    fi
    
    # Check if npm is available (required for layer dependencies)
    if ! command -v npm &> /dev/null; then
        print_error "npm command not found. Please install Node.js and npm."
        exit 1
    fi
    
    # Check if AWS CLI is available (optional but recommended)
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI not found. Some operations may fail."
    fi
    
    print_status "All requirements satisfied"
}



# Function to install Lambda layer dependencies
install_layer_dependencies() {
    print_header "Installing Lambda Layer Dependencies"
    
    # Install dependencies for dependencies layer
    if [ -d "layers/dependencies/nodejs" ]; then
        print_status "Installing dependencies layer..."
        cd layers/dependencies/nodejs
        if [ -f "package.json" ]; then
            npm install --production
            print_status "Dependencies layer installed successfully"
        fi
        cd - > /dev/null
    fi
    
    # Check utility layer (usually no dependencies)
    if [ -d "layers/utility/nodejs" ]; then
        cd layers/utility/nodejs
        if [ -f "package.json" ] && [ "$(cat package.json | grep -c '"dependencies".*{.*}')" -eq 0 ]; then
            print_status "Utility layer has no dependencies to install"
        elif [ -f "package.json" ]; then
            print_status "Installing utility layer..."
            npm install --production
            print_status "Utility layer installed successfully"
        fi
        cd - > /dev/null
    fi
    
    print_status "Layer dependencies installation completed"
}

# Function to clean build artifacts
clean_build() {
    print_header "Cleaning Build Artifacts"
    
    # Remove Terraform build artifacts
    if [ -d "terraform/builds" ]; then
        rm -rf terraform/builds
        print_status "Removed terraform/builds directory"
    fi
    
    # Remove .terraform directories
    find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    print_status "Removed .terraform directories"
    
    # Remove node_modules from layers (will be reinstalled when needed)
    if [ -d "layers/dependencies/nodejs/node_modules" ]; then
        rm -rf layers/dependencies/nodejs/node_modules
        print_status "Removed dependencies layer node_modules"
    fi
    
    if [ -d "layers/utility/nodejs/node_modules" ]; then
        rm -rf layers/utility/nodejs/node_modules
        print_status "Removed utility layer node_modules"
    fi
    
    print_status "Cleanup completed"
}

# Function to validate Terraform configuration
validate_terraform() {
    local validate_backend=${1:-false}
    
    print_header "Validating Terraform Configuration"
    
    cd terraform
    
    # Validate backend setup only if explicitly requested
    if [ "$validate_backend" = "true" ] && [ -d "../terraform/backend-setup" ]; then
        print_status "Validating backend setup..."
        cd ../terraform/backend-setup
        # Initialize if not already done
        if [[ ! -d ".terraform" ]]; then
            print_status "Initializing backend setup..."
            terraform init
        fi
        terraform validate
        cd ../../
    fi
    
    # Validate main configuration with local backend for CI
    print_status "Validating main configuration..."
    
    # Use local backend for validation if in CI environment or no AWS credentials
    if [[ -n "$CI" ]] || ! aws sts get-caller-identity &>/dev/null; then
        print_status "Using local backend for validation..."
        # Temporarily modify backend.tf to use local backend
        if [[ -f "backend.tf" ]]; then
            mv backend.tf backend.tf.bak
            # Create a temporary backend.tf with local backend
            cat > backend.tf << EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }

  # Local backend for validation
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF
            # Format the generated backend file
            terraform fmt backend.tf
        fi
    fi
    
    # Initialize if not already done or .terraform directory doesn't exist
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing main configuration..."
        terraform init -input=false
    fi
    
    # Check formatting first
    print_status "Checking terraform formatting..."
    terraform fmt -check -recursive . || {
        print_error "Terraform files are not properly formatted. Run 'terraform fmt -recursive .' to fix."
        exit 1
    }
    
    # Validate configuration
    print_status "Running terraform validate..."
    terraform validate
    
    # Restore original backend configuration if it was backed up
    if [[ -f "backend.tf.bak" ]]; then
        mv backend.tf.bak backend.tf
    fi
    
    cd ..
    print_status "Terraform validation completed successfully"
}

# Function to plan Terraform changes
plan_terraform() {
    local env=$1
    
    if [ -z "$env" ]; then
        print_error "Environment is required for plan command"
        show_usage
        exit 1
    fi
    
    print_header "Planning Terraform Changes for $env"
    
    cd terraform
    
    # Initialize if not already done
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing Terraform..."
        terraform init
    fi

    # Ensure workspace exists and select it
    print_status "Setting up workspace: $env"
    if ! terraform workspace list | grep -q "\s$env\s\|^$env$\|\*\s$env$"; then
        print_status "Creating new workspace: $env"
        terraform workspace new "$env"
    else
        print_status "Selecting existing workspace: $env"
        terraform workspace select "$env"
    fi
    
    print_status "Running terraform plan..."
    terraform plan -out=terraform-plan-$env.tfplan -detailed-exitcode
    print_status "Plan saved to terraform/terraform-plan-$env.tfplan"
    
    cd ..
}

# Function to apply Terraform changes
apply_terraform() {
    local env=$1
    local plan_file=$2
    
    if [ -z "$env" ]; then
        print_error "Environment is required for apply command"
        show_usage
        exit 1
    fi
    
    print_header "Applying Terraform Changes for $env"
    
    cd terraform
    
    # Initialize if not already done
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing Terraform..."
        terraform init
    fi

    # Ensure workspace exists and select it
    print_status "Setting up workspace: $env"
    if ! terraform workspace list | grep -q "\s$env\s\|^$env$\|\*\s$env$"; then
        print_status "Creating new workspace: $env"
        terraform workspace new "$env"
    else
        print_status "Selecting existing workspace: $env"
        terraform workspace select "$env"
    fi
    
    # Check if plan file exists
    if [ -n "$plan_file" ]; then
        # Handle absolute and relative paths
        if [ -f "$plan_file" ]; then
            print_status "Applying saved plan from $plan_file"
            terraform apply "$plan_file"
        elif [ -f "../$plan_file" ]; then
            print_status "Applying saved plan from ../$plan_file"
            terraform apply "../$plan_file"
        elif [ -f "terraform-plan-$env.tfplan" ]; then
            print_status "Applying saved plan from terraform-plan-$env.tfplan"
            terraform apply "terraform-plan-$env.tfplan"
        else
            print_error "Plan file specified but not found: $plan_file"
            print_status "Available files in current directory:"
            ls -la
            print_status "Falling back to auto-approve"
            terraform apply -auto-approve
        fi
    elif [ -f "terraform-plan-$env.tfplan" ]; then
        print_status "Applying saved plan from terraform-plan-$env.tfplan"
        terraform apply "terraform-plan-$env.tfplan"
    else
        print_status "No saved plan found, applying with auto-approve"
        terraform apply -auto-approve
    fi
    
    cd ..
}

# Function to destroy Terraform resources
destroy_terraform() {
    local env=$1
    
    if [ -z "$env" ]; then
        print_error "Environment is required for destroy command"
        show_usage
        exit 1
    fi
    
    print_header "Destroying Terraform Resources for $env"
    
    cd terraform
    
    # Initialize if not already done
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing Terraform..."
        terraform init
    fi
    
    # Use workspace script if available
    if [ -f "workspace.sh" ]; then
        chmod +x workspace.sh
        ./workspace.sh destroy "$env"
    else
        # Manual workspace management
        terraform workspace select "$env" || terraform workspace new "$env"
        terraform destroy -auto-approve
    fi
    
    cd ..
}

# Function to deploy to environment
deploy_to_environment() {
    local env=$1
    
    if [ -z "$env" ]; then
        print_error "Environment is required for deploy command"
        show_usage
        exit 1
    fi
    
    print_header "Deploying to $env Environment"
    
    # Validate configuration
    validate_terraform
    
    # Apply changes
    apply_terraform "$env"
    
    print_status "Deployment to $env completed successfully"
}

# Main script logic
main() {
    local command=$1
    local environment=$2
    
    # Check requirements first
    check_requirements
    
    case $command in
        "clean")
            clean_build
            ;;
        "validate")
            install_layer_dependencies
            validate_terraform false
            ;;
        "validate-all")
            install_layer_dependencies
            validate_terraform true
            ;;
        "plan")
            install_layer_dependencies
            plan_terraform "$environment"
            ;;
        "apply")
            install_layer_dependencies
            apply_terraform "$environment" "$3"
            ;;
        "destroy")
            destroy_terraform "$environment"
            ;;
        "deploy")
            install_layer_dependencies
            deploy_to_environment "$environment"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        "")
            print_error "No command specified"
            show_usage
            exit 1
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
