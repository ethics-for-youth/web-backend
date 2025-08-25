# Scripts Directory

This directory contains utility scripts for building, testing, and managing the EFY API project.

## 📁 Available Scripts

### 🔨 Build Scripts

#### `build.sh` (Linux/macOS)
**Purpose**: Builds and deploys the EFY API infrastructure using Terraform.

**Usage**:
```bash
# Make executable (if needed)
chmod +x scripts/build.sh

# Run the build script
./scripts/build.sh
```

**What it does**:
- Sets up the development environment
- Builds Lambda function packages
- Creates deployment packages for layers
- Runs Terraform to deploy infrastructure to AWS
- Configures API Gateway and DynamoDB tables

**Prerequisites**:
- AWS CLI configured with appropriate credentials
- Terraform installed
- Node.js installed for Lambda dependencies
- Bash shell environment

---

#### `build.ps1` (Windows PowerShell)
**Purpose**: Windows equivalent of the build.sh script.

**Usage**:
```powershell
# Run from PowerShell
.\scripts\build.ps1
```

**What it does**:
- Same functionality as build.sh but for Windows environments
- Uses PowerShell commands instead of bash
- Handles Windows-specific path formatting

**Prerequisites**:
- PowerShell 5.0 or later
- AWS CLI configured
- Terraform installed
- Node.js installed

---

### 🧪 Testing Scripts

#### `test_endpoints.sh`
**Purpose**: Quick validation test for all POST endpoints with simple test data.

**Usage**:
```bash
# Make executable
chmod +x scripts/test_endpoints.sh

# Run the test
./scripts/test_endpoints.sh
```

**What it tests**:
- Events POST endpoint (`/events`)
- Competitions POST endpoint (`/competitions`) 
- Volunteers POST endpoint (`/volunteers/apply`)
- Suggestions POST endpoint (`/suggestions`)

**Sample Output**:
```
🧪 Testing Individual POST Endpoints...
1️⃣ Testing Events POST endpoint:
{"success":true,"message":"Event created successfully",...}

2️⃣ Testing Competitions POST endpoint:
{"success":true,"message":"Competition created successfully",...}
```

**When to use**:
- After deploying/redeploying the infrastructure
- Quick validation that POST endpoints are working
- Debugging individual endpoint issues
- Before running the full database population

---

### 📊 Database Population Scripts

#### `populate_database.sh`
**Purpose**: Populates the database with comprehensive dummy data for testing and development.

**Usage**:
```bash
# Make executable
chmod +x scripts/populate_database.sh

# Run the population script
./scripts/populate_database.sh
```

**What it creates**:
- **4 Events**: Tech conferences, workshops, health fairs, educational programs
- **3 Competitions**: Hackathons, innovation challenges, essay contests
- **5 Volunteer Applications**: Diverse volunteers with different skills and backgrounds
- **6 Suggestions**: Feature requests and improvement suggestions

**Sample Records Created**:

**Events**:
- Annual Tech Conference 2024 (Mumbai)
- Green Energy Workshop (Delhi)
- Community Health Fair (Bangalore)
- Digital Literacy Program (Chennai)

**Competitions**:
- CodeForGood Hackathon 2024
- Sustainable Innovation Challenge
- Youth Leadership Essay Contest

**Volunteers**:
- Priya Sharma (Event Management)
- Rahul Gupta (Web Development)
- Anjali Reddy (Healthcare)
- Vikram Singh (Photography/Marketing)
- Meera Patel (Education)

**Suggestions**:
- Mobile App for Event Registration
- Eco-Friendly Event Materials
- Mentorship Program for New Volunteers
- Partnership with Local Schools
- Virtual Reality Training Sessions
- Community Impact Dashboard

**Features**:
- ✅ Detailed progress reporting
- ✅ Error handling and status codes
- ✅ Summary statistics at completion
- ✅ Individual record tracking
- ✅ Realistic, diverse data

**When to use**:
- Initial setup of development/test environment
- After database resets or migrations
- Demonstrating the application with realistic data
- Load testing with substantial data sets

---

## 🚀 Common Workflows

### Initial Setup
```bash
# 1. Build and deploy infrastructure
./scripts/build.sh

# 2. Test that endpoints are working
./scripts/test_endpoints.sh

# 3. Populate with dummy data
./scripts/populate_database.sh
```

### After Code Changes
```bash
# 1. Redeploy infrastructure
./scripts/build.sh

# 2. Quick validation
./scripts/test_endpoints.sh

# 3. (Optional) Repopulate data if needed
./scripts/populate_database.sh
```

### Troubleshooting Failed Endpoints
```bash
# 1. Test individual endpoints
./scripts/test_endpoints.sh

# 2. Check specific endpoint manually
curl -X GET https://d4ca8ryveb.execute-api.ap-south-1.amazonaws.com/default/events

# 3. If needed, rebuild and test
./scripts/build.sh
./scripts/test_endpoints.sh
```

## 📋 Prerequisites

### General Requirements
- AWS CLI configured with appropriate permissions
- Active AWS account with DynamoDB and Lambda access
- Internet connection for AWS API calls

### For Build Scripts
- Terraform >= 1.0
- Node.js >= 18.x
- npm or yarn package manager

### For Test Scripts
- curl command-line tool
- bash shell (Linux/macOS/WSL)

## 🔧 Configuration

### API Endpoint
The scripts are currently configured for:
```
https://d4ca8ryveb.execute-api.ap-south-1.amazonaws.com/default
```

To change the endpoint, modify the `API_BASE_URL` variable in:
- `test_endpoints.sh`
- `populate_database.sh`

### Environment Variables
Some scripts may use these environment variables:
- `AWS_REGION`: AWS region for deployment
- `AWS_PROFILE`: AWS CLI profile to use
- `TF_VAR_*`: Terraform variable overrides

## 📝 Notes

- Always run `test_endpoints.sh` before `populate_database.sh` to ensure endpoints are working
- The populate script will show detailed error messages if endpoints are not functioning
- Build scripts handle dependency installation automatically
- All scripts include error handling and status reporting

## 🆘 Troubleshooting

### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### API Gateway Issues
- Verify AWS credentials are configured
- Check that the API Gateway URL is correct
- Ensure the deployed environment matches the script configuration

### Data Population Failures
- Run `test_endpoints.sh` first to identify failing endpoints
- Check CloudWatch logs for Lambda function errors
- Verify DynamoDB tables exist and have proper permissions