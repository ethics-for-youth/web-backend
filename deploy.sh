#!/bin/bash

# EFY Backend Deployment Script
# Usage: ./deploy.sh [command] [environment]
# Commands: validate, plan, apply, destroy, clean
# Environments: dev, qa, prod

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    echo "EFY Backend Deployment Script"
    echo ""
    echo "Usage: $0 [command] [environment]"
    echo ""
    echo "Commands:"
    echo "  validate       Validate Terraform configuration"
    echo "  plan          Create deployment plan"
    echo "  apply         Apply infrastructure changes"
    echo "  destroy       Destroy infrastructure (use with caution)"
    echo "  clean         Clean temporary files"
    echo "  help          Show this help message"
    echo ""
    echo "Environments:"
    echo "  dev           Development environment"
    echo "  qa            Quality assurance environment"
    echo "  prod          Production environment"
    echo ""
    echo "Examples:"
    echo "  $0 validate"
    echo "  $0 plan dev"
    echo "  $0 apply dev"
    echo "  $0 destroy dev"
    echo ""
}

# Validate prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please configure AWS CLI first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Install dependencies for Lambda layers
install_dependencies() {
    print_info "Installing Lambda layer dependencies..."
    
    if [ -d "layers/dependencies/nodejs" ]; then
        cd layers/dependencies/nodejs
        if [ -f "package.json" ]; then
            npm install --production
            print_success "Dependencies layer installed"
        fi
        cd - > /dev/null
    fi
    
    if [ -d "layers/utility/nodejs" ]; then
        cd layers/utility/nodejs
        if [ -f "package.json" ]; then
            npm install --production
            print_success "Utility layer installed"
        fi
        cd - > /dev/null
    fi
}

# Validate Terraform configuration
validate_terraform() {
    print_info "Validating Terraform configuration..."
    
    cd terraform
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    print_info "Validating configuration..."
    terraform validate
    
    print_success "Terraform validation passed"
    cd - > /dev/null
}

# Create Terraform plan
plan_terraform() {
    local environment=$1
    
    if [ -z "$environment" ]; then
        print_error "Environment is required for plan command"
        echo "Usage: $0 plan [dev|qa|prod]"
        exit 1
    fi
    
    print_info "Creating Terraform plan for $environment environment..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Select or create workspace
    print_info "Setting up workspace for $environment..."
    terraform workspace select $environment || terraform workspace new $environment
    
    # Create plan
    print_info "Creating deployment plan..."
    terraform plan -out="terraform-$environment.tfplan"
    
    print_success "Plan created successfully: terraform-$environment.tfplan"
    cd - > /dev/null
}

# Apply Terraform changes
apply_terraform() {
    local environment=$1
    
    if [ -z "$environment" ]; then
        print_error "Environment is required for apply command"
        echo "Usage: $0 apply [dev|qa|prod]"
        exit 1
    fi
    
    # Confirmation for production
    if [ "$environment" = "prod" ]; then
        print_warning "You are about to deploy to PRODUCTION environment!"
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    print_info "Applying Terraform changes for $environment environment..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Select workspace
    terraform workspace select $environment
    
    # Apply changes
    if [ -f "terraform-$environment.tfplan" ]; then
        print_info "Applying from existing plan..."
        terraform apply "terraform-$environment.tfplan"
    else
        print_info "Creating and applying new plan..."
        terraform apply
    fi
    
    # Show outputs
    print_info "Deployment outputs:"
    terraform output
    
    print_success "Deployment completed successfully!"
    cd - > /dev/null
}

# Destroy infrastructure
destroy_terraform() {
    local environment=$1
    
    if [ -z "$environment" ]; then
        print_error "Environment is required for destroy command"
        echo "Usage: $0 destroy [dev|qa|prod]"
        exit 1
    fi
    
    print_warning "You are about to DESTROY the $environment environment!"
    print_warning "This action is IRREVERSIBLE and will delete all resources!"
    read -p "Type 'destroy-$environment' to confirm: " confirm
    
    if [ "$confirm" != "destroy-$environment" ]; then
        print_info "Destroy operation cancelled"
        exit 0
    fi
    
    print_info "Destroying infrastructure for $environment environment..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Select workspace
    terraform workspace select $environment
    
    # Destroy infrastructure
    terraform destroy
    
    print_success "Infrastructure destroyed successfully!"
    cd - > /dev/null
}

# Clean temporary files
clean_files() {
    print_info "Cleaning temporary files..."
    
    # Clean Terraform files
    find . -name "*.tfplan" -delete
    find . -name ".terraform.lock.hcl" -delete
    rm -rf terraform/.terraform/
    rm -rf terraform/builds/
    
    # Clean node_modules
    find . -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Clean Lambda function node_modules
    find lambda_functions -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    
    print_success "Cleanup completed"
}

# Get API Gateway URL
get_api_url() {
    local environment=$1
    
    if [ -z "$environment" ]; then
        print_error "Environment is required"
        echo "Usage: $0 url [dev|qa|prod]"
        exit 1
    fi
    
    cd terraform
    terraform workspace select $environment
    api_url=$(terraform output -raw efy_api_gateway_url 2>/dev/null || echo "Not deployed")
    print_info "API Gateway URL for $environment: $api_url"
    cd - > /dev/null
}

# Main execution
main() {
    local command=$1
    local environment=$2
    
    case $command in
        "validate")
            check_prerequisites
            install_dependencies
            validate_terraform
            ;;
        "plan")
            check_prerequisites
            install_dependencies
            plan_terraform $environment
            ;;
        "apply")
            check_prerequisites
            install_dependencies
            apply_terraform $environment
            ;;
        "destroy")
            check_prerequisites
            destroy_terraform $environment
            ;;
        "clean")
            clean_files
            ;;
        "url")
            get_api_url $environment
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"