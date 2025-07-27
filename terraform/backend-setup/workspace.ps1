# Terraform Workspace Management Script for Backend Setup
# This script helps manage Terraform workspaces for different environments

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$Environment
)

# Valid environments
$ValidEnvironments = @("dev", "qa", "prod")

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "=== $Message ===" -ForegroundColor Blue
}

# Function to show usage
function Show-Usage {
    Write-Host "Usage: .\workspace.ps1 <command> [environment]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  init <env>     - Initialize and select workspace for environment (dev|qa|prod)"
    Write-Host "  plan <env>     - Plan changes for environment"
    Write-Host "  apply <env>    - Apply changes for environment"
    Write-Host "  destroy <env>  - Destroy resources for environment"
    Write-Host "  list           - List all workspaces"
    Write-Host "  show           - Show current workspace"
    Write-Host "  help           - Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\workspace.ps1 init dev"
    Write-Host "  .\workspace.ps1 plan qa"
    Write-Host "  .\workspace.ps1 apply prod"
    Write-Host "  .\workspace.ps1 list"
}

# Function to validate environment
function Test-Environment {
    param([string]$Env)
    if ($ValidEnvironments -contains $Env) {
        return $true
    }
    Write-Error "Invalid environment: $Env"
    Write-Error "Valid environments: $($ValidEnvironments -join ', ')"
    return $false
}

# Function to check if Terraform is initialized
function Test-TerraformInit {
    if (-not (Test-Path ".terraform")) {
        Write-Error "Terraform not initialized. Run 'terraform init' first."
        exit 1
    }
}

# Function to initialize and select workspace
function Initialize-Workspace {
    param([string]$Env)
    Write-Header "Initializing workspace for $Env environment"
    
    # Initialize Terraform if not already done
    if (-not (Test-Path ".terraform")) {
        Write-Status "Initializing Terraform..."
        terraform init
    }
    
    # Create workspace if it doesn't exist
    $workspaces = terraform workspace list
    if ($workspaces -notmatch $Env) {
        Write-Status "Creating workspace: $Env"
        terraform workspace new $Env
    } else {
        Write-Status "Workspace $Env already exists"
    }
    
    # Select the workspace
    Write-Status "Selecting workspace: $Env"
    terraform workspace select $Env
    
    Write-Status "Workspace $Env is ready!"
}

# Function to plan changes
function Plan-Changes {
    param([string]$Env)
    Write-Header "Planning changes for $Env environment"
    
    Test-TerraformInit
    
    # Ensure we're in the correct workspace
    $currentWorkspace = terraform workspace show
    if ($currentWorkspace -ne $Env) {
        Write-Warning "Current workspace is $currentWorkspace, switching to $Env"
        terraform workspace select $Env
    }
    
    Write-Status "Running terraform plan..."
    terraform plan
}

# Function to apply changes
function Apply-Changes {
    param([string]$Env)
    Write-Header "Applying changes for $Env environment"
    
    Test-TerraformInit
    
    # Ensure we're in the correct workspace
    $currentWorkspace = terraform workspace show
    if ($currentWorkspace -ne $Env) {
        Write-Warning "Current workspace is $currentWorkspace, switching to $Env"
        terraform workspace select $Env
    }
    
    Write-Warning "This will apply changes to the $Env environment!"
    $confirmation = Read-Host "Are you sure you want to continue? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        Write-Status "Running terraform apply..."
        terraform apply
    } else {
        Write-Status "Operation cancelled."
    }
}

# Function to destroy resources
function Destroy-Resources {
    param([string]$Env)
    Write-Header "Destroying resources for $Env environment"
    
    Test-TerraformInit
    
    # Ensure we're in the correct workspace
    $currentWorkspace = terraform workspace show
    if ($currentWorkspace -ne $Env) {
        Write-Warning "Current workspace is $currentWorkspace, switching to $Env"
        terraform workspace select $Env
    }
    
    Write-Error "This will DESTROY ALL RESOURCES in the $Env environment!"
    $confirmation = Read-Host "Are you absolutely sure? Type 'yes' to confirm"
    if ($confirmation -eq 'yes') {
        Write-Status "Running terraform destroy..."
        terraform destroy
    } else {
        Write-Status "Operation cancelled."
    }
}

# Function to list workspaces
function List-Workspaces {
    Write-Header "Terraform Workspaces"
    terraform workspace list
}

# Function to show current workspace
function Show-CurrentWorkspace {
    Write-Header "Current Workspace"
    $currentWorkspace = terraform workspace show
    Write-Status "Current workspace: $currentWorkspace"
}

# Main script logic
function Main {
    param([string]$Command, [string]$Environment)
    
    switch ($Command) {
        "init" {
            if (-not $Environment) {
                Write-Error "Environment is required for init command"
                Show-Usage
                exit 1
            }
            if (Test-Environment $Environment) {
                Initialize-Workspace $Environment
            }
        }
        "plan" {
            if (-not $Environment) {
                Write-Error "Environment is required for plan command"
                Show-Usage
                exit 1
            }
            if (Test-Environment $Environment) {
                Plan-Changes $Environment
            }
        }
        "apply" {
            if (-not $Environment) {
                Write-Error "Environment is required for apply command"
                Show-Usage
                exit 1
            }
            if (Test-Environment $Environment) {
                Apply-Changes $Environment
            }
        }
        "destroy" {
            if (-not $Environment) {
                Write-Error "Environment is required for destroy command"
                Show-Usage
                exit 1
            }
            if (Test-Environment $Environment) {
                Destroy-Resources $Environment
            }
        }
        "list" {
            List-Workspaces
        }
        "show" {
            Show-CurrentWorkspace
        }
        "help" {
            Show-Usage
        }
        default {
            if (-not $Command) {
                Write-Error "No command specified"
            } else {
                Write-Error "Unknown command: $Command"
            }
            Show-Usage
            exit 1
        }
    }
}

# Run main function with all arguments
Main $Command $Environment 