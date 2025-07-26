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
    Write-Host "  build-layers    - Build Lambda layers (dependencies and utility)"
    Write-Host "  clean           - Clean build artifacts"
    Write-Host "  validate        - Validate Terraform configuration"
    Write-Host "  plan <env>      - Plan Terraform changes for environment (dev|qa|prod)"
    Write-Host "  apply <env>     - Apply Terraform changes for environment"
    Write-Host "  destroy <env>   - Destroy resources for environment"
    Write-Host "  deploy <env>    - Build layers and deploy to environment"
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
function Build-Layers {
    Write-Header "Building Lambda Layers"
    
    # Create layers directory if it doesn't exist
    if (-not (Test-Path "layers")) {
        New-Item -ItemType Directory -Path "layers" -Force | Out-Null
    }
    
    # Build dependencies layer
    Write-Status "Building dependencies layer..."
    if (Test-Path "layers/dependencies/nodejs") {
        Set-Location "layers/dependencies/nodejs"
        Compress-Archive -Path "." -DestinationPath "../../../dependencies.zip" -Force
        Set-Location "../../../"
        Write-Status "Dependencies layer built: layers/dependencies.zip"
    } else {
        Write-Warning "Dependencies layer directory not found. Creating empty layer..."
        New-Item -ItemType Directory -Path "layers/dependencies/nodejs" -Force | Out-Null
        '{"name": "dependencies-layer"}' | Out-File -FilePath "layers/dependencies/nodejs/package.json" -Encoding UTF8
        Set-Location "layers/dependencies/nodejs"
        Compress-Archive -Path "." -DestinationPath "../../../dependencies.zip" -Force
        Set-Location "../../../"
        Write-Status "Empty dependencies layer created: layers/dependencies.zip"
    }
    
    # Build utility layer
    Write-Status "Building utility layer..."
    if (Test-Path "layers/utility/nodejs") {
        Set-Location "layers/utility/nodejs"
        Compress-Archive -Path "." -DestinationPath "../../../utility.zip" -Force
        Set-Location "../../../"
        Write-Status "Utility layer built: layers/utility.zip"
    } else {
        Write-Warning "Utility layer directory not found. Creating empty layer..."
        New-Item -ItemType Directory -Path "layers/utility/nodejs" -Force | Out-Null
        '{"name": "utility-layer"}' | Out-File -FilePath "layers/utility/nodejs/package.json" -Encoding UTF8
        Set-Location "layers/utility/nodejs"
        Compress-Archive -Path "." -DestinationPath "../../../utility.zip" -Force
        Set-Location "../../../"
        Write-Status "Empty utility layer created: layers/utility.zip"
    }
    
    Write-Status "All Lambda layers built successfully"
}

# Function to clean build artifacts
function Clear-Build {
    Write-Header "Cleaning Build Artifacts"
    
    # Remove layer zip files
    if (Test-Path "layers/dependencies.zip") {
        Remove-Item "layers/dependencies.zip" -Force
        Write-Status "Removed layers/dependencies.zip"
    }
    
    if (Test-Path "layers/utility.zip") {
        Remove-Item "layers/utility.zip" -Force
        Write-Status "Removed layers/utility.zip"
    }
    
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
    Write-Header "Validating Terraform Configuration"
    
    Set-Location "terraform"
    
    # Check if backend setup exists
    if (Test-Path "../terraform/backend-setup") {
        Write-Status "Validating backend setup..."
        Set-Location "../terraform/backend-setup"
        terraform validate
        Set-Location "../.."
    }
    
    # Validate main configuration
    Write-Status "Validating main configuration..."
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
    
    # Use workspace script if available
    if (Test-Path "workspace.ps1") {
        .\workspace.ps1 plan $Env
    } else {
        # Manual workspace management
        terraform workspace select $Env 2>$null || terraform workspace new $Env
        terraform plan
    }
    
    Set-Location ".."
}

# Function to apply Terraform changes
function Apply-Terraform {
    param([string]$Env)
    
    if (-not $Env) {
        Write-Error "Environment is required for apply command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Applying Terraform Changes for $Env"
    
    Set-Location "terraform"
    
    # Use workspace script if available
    if (Test-Path "workspace.ps1") {
        .\workspace.ps1 apply $Env
    } else {
        # Manual workspace management
        terraform workspace select $Env 2>$null || terraform workspace new $Env
        terraform apply -auto-approve
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
    
    # Use workspace script if available
    if (Test-Path "workspace.ps1") {
        .\workspace.ps1 destroy $Env
    } else {
        # Manual workspace management
        terraform workspace select $Env 2>$null || terraform workspace new $Env
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
    
    # Build layers first
    Build-Layers
    
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
        "build-layers" {
            Build-Layers
        }
        "clean" {
            Clear-Build
        }
        "validate" {
            Test-TerraformConfig
        }
        "plan" {
            Plan-Terraform $Environment
        }
        "apply" {
            Apply-Terraform $Environment
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