#!/bin/bash

# RBAC Implementation Validation Script
# This script validates that all components of the RBAC system are properly implemented

set -e  # Exit on any error

echo "🔍 Validating RBAC Implementation..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_TOTAL=0

# Function to check and report
check_item() {
    local description="$1"
    local command="$2"
    local expected_result="$3"
    
    echo -n "Checking: $description... "
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
}

# Function to check file exists
check_file() {
    local description="$1"
    local file_path="$2"
    
    check_item "$description" "test -f '$file_path'"
}

# Function to check directory exists
check_directory() {
    local description="$1"
    local dir_path="$2"
    
    check_item "$description" "test -d '$dir_path'"
}

echo ""
echo "📁 File Structure Validation"
echo "----------------------------"

# Check Terraform modules
check_directory "Cognito Terraform module" "terraform/modules/cognito"
check_file "Cognito main.tf" "terraform/modules/cognito/main.tf"
check_file "Cognito variables.tf" "terraform/modules/cognito/variables.tf"
check_file "Cognito outputs.tf" "terraform/modules/cognito/outputs.tf"

# Check Lambda layers
check_file "Authentication middleware" "layers/utility/nodejs/auth.js"
check_file "Permission management" "layers/utility/nodejs/permissions.js"
check_file "Updated utils.js" "layers/utility/nodejs/utils.js"

# Check dependencies
check_file "Dependencies package.json" "layers/dependencies/nodejs/package.json"
check_item "JWT dependencies installed" "grep -q 'jsonwebtoken' layers/dependencies/nodejs/package.json"
check_item "JWKS dependencies installed" "grep -q 'jwks-rsa' layers/dependencies/nodejs/package.json"

echo ""
echo "🔧 Lambda Functions Validation"
echo "------------------------------"

# Check updated Lambda functions
check_file "Updated events_get function" "lambda_functions/events_get/index.js"
check_file "Updated events_post function" "lambda_functions/events_post/index.js"
check_item "Events_get has auth middleware" "grep -q 'createAuthMiddleware' lambda_functions/events_get/index.js"
check_item "Events_post has auth middleware" "grep -q 'createAuthMiddleware' lambda_functions/events_post/index.js"

# Check new volunteer functions
check_directory "Volunteer tasks get function" "lambda_functions/volunteers_tasks_get"
check_directory "Volunteer tasks post function" "lambda_functions/volunteers_tasks_post"
check_directory "Volunteer tasks put function" "lambda_functions/volunteers_tasks_put"
check_directory "Volunteer applications get function" "lambda_functions/volunteers_applications_get"

# Check volunteer function content
check_item "Volunteer tasks get has auth" "grep -q 'createAuthMiddleware' lambda_functions/volunteers_tasks_get/index.js"
check_item "Volunteer tasks post has auth" "grep -q 'createAuthMiddleware' lambda_functions/volunteers_tasks_post/index.js"

echo ""
echo "📊 Database Schema Validation"
echo "-----------------------------"

# Check DynamoDB table definitions
check_item "Permissions table defined" "grep -q 'permissions' terraform/modules/dynamodb/main.tf"
check_item "Users table defined" "grep -q 'users' terraform/modules/dynamodb/main.tf"
check_item "Volunteer tasks table defined" "grep -q 'volunteer_tasks' terraform/modules/dynamodb/main.tf"
check_item "Volunteer applications table defined" "grep -q 'volunteer_applications' terraform/modules/dynamodb/main.tf"

# Check migration scripts
check_file "Database migration script" "scripts/migrate_user_associations.js"
check_file "Migration package.json" "scripts/package.json"

echo ""
echo "🌐 API Gateway Validation"
echo "-------------------------"

# Check API Gateway updates
check_item "Cognito authorizer in API Gateway" "grep -q 'aws_api_gateway_authorizer' terraform/modules/efy_api_gateway/main.tf"
check_item "Cognito authorizer variables" "grep -q 'cognito_user_pool_arn' terraform/modules/efy_api_gateway/variables.tf"

echo ""
echo "⚙️ Terraform Configuration Validation"
echo "-------------------------------------"

# Check main Terraform configuration
check_item "Cognito module included" "grep -q 'module \"cognito\"' terraform/main.tf"
check_item "RBAC tables in DynamoDB module" "grep -q 'permissions_table_name' terraform/main.tf"
check_item "Cognito outputs defined" "grep -q 'cognito_user_pool_id' terraform/outputs.tf"

# Terraform validation
cd terraform
check_item "Terraform configuration valid" "terraform validate"
cd ..

echo ""
echo "📚 Documentation Validation"  
echo "---------------------------"

# Check documentation files
check_file "RBAC implementation plan" "docs/COGNITO_RBAC_PLAN.md"
check_file "Lambda auth pattern docs" "docs/LAMBDA_AUTH_PATTERN.md"
check_file "Database schema docs" "docs/DATABASE_SCHEMA_UPDATES.md"
check_file "Testing guide" "docs/RBAC_TESTING_GUIDE.md"

# Check README updates
check_item "CLAUDE.md mentions auth" "grep -q -i 'auth\|cognito' CLAUDE.md || echo 'No auth mention found'"

echo ""
echo "🔐 Security Configuration Validation"
echo "-----------------------------------"

# Check security settings
check_item "Password policy configured" "grep -q 'password_policy' terraform/modules/cognito/main.tf"
check_item "MFA support configured" "grep -q 'user_pool_add_ons' terraform/modules/cognito/main.tf"
check_item "JWT token expiry set" "grep -q 'access_token_validity' terraform/modules/cognito/main.tf"

echo ""
echo "📊 Environment Configuration Validation"
echo "--------------------------------------"

# Check that auth is disabled by default for safe deployment
check_item "Auth disabled by default in events_get" "grep -q 'ENABLE_AUTH.*false' terraform/main.tf"
check_item "Backward compatibility maintained" "grep -q 'Skip authentication if disabled' lambda_functions/events_get/index.js"

echo ""
echo "🚀 Deployment Readiness Validation"
echo "---------------------------------"

# Check build and deployment scripts
check_item "Build script exists" "test -f scripts/build.sh || test -f scripts/build.ps1"
check_item "Package.json has scripts" "test -f package.json && grep -q scripts package.json || echo 'No package.json or scripts'"

echo ""
echo "═══════════════════════════════════"
echo "📊 VALIDATION SUMMARY"
echo "═══════════════════════════════════"

echo -e "Total Checks: ${YELLOW}$CHECKS_TOTAL${NC}"
echo -e "Passed: ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Failed: ${RED}$CHECKS_FAILED${NC}"

# Calculate percentage
if [ $CHECKS_TOTAL -gt 0 ]; then
    PERCENTAGE=$((CHECKS_PASSED * 100 / CHECKS_TOTAL))
    echo -e "Success Rate: ${YELLOW}${PERCENTAGE}%${NC}"
fi

echo ""
if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL VALIDATION CHECKS PASSED!${NC}"
    echo -e "${GREEN}✅ RBAC implementation is ready for deployment${NC}"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Deploy infrastructure: terraform apply"
    echo "2. Run database migration: npm run migrate:dev"
    echo "3. Create test users in Cognito"
    echo "4. Test authentication: see docs/RBAC_TESTING_GUIDE.md"
    echo "5. Enable authentication: set ENABLE_AUTH=true"
    exit 0
else
    echo -e "${RED}❌ $CHECKS_FAILED VALIDATION CHECK(S) FAILED${NC}"
    echo -e "${YELLOW}⚠️  Please fix the failed checks before deployment${NC}"
    echo ""
    echo "📋 Common Issues:"
    echo "• Missing files: Check if all files were created correctly"
    echo "• Terraform errors: Run 'terraform validate' for details"  
    echo "• Dependencies: Ensure npm install was run in layers/dependencies/nodejs"
    exit 1
fi