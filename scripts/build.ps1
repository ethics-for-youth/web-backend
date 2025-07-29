# Build Script for EFY Web Backend Infrastructure (PowerShell)
# This script builds Lambda layers and prepares the infrastructure for deployment

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$Environment,
    
    [Parameter(Position=2)]
    [string]$PlanFile
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
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
    Write-Host "  .\build.ps1 plan dev"
    Write-Host "  .\build.ps1 deploy dev"
    Write-Host "  .\build.ps1 clean"
}

# Function to check if required tools are installed
function Test-Requirements {
    Write-Header "Checking Requirements"
    
    # Check if PowerShell version is sufficient
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-ErrorMessage "PowerShell 5.0 or higher is required."
        exit 1
    }
    
    # Check if terraform is available
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-ErrorMessage "terraform command not found. Please install Terraform."
        exit 1
    }
    
    # Check if AWS CLI is available (optional but recommended)
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Warning "AWS CLI not found. Some operations may fail."
    }
    
    Write-Status "All requirements satisfied"
}

# Function to clean build artifacts
function Clear-Build {
    Write-Header "Cleaning Build Artifacts"
    
    # Remove Terraform build artifacts
    if (Test-Path "terraform/builds") {
        Remove-Item "terraform/builds" -Recurse -Force
        Write-Status "Removed terraform/builds directory"
    }
    
    # Remove .terraform directories
    Get-ChildItem -Path "." -Name ".terraform" -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Status "Removed .terraform directories"
    
    Write-Status "Cleanup completed"
}

# Function to check if running in CI environment
function Test-CIEnvironment {
    return ($env:CI -or $env:GITHUB_ACTIONS -or $env:AZURE_PIPELINES -or $env:JENKINS_URL)
}

# Function to test AWS credentials
function Test-AWSCredentials {
    try {
        $result = aws sts get-caller-identity 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

# Function to validate Terraform configuration
function Test-TerraformConfig {
    param([bool]$ValidateBackend = $false)
    
    Write-Header "Validating Terraform Configuration"
    
    $originalLocation = Get-Location
    Set-Location "terraform"
    
    try {
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
            Set-Location "../../terraform"
        }
        
        # Validate main configuration with local backend for CI
        Write-Status "Validating main configuration..."
        
        # Use local backend for validation if in CI environment or no AWS credentials
        $useLocalBackend = (Test-CIEnvironment) -or (-not (Test-AWSCredentials))
        $backupCreated = $false
        
        if ($useLocalBackend) {
            Write-Status "Using local backend for validation..."
            # Temporarily modify backend.tf to use local backend
            if (Test-Path "backend.tf") {
                Copy-Item "backend.tf" "backend.tf.bak"
                $backupCreated = $true
                
                # Create a temporary backend.tf with local backend
                $localBackend = @'
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
'@
                Set-Content -Path "backend.tf" -Value $localBackend
                
                # Format the generated backend file
                terraform fmt backend.tf
            }
        }
        
        # Initialize if not already done or .terraform directory doesn't exist
        if (-not (Test-Path ".terraform")) {
            Write-Status "Initializing main configuration..."
            terraform init -input=false
        }
        
        # Check formatting first
        Write-Status "Checking terraform formatting..."
        terraform fmt -check -recursive .
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMessage "Terraform files are not properly formatted. Run 'terraform fmt -recursive .' to fix."
            exit 1
        }
        
        # Validate configuration
        Write-Status "Running terraform validate..."
        terraform validate
        
        # Restore original backend configuration if it was backed up
        if ($backupCreated -and (Test-Path "backend.tf.bak")) {
            Move-Item "backend.tf.bak" "backend.tf" -Force
        }
        
        Write-Status "Terraform validation completed successfully"
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to setup workspace
function Set-TerraformWorkspace {
    param([string]$Env)
    
    Write-Status "Setting up workspace: $Env"
    
    # Check if workspace exists
    $workspaces = terraform workspace list
    $workspaceExists = $workspaces | Where-Object { $_ -match "\s$Env\s|^$Env$|\*\s$Env$" }
    
    if (-not $workspaceExists) {
        Write-Status "Creating new workspace: $Env"
        terraform workspace new $Env
    }
    else {
        Write-Status "Selecting existing workspace: $Env"
        terraform workspace select $Env
    }
}

# Function to plan Terraform changes
function Plan-Terraform {
    param([string]$Env)
    
    if (-not $Env) {
        Write-ErrorMessage "Environment is required for plan command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Planning Terraform Changes for $Env"
    
    $originalLocation = Get-Location
    Set-Location "terraform"
    
    try {
        # Initialize if not already done
        if (-not (Test-Path ".terraform")) {
            Write-Status "Initializing Terraform..."
            terraform init
        }

        # Setup workspace
        Set-TerraformWorkspace $Env
        
        Write-Status "Running terraform plan..."
        terraform plan -out="terraform-plan-$Env.tfplan" -detailed-exitcode
        Write-Status "Plan saved to terraform/terraform-plan-$Env.tfplan"
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to apply Terraform changes
function Apply-Terraform {
    param([string]$Env, [string]$PlanFile)
    
    if (-not $Env) {
        Write-ErrorMessage "Environment is required for apply command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Applying Terraform Changes for $Env"
    
    $originalLocation = Get-Location
    Set-Location "terraform"
    
    try {
        # Initialize if not already done
        if (-not (Test-Path ".terraform")) {
            Write-Status "Initializing Terraform..."
            terraform init
        }

        # Setup workspace
        Set-TerraformWorkspace $Env
        
        # Check if plan file exists
        if ($PlanFile) {
            # Handle absolute and relative paths
            if (Test-Path $PlanFile) {
                Write-Status "Applying saved plan from $PlanFile"
                terraform apply $PlanFile
            }
            elseif (Test-Path "../$PlanFile") {
                Write-Status "Applying saved plan from ../$PlanFile"
                terraform apply "../$PlanFile"
            }
            elseif (Test-Path "terraform-plan-$Env.tfplan") {
                Write-Status "Applying saved plan from terraform-plan-$Env.tfplan"
                terraform apply "terraform-plan-$Env.tfplan"
            }
            else {
                Write-ErrorMessage "Plan file specified but not found: $PlanFile"
                Write-Status "Available files in current directory:"
                Get-ChildItem -Name
                Write-Status "Falling back to auto-approve"
                terraform apply -auto-approve
            }
        }
        elseif (Test-Path "terraform-plan-$Env.tfplan") {
            Write-Status "Applying saved plan from terraform-plan-$Env.tfplan"
            terraform apply "terraform-plan-$Env.tfplan"
        }
        else {
            Write-Status "No saved plan found, applying with auto-approve"
            terraform apply -auto-approve
        }
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to destroy Terraform resources
function Destroy-Terraform {
    param([string]$Env)
    
    if (-not $Env) {
        Write-ErrorMessage "Environment is required for destroy command"
        Show-Usage
        exit 1
    }
    
    Write-Header "Destroying Terraform Resources for $Env"
    
    $originalLocation = Get-Location
    Set-Location "terraform"
    
    try {
        # Initialize if not already done
        if (-not (Test-Path ".terraform")) {
            Write-Status "Initializing Terraform..."
            terraform init
        }
        
        # Use workspace script if available
        if (Test-Path "workspace.ps1") {
            & .\workspace.ps1 destroy $Env
        }
        else {
            # Manual workspace management
            Set-TerraformWorkspace $Env
            terraform destroy -auto-approve
        }
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to deploy to environment
function Deploy-ToEnvironment {
    param([string]$Env)
    
    if (-not $Env) {
        Write-ErrorMessage "Environment is required for deploy command"
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
    param([string]$Command, [string]$Environment, [string]$PlanFile)
    
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
            Apply-Terraform $Environment $PlanFile
        }
        "destroy" {
            Destroy-Terraform $Environment
        }
        "deploy" {
            Deploy-ToEnvironment $Environment
        }
        { $_ -in @("help", "--help", "-h") } {
            Show-Usage
        }
        "" {
            Write-ErrorMessage "No command specified"
            Show-Usage
            exit 1
        }
        default {
            Write-ErrorMessage "Unknown command: $Command"
            Show-Usage
            exit 1
        }
    }
}

# Run main function with all arguments
Main $Command $Environment $PlanFile 