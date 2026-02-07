# CLAUDE.md

This file provides guidance to Claude Code or Cursor agent (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Deployment
- `npm run build` - Build Lambda layers and validate Terraform configuration  
- `npm run validate` - Validate Terraform configuration only
- `npm run plan:dev` - Plan Terraform changes for dev environment
- `npm run plan:qa` - Plan Terraform changes for qa environment  
- `npm run plan:prod` - Plan Terraform changes for prod environment
- `npm run deploy:dev` - Deploy to dev environment
- `npm run clean` - Clean build artifacts and .terraform directories
- `npm run install:layers` - Install dependencies for Lambda layers

### Manual Terraform Operations
```bash
# Navigate to terraform directory first
cd terraform

# Initialize with specific environment backend
terraform init -backend-config="backend-dev.tfbackend"

# Create/select workspace
terraform workspace new dev  # or select existing
terraform workspace select dev

# Plan with environment-specific variables
terraform plan -var-file="terraform.dev.tfvars" -out=terraform-plan-dev.tfplan

# Apply changes
terraform apply terraform-plan-dev.tfplan
```

### Testing
- `./scripts/test_endpoints.sh` - Manual endpoint testing script for deployed APIs
- No automated test framework is configured in this project

## Architecture Overview

### Serverless AWS Lambda Architecture
This is a serverless backend built entirely on AWS Lambda functions, with each API endpoint implemented as a separate Lambda function. The infrastructure is managed through Terraform with multi-environment support (dev/qa/prod).

### Key Components
- **Lambda Functions**: Each API endpoint has its own function in `lambda_functions/`
- **Lambda Layers**: Shared code and dependencies in `layers/`
  - `dependencies` layer: External npm packages (AWS SDK, bcrypt, etc.)  
  - `utility` layer: Custom shared utilities (`utils.js`)
- **DynamoDB**: NoSQL database for all data persistence
- **API Gateway**: REST API routing to Lambda functions
- **Terraform Modules**: Reusable infrastructure components in `terraform/modules/`

### Lambda Function Pattern
All Lambda functions follow the same structure:
- Import utilities from `/opt/nodejs/utils` (utility layer)
- Use AWS SDK v3 with DynamoDBDocumentClient
- Consistent error handling with `successResponse()` and `errorResponse()`
- Environment variables for table names and AWS region

### Database Tables
The system uses DynamoDB with the following tables:
- `EVENTS_TABLE_NAME` - Events and workshops (includes registrationFee field)
- `COMPETITIONS_TABLE_NAME` - Competitions and contests (includes registrationFee field)
- `VOLUNTEERS_TABLE_NAME` - Volunteer applications  
- `SUGGESTIONS_TABLE_NAME` - Community suggestions
- `COURSES_TABLE_NAME` - Educational courses (includes registrationFee field)
- `REGISTRATIONS_TABLE_NAME` - Event/competition registrations (includes payment tracking)
- `MESSAGES_TABLE_NAME` - Community messages and feedback
- `PAYMENTS_TABLE_NAME` - Payment orders and webhook events

### Multi-Environment Setup
- **Workspaces**: Terraform workspaces for environment isolation (dev/qa/prod)
- **Backend Config**: S3 backend with environment-specific configs in `backend-{env}.tfbackend`
- **Variable Files**: Environment-specific variables in `terraform.{env}.tfvars`
- **Resource Naming**: All resources prefixed with `{project_name}-{environment}`

### API Endpoints Structure
The API follows RESTful conventions with endpoints for:
- Events: CRUD operations for workshops and events
- Competitions: Competition management with registration and results
- Volunteers: Volunteer application submission and management
- Suggestions: Community idea submission and viewing
- Courses: Educational course management
- Registrations: Cross-entity registration system
- Messages: Community messaging and feedback
- Admin: Dashboard statistics and metrics

### Shared Utilities (`layers/utility/nodejs/utils.js`)
- `successResponse(data, message, statusCode)` - Standard success responses
- `errorResponse(error, statusCode)` - Standard error responses  
- `validateRequired(obj, fields)` - Required field validation
- `parseJSON(str)` - Safe JSON parsing with error handling
- `isEmptyString(value)` - String validation utility

### Development Workflow
1. Make changes to Lambda function code in `lambda_functions/`
2. If adding shared utilities, update `layers/utility/nodejs/utils.js`
3. If adding dependencies, update `layers/dependencies/nodejs/package.json`
4. Run `npm run validate` to check Terraform configuration
5. Run `npm run plan:dev` to preview infrastructure changes
6. Run `npm run deploy:dev` to deploy to development environment
7. Test endpoints using `./scripts/test_endpoints.sh`
8. Test registration fees using `./scripts/test_registration_fee.sh`
9. Test payment integration using `./scripts/test_payment_integration_improved.sh`

### Registration Fee Integration
All events, competitions, and courses now support registration fees:
- **Events**: `registrationFee` field (defaults to 0 for free events)
- **Competitions**: `registrationFee` field (defaults to 0 for free competitions)  
- **Courses**: `registrationFee` field (defaults to 0 for free courses)
- **Registrations**: Tracks `registrationFee`, `paymentStatus`, and `paymentId`
- **Integration**: Compatible with Razorpay payment gateway for paid registrations

### Important Notes
- All Lambda functions use Node.js runtime with AWS SDK v3
- CORS is configured for all endpoints to allow web frontend access
- No authentication is implemented - all endpoints are public
- Environment variables are set automatically by Terraform for each function
- The utility layer is available at `/opt/nodejs/utils` in all Lambda functions
- Build script automatically installs layer dependencies before deployment