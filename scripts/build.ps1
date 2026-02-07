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
    Write-Host "  help            - Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build.ps1 validate"
    Write-Host "  .\build.ps1 plan dev"
    Write-Host "  .\build.ps1 apply dev"
    Write-Host "  .\build.ps1 apply dev terraform-plan-dev.tfplan"
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
    
    # Check if npm is available (required for layer dependencies)
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-ErrorMessage "npm command not found. Please install Node.js and npm."
        exit 1
    }
    
    # Check if AWS CLI is available (optional but recommended)
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Warning "AWS CLI not found. Some operations may fail."
    }
    
    Write-Status "All requirements satisfied"
}

# Function to install Lambda layer dependencies
function Install-LayerDependencies {
    Write-Header "Installing Lambda Layer Dependencies"
    
    $originalLocation = Get-Location
    
    try {
        # Install dependencies for dependencies layer
        if (Test-Path "layers/dependencies/nodejs") {
            Write-Status "Installing dependencies layer..."
            Set-Location "layers/dependencies/nodejs"
            if (Test-Path "package.json") {
                npm install --production
                Write-Status "Dependencies layer installed successfully"
            }
            Set-Location $originalLocation
        }
        
        # Check utility layer (usually no dependencies)
        if (Test-Path "layers/utility/nodejs") {
            Set-Location "layers/utility/nodejs"
            if (Test-Path "package.json") {
                $packageContent = Get-Content "package.json" -Raw
                if ($packageContent -like '*"dependencies"*:*{*}*') {
                    Write-Status "Installing utility layer..."
                    npm install --production
                    Write-Status "Utility layer installed successfully"
                }
                else {
                    Write-Status "Utility layer has no dependencies to install"
                }
            }
            Set-Location $originalLocation
        }
        
        Write-Status "Layer dependencies installation completed"
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to build reproducible layer zips
function Build-LayerZips {
    Write-Header "Building Reproducible Layer Zips"
    
    $originalLocation = Get-Location
    
    try {
        # Create builds directory if it doesn't exist
        if (-not (Test-Path "terraform/builds")) {
            New-Item -Path "terraform/builds" -ItemType Directory -Force | Out-Null
        }
        
        # Build dependencies layer
        if (Test-Path "layers/dependencies") {
            Write-Status "Creating reproducible zip for dependencies layer..."
            Set-Location "layers/dependencies"
            
            # Remove any existing zip
            if (Test-Path "../../terraform/builds/dependencies-layer.zip") {
                Remove-Item "../../terraform/builds/dependencies-layer.zip" -Force
            }
            
            # Use 7-zip or Compress-Archive to create zip
            # Note: PowerShell's Compress-Archive includes timestamps
            # For true reproducibility, we'd need 7-zip with specific flags
            # For now, this is better than the previous approach
            Compress-Archive -Path ".\*" -DestinationPath "..\..\terraform\builds\dependencies-layer.zip" -Force
            
            $size = (Get-Item "..\..\terraform\builds\dependencies-layer.zip").Length
            $sizeKB = [math]::Round($size / 1KB, 2)
            Write-Status "Dependencies layer zip created: $sizeKB KB"
            Set-Location $originalLocation
        }
        
        # Build utility layer
        if (Test-Path "layers/utility") {
            Write-Status "Creating reproducible zip for utility layer..."
            Set-Location "layers/utility"
            
            # Remove any existing zip
            if (Test-Path "../../terraform/builds/utility-layer.zip") {
                Remove-Item "../../terraform/builds/utility-layer.zip" -Force
            }
            
            Compress-Archive -Path ".\*" -DestinationPath "..\..\terraform\builds\utility-layer.zip" -Force
            
            $size = (Get-Item "..\..\terraform\builds\utility-layer.zip").Length
            $sizeKB = [math]::Round($size / 1KB, 2)
            Write-Status "Utility layer zip created: $sizeKB KB"
            Set-Location $originalLocation
        }
        
        Write-Status "Layer zip creation completed"
    }
    finally {
        Set-Location $originalLocation
    }
}

# Function to build reproducible lambda function zips
function Build-LambdaZips {
    Write-Header "Building Reproducible Lambda Function Zips"
    
    $originalLocation = Get-Location
    
    try {
        # Create builds directory if it doesn't exist
        if (-not (Test-Path "terraform/builds")) {
            New-Item -Path "terraform/builds" -ItemType Directory -Force | Out-Null
        }
        
        $lambdaCount = 0
        
        # Build each lambda function
        if (Test-Path "lambda_functions") {
            $lambdaDirs = Get-ChildItem -Path "lambda_functions" -Directory
            
            foreach ($lambdaDir in $lambdaDirs) {
                $lambdaName = $lambdaDir.Name
                Write-Status "Creating reproducible zip for $lambdaName..."
                
                Set-Location $lambdaDir.FullName
                
                # Remove any existing zip
                $zipPath = "..\..\terraform\builds\$lambdaName.zip"
                if (Test-Path $zipPath) {
                    Remove-Item $zipPath -Force
                }
                
                # Create zip
                Compress-Archive -Path ".\*" -DestinationPath $zipPath -Force
                
                $lambdaCount++
                Set-Location $originalLocation
            }
        }
        
        Write-Status "Created $lambdaCount lambda function zips"
        Write-Status "Lambda function zip creation completed"
    }
    finally {
        Set-Location $originalLocation
    }
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
    
    # Remove node_modules from layers (will be reinstalled when needed)
    if (Test-Path "layers/dependencies/nodejs/node_modules") {
        Remove-Item "layers/dependencies/nodejs/node_modules" -Recurse -Force
        Write-Status "Removed dependencies layer node_modules"
    }
    
    if (Test-Path "layers/utility/nodejs/node_modules") {
        Remove-Item "layers/utility/nodejs/node_modules" -Recurse -Force
        Write-Status "Removed utility layer node_modules"
    }
    
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
        
        # Validate main configuration
        Write-Status "Validating main configuration..."
        
        # For validation only, use local backend if AWS credentials are not available
        $useLocalBackend = (Test-CIEnvironment) -or (-not (Test-AWSCredentials))
        $backupCreated = $false
        
        if ($useLocalBackend) {
            Write-Status "Using local backend for validation (no AWS credentials)..."
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

  # Local backend for validation only
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
        if ((-not (Test-Path ".terraform")) -or $useLocalBackend) {
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
            Write-Status "Initializing Terraform with S3 backend for $Env..."
            terraform init -backend-config="backend-$Env.tfbackend"
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
            Write-Status "Initializing Terraform with S3 backend for $Env..."
            terraform init -backend-config="backend-$Env.tfbackend"
        }

        # Setup workspace
        Set-TerraformWorkspace $Env
        
        # Determine the plan file to use
        $actualPlanFile = ""
        
        if ($PlanFile) {
            # Plan file was explicitly specified
            if (Test-Path $PlanFile) {
                $actualPlanFile = $PlanFile
            }
            elseif (Test-Path "../$PlanFile") {
                $actualPlanFile = "../$PlanFile"
            }
            else {
                Write-ErrorMessage "Specified plan file not found: $PlanFile"
                Write-Status "Available files in current directory:"
                Get-ChildItem -Name
                Write-Status "Available files in parent directory:"
                Get-ChildItem -Path ".." -Name
                exit 1
            }
        }
        elseif (Test-Path "terraform-plan-$Env.tfplan") {
            # Check for default plan file
            $actualPlanFile = "terraform-plan-$Env.tfplan"
        }
        
        # Apply terraform changes
        if ($actualPlanFile) {
            Write-Status "Applying saved plan from $actualPlanFile"
            terraform apply $actualPlanFile
        }
        else {
            Write-Status "No plan file found, applying with var file: terraform.$Env.tfvars"
            if (Test-Path "terraform.$Env.tfvars") {
                terraform apply -var-file="terraform.$Env.tfvars" -auto-approve
            }
            else {
                Write-ErrorMessage "No var file found for environment $Env. Please ensure terraform.$Env.tfvars exists."
                exit 1
            }
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
            Write-Status "Initializing Terraform with S3 backend for $Env..."
            terraform init -backend-config="backend-$Env.tfbackend"
        }
        

        # Manual workspace management
        Set-TerraformWorkspace $Env
        terraform destroy -auto-approve

    }
    finally {
        Set-Location $originalLocation
    }
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
            Install-LayerDependencies
            Test-TerraformConfig $false
        }
        "validate-all" {
            Install-LayerDependencies
            Test-TerraformConfig $true
        }
        "plan" {
            Install-LayerDependencies
            Build-LayerZips
            Build-LambdaZips
            Plan-Terraform $Environment
        }
        "apply" {
            # Skip dependency installation if using pre-built artifacts
            if ((Test-Path "terraform/builds") -and $PlanFile) {
                Write-Status "Using pre-built artifacts, skipping dependency installation and build"
            } else {
                Install-LayerDependencies
                Build-LayerZips
                Build-LambdaZips
            }
            Apply-Terraform $Environment $PlanFile
        }
        "destroy" {
            Destroy-Terraform $Environment
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