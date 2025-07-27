#!/bin/bash

# Terraform Workspace Management Script for Main Infrastructure
# This script helps manage Terraform workspaces for different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Valid environments
VALID_ENVIRONMENTS=("dev" "qa" "prod")

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
    echo "Usage: $0 <command> [environment]"
    echo ""
    echo "Commands:"
    echo "  init <env>     - Initialize and select workspace for environment (dev|qa|prod)"
    echo "  plan <env>     - Plan changes for environment"
    echo "  apply <env>    - Apply changes for environment"
    echo "  destroy <env>  - Destroy resources for environment"
    echo "  validate       - Run terraform validate"
    echo "  list           - List all workspaces"
    echo "  show           - Show current workspace"
    echo "  help           - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init dev"
    echo "  $0 plan qa"
    echo "  $0 apply prod"
    echo "  $0 validate"
    echo "  $0 list"
    echo ""
    echo "Note: Make sure the backend infrastructure is set up first using the backend-setup workspace!"
}

# Function to validate environment
validate_environment() {
    local env=$1
    for valid_env in "${VALID_ENVIRONMENTS[@]}"; do
        if [[ "$env" == "$valid_env" ]]; then
            return 0
        fi
    done
    print_error "Invalid environment: $env"
    print_error "Valid environments: ${VALID_ENVIRONMENTS[*]}"
    exit 1
}

# Function to check if Terraform is initialized
check_terraform_init() {
    if [[ ! -d ".terraform" ]]; then
        print_error "Terraform not initialized. Run 'terraform init' first."
        exit 1
    fi
}

# Function to check if backend is set up
check_backend_setup() {
    print_warning "Make sure you have set up the backend infrastructure first!"
    print_warning "Run the backend-setup workspace before using this main infrastructure."
    print_warning "Example: cd ../backend-setup && ./workspace.sh apply dev"
}

# Function to initialize and select workspace
init_workspace() {
    local env=$1
    print_header "Initializing workspace for $env environment"
    
    check_backend_setup
    
    # Initialize Terraform if not already done
    if [[ ! -d ".terraform" ]]; then
        print_status "Initializing Terraform..."
        terraform init
    fi
    
    # Create workspace if it doesn't exist
    if ! terraform workspace list | grep -q "$env"; then
        print_status "Creating workspace: $env"
        terraform workspace new "$env"
    else
        print_status "Workspace $env already exists"
    fi
    
    # Select the workspace
    print_status "Selecting workspace: $env"
    terraform workspace select "$env"
    
    print_status "Workspace $env is ready!"
    print_status "You can now run: $0 plan $env"
}

# Function to plan changes
plan_changes() {
    local env=$1
    print_header "Planning changes for $env environment"
    
    check_terraform_init
    
    # Ensure we're in the correct workspace
    local current_workspace=$(terraform workspace show)
    if [[ "$current_workspace" != "$env" ]]; then
        print_warning "Current workspace is $current_workspace, switching to $env"
        terraform workspace select "$env"
    fi
    
    print_status "Running terraform plan..."
    terraform plan
}

# Function to apply changes
apply_changes() {
    local env=$1
    print_header "Applying changes for $env environment"
    
    check_terraform_init
    
    # Ensure we're in the correct workspace
    local current_workspace=$(terraform workspace show)
    if [[ "$current_workspace" != "$env" ]]; then
        print_warning "Current workspace is $current_workspace, switching to $env"
        terraform workspace select "$env"
    fi
    
    print_warning "This will apply changes to the $env environment!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Running terraform apply..."
        terraform apply
    else
        print_status "Operation cancelled."
    fi
}

# Function to destroy resources
destroy_resources() {
    local env=$1
    print_header "Destroying resources for $env environment"
    
    check_terraform_init
    
    # Ensure we're in the correct workspace
    local current_workspace=$(terraform workspace show)
    if [[ "$current_workspace" != "$env" ]]; then
        print_warning "Current workspace is $current_workspace, switching to $env"
        terraform workspace select "$env"
    fi
    
    print_error "This will DESTROY ALL RESOURCES in the $env environment!"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
    if [[ "$REPLY" == "yes" ]]; then
        print_status "Running terraform destroy..."
        terraform destroy
    else
        print_status "Operation cancelled."
    fi
}

# Function to validate the configuration
validate_config() {
    print_header "Validating Terraform configuration"
    terraform validate
}

# Function to list workspaces
list_workspaces() {
    print_header "Terraform Workspaces"
    terraform workspace list
}

# Function to show current workspace
show_current_workspace() {
    print_header "Current Workspace"
    local current_workspace=$(terraform workspace show)
    print_status "Current workspace: $current_workspace"
}

# Main script logic
main() {
    local command=$1
    local environment=$2
    
    case $command in
        "init")
            if [[ -z "$environment" ]]; then
                print_error "Environment is required for init command"
                show_usage
                exit 1
            fi
            validate_environment "$environment"
            init_workspace "$environment"
            ;;
        "plan")
            if [[ -z "$environment" ]]; then
                print_error "Environment is required for plan command"
                show_usage
                exit 1
            fi
            validate_environment "$environment"
            plan_changes "$environment"
            ;;
        "apply")
            if [[ -z "$environment" ]]; then
                print_error "Environment is required for apply command"
                show_usage
                exit 1
            fi
            validate_environment "$environment"
            apply_changes "$environment"
            ;;
        "destroy")
            if [[ -z "$environment" ]]; then
                print_error "Environment is required for destroy command"
                show_usage
                exit 1
            fi
            validate_environment "$environment"
            destroy_resources "$environment"
            ;;
        "validate")
            validate_config
            ;;
        "list")
            list_workspaces
            ;;
        "show")
            show_current_workspace
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