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
    echo "  build-layers    - Build Lambda layers (dependencies and utility)"
    echo "  clean           - Clean build artifacts"
    echo "  validate        - Validate Terraform configuration (main only)"
    echo "  validate-all    - Validate both backend and main Terraform configuration"
    echo "  plan <env>      - Plan Terraform changes for environment (dev|qa|prod)"
    echo "  apply <env>     - Apply Terraform changes for environment"
    echo "  destroy <env>   - Destroy resources for environment"
    echo "  deploy <env>    - Build layers and deploy to environment"
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
    
    # Check if AWS CLI is available (optional but recommended)
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI not found. Some operations may fail."
    fi
    
    print_status "All requirements satisfied"
}

# Function to build Lambda layers
build_layers() {
    print_header "Building Lambda Layers"
    
    # Create layers directory if it doesn't exist
    mkdir -p layers
    
    # Build dependencies layer
    print_status "Building dependencies layer..."
    if [ -d "layers/dependencies/nodejs" ]; then
        cd layers/dependencies/nodejs
        zip -r ../../../dependencies.zip . -q
        cd ../../../
        print_status "Dependencies layer built: layers/dependencies.zip"
    else
        print_warning "Dependencies layer directory not found. Creating empty layer..."
        mkdir -p layers/dependencies/nodejs
        echo '{"name": "dependencies-layer"}' > layers/dependencies/nodejs/package.json
        cd layers/dependencies/nodejs
        zip -r ../../../dependencies.zip . -q
        cd ../../../
        print_status "Empty dependencies layer created: layers/dependencies.zip"
    fi
    
    # Build utility layer
    print_status "Building utility layer..."
    if [ -d "layers/utility/nodejs" ]; then
        cd layers/utility/nodejs
        zip -r ../../../utility.zip . -q
        cd ../../../
        print_status "Utility layer built: layers/utility.zip"
    else
        print_warning "Utility layer directory not found. Creating empty layer..."
        mkdir -p layers/utility/nodejs
        echo '{"name": "utility-layer"}' > layers/utility/nodejs/package.json
        cd layers/utility/nodejs
        zip -r ../../../utility.zip . -q
        cd ../../../
        print_status "Empty utility layer created: layers/utility.zip"
    fi
    
    print_status "All Lambda layers built successfully"
}

# Function to clean build artifacts
clean_build() {
    print_header "Cleaning Build Artifacts"
    
    # Remove layer zip files
    if [ -f "layers/dependencies.zip" ]; then
        rm layers/dependencies.zip
        print_status "Removed layers/dependencies.zip"
    fi
    
    if [ -f "layers/utility.zip" ]; then
        rm layers/utility.zip
        print_status "Removed layers/utility.zip"
    fi
    
    # Remove Terraform build artifacts
    if [ -d "terraform/builds" ]; then
        rm -rf terraform/builds
        print_status "Removed terraform/builds directory"
    fi
    
    # Remove .terraform directories
    find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    print_status "Removed .terraform directories"
    
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
    
    # Validate main configuration
    print_status "Validating main configuration..."
    # Initialize if not already done
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing main configuration..."
        terraform init
    fi
    terraform validate
    
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
    
    # Use workspace script if available
    if [ -f "workspace.sh" ]; then
        chmod +x workspace.sh
        ./workspace.sh plan "$env"
    else
        # Manual workspace management
        terraform workspace select "$env" || terraform workspace new "$env"
        terraform plan
    fi
    
    cd ..
}

# Function to apply Terraform changes
apply_terraform() {
    local env=$1
    
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
    
    # Use workspace script if available
    if [ -f "workspace.sh" ]; then
        chmod +x workspace.sh
        ./workspace.sh apply "$env"
    else
        # Manual workspace management
        terraform workspace select "$env" || terraform workspace new "$env"
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
    
    # Build layers first
    build_layers
    
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
        "build-layers")
            build_layers
            ;;
        "clean")
            clean_build
            ;;
        "validate")
            validate_terraform false
            ;;
        "validate-all")
            validate_terraform true
            ;;
        "plan")
            plan_terraform "$environment"
            ;;
        "apply")
            apply_terraform "$environment"
            ;;
        "destroy")
            destroy_terraform "$environment"
            ;;
        "deploy")
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
