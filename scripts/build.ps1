# Build Script for EFY Web Backend Infrastructure (PowerShell)
# This script builds Lambda layers and prepares the infrastructure for deployment

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$Environment
)

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
    Write-Host "Usage: .\build.ps1 <command> [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  clean           - Clean build artifacts"
    Write-Host "  validate        - Validate Terraform configuration (main only)"
    Write-Host "  validate-all    - Validate both backend and main Terraform configuration"
    Write-Host "  plan <env>      - Plan Terraform changes for environment (dev|qa|prod)"
    Write-Host "  apply <env> [plan-file] - Apply Terraform changes for environment (optionally with plan file)"
    Write-Host "  destroy <env>   - Destroy resources for environment"
    Write-Host "  deploy <env>    - Deploy to environment"
    Write-Host "  help            - Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build.ps1 build-layers"
    Write-Host "  .\build.ps1 plan dev"
    Write-Host "  .\build.ps1 deploy dev"
    Write-Host "  .\build.ps1 clean"
}

# Function to check if required tools are installed
function Test-Requirements {
    Write-Header "Checking Requirements"
    
    # Check if Compress-Archive is available (PowerShell 5.0+)
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.0 or higher is required."
        exit 1
    }
    
    # Check if terraform is available
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "terraform command not found. Please install Terraform."
        exit 1
    }
    
    # Check if AWS CLI is available (optional but recommended)
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Warning "AWS CLI not found. Some operations may fail."
    }
    
    Write-Status "All requirements satisfied"
}

# Function to build Lambda layers


# Function to clean build artifacts
function Clear-Build {
    Write-Header "Cleaning Build Artifacts"
    
    # Remove Terraform build artifacts
    if (Test-Path "terraform/builds") {
        Remove-Item "terraform/builds" -Recurse -Force
        Write-Status "Removed terraform/builds directory"
    }
    
    # Remove .terraform directories
    Get-ChildItem -Path "." -Name ".terraform" -Directory -Recurse | ForEach-Object {
        Remove-Item $_ -Recurse -Force
    }
    Write-Status "Removed .terraform directories"
    
    Write-Status "Cleanup completed"
}

# Function to validate Terraform configuration
function Test-TerraformConfig {
    param([bool]$ValidateBackend = $false)
    
    Write-Header "Validating Terraform Configuration"
    
    Set-Location "terraform"
    
    # Validate backend setup only if explicitly requested
    if ($ValidateBackend -and (Test-Path "../terraform/backend-setup")) {
        Write-Status "Validating backend setup..."
        Set-Location "../terraform/backend-setup"
        # Initialize if not already done
        if (-not (Test-Path ".terraform")) {
            Write-Status "Initializing backend setup..."
            terraform init
        }
        terraform validate
        Set-Location "../.."
    }
    
    # Validate main configuration
    Write-Status "Validating main configuration..."
    # Initialize if not already done
    if (-not (Test-Path ".terraform")) {
        Write-Status "Initializing main configuration..."
        terraform init
    }
    
    # Select a valid workspace for validation (use dev as default)
    Write-Status "Selecting workspace for validation..."
    terraform workspace select dev 2>$null
    if ($LASTEXITCODE -ne 0) {
        terraform workspace new dev
    }
    terraform validate
    
    Set-Location ".."
    Write-Status "Terraform validation completed successfully"
}

# Function to plan Terraform changes
function Plan-Terraform {
    param([string]$Env)
    
    if (-not $Env) {
        Write-Error "Environment is required for plan command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Planning Terraform Changes for $Env"
    
    Set-Location "terraform"
    
    # Initialize if not already done
    if (-not (Test-Path ".terraform")) {
        Write-Status "Initializing Terraform..."
        terraform init
    }
    
    # Use workspace script if available
    if (Test-Path "workspace.ps1") {
        .\workspace.ps1 plan $Env
    } else {
        # Manual workspace management
        terraform workspace select $Env 2>$null
        if ($LASTEXITCODE -ne 0) {
            terraform workspace new $Env
        }
        terraform plan -out=terraform-plan-$Env.out
        Write-Status "Plan saved to terraform/terraform-plan-$Env.out"
    }
    
    Set-Location ".."
}

# Function to apply Terraform changes
function Apply-Terraform {
    param([string]$Env, [string]$PlanFile)
    
    if (-not $Env) {
        Write-Error "Environment is required for apply command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Applying Terraform Changes for $Env"
    
    Set-Location "terraform"
    
    # Initialize if not already done
    if (-not (Test-Path ".terraform")) {
        Write-Status "Initializing Terraform..."
        terraform init
    }
    
    # Use workspace script if available
    if (Test-Path "workspace.ps1") {
        if ($PlanFile -and (Test-Path "../$PlanFile")) {
            Write-Status "Applying saved plan from $PlanFile"
            terraform workspace select $Env 2>$null
            if ($LASTEXITCODE -ne 0) {
                terraform workspace new $Env
            }
            terraform apply "../$PlanFile"
        } else {
            .\workspace.ps1 apply $Env
        }
    } else {
        # Manual workspace management
        terraform workspace select $Env 2>$null
        if ($LASTEXITCODE -ne 0) {
            terraform workspace new $Env
        }
        
        # Check if plan file exists
        if ($PlanFile -and (Test-Path "../$PlanFile")) {
            Write-Status "Applying saved plan from $PlanFile"
            terraform apply "../$PlanFile"
        } elseif (Test-Path "plan.out") {
            Write-Status "Applying saved plan from plan.out"
            terraform apply plan.out
        } else {
            Write-Status "No saved plan found, applying with auto-approve"
            terraform apply -auto-approve
        }
    }
    
    Set-Location ".."
}

# Function to destroy Terraform resources
function Destroy-Terraform {
    param([string]$Env)
    
    if (-not $Env) {
        Write-Error "Environment is required for destroy command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Destroying Terraform Resources for $Env"
    
    Set-Location "terraform"
    
    # Initialize if not already done
    if (-not (Test-Path ".terraform")) {
        Write-Status "Initializing Terraform..."
        terraform init
    }
    
    # Use workspace script if available
    if (Test-Path "workspace.ps1") {
        .\workspace.ps1 destroy $Env
    } else {
        # Manual workspace management
        terraform workspace select $Env 2>$null
        if ($LASTEXITCODE -ne 0) {
            terraform workspace new $Env
        }
        terraform destroy -auto-approve
    }
    
    Set-Location ".."
}

# Function to deploy to environment
function Deploy-ToEnvironment {
    param([string]$Env)
    
    if (-not $Env) {
        Write-Error "Environment is required for deploy command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Deploying to $Env Environment"
    
    # Validate configuration
    Test-TerraformConfig
    
    # Apply changes
    Apply-Terraform $Env
    
    Write-Status "Deployment to $Env completed successfully"
}

# Main script logic
function Main {
    param([string]$Command, [string]$Environment)
    
    # Check requirements first
    Test-Requirements
    
    switch ($Command) {
        "clean" {
            Clear-Build
        }
        "validate" {
            Test-TerraformConfig $false
        }
        "validate-all" {
            Test-TerraformConfig $true
        }
        "plan" {
            Plan-Terraform $Environment
        }
        "apply" {
            Apply-Terraform $Environment $args[2]
        }
        "destroy" {
            Destroy-Terraform $Environment
        }
        "deploy" {
            Deploy-ToEnvironment $Environment
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