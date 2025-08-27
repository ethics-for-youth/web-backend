# Amazon Cognito RBAC Implementation Plan for EFY Backend

This document outlines the comprehensive plan for implementing role-based authentication and authorization using Amazon Cognito in the EFY serverless backend.

## 🎯 Overview

### Current State
- **No Authentication**: All API endpoints are currently public (`authorization = "NONE"`)
- **Serverless Architecture**: AWS Lambda + API Gateway + DynamoDB
- **Infrastructure**: Terraform-managed with multi-environment support
- **Payment Integration**: Razorpay payment gateway already implemented

### Target State
- **Cognito User Pool**: User registration, authentication, and profile management
- **Cognito Identity Pool**: AWS credentials for authenticated users
- **Role-Based Access Control**: Four user types with specific permissions
- **JWT Token Validation**: Secure API access with role-based authorization
- **Scalable Permission System**: Easy to add new roles and permissions

## ️ Architecture Plan

### 1. Cognito Components

#### User Pool
- **User Registration**: Email/password with email verification
- **User Groups**: student, teacher, volunteer, admin with IAM roles
- **Custom Attributes**: role, organization, phone_number
- **Password Policy**: Secure password requirements
- **MFA**: Optional for enhanced security

#### Identity Pool
- **Authenticated Role**: IAM role for authenticated users
- **Unauthenticated Role**: Limited IAM role for public access
- **Identity Pool Mapping**: Maps Cognito groups to IAM roles

### 2. Permission Structure

#### Role Hierarchy
```markdown:docs/COGNITO_RBAC_PLAN.md
<code_block_to_apply_changes_from>
Admin (Full Access)
├── Manage all events, competitions, courses
├── Manage volunteers and registrations
├── Access admin dashboard and analytics
├── Manage payments and financial data
└── User management and role assignments

Teacher (Course Management)
├── Create and manage courses
├── View student registrations and progress
├── Mark attendance and grades
├── Access course analytics
└── Submit suggestions and feedback

Volunteer (Event Support)
├── Register for events and competitions
├── View available courses
├── Submit suggestions and messages
├── Apply for volunteer positions
├── View assigned volunteer tasks
├── Mark task completion
├── Access volunteer dashboard
└── Submit volunteer reports

Student (Limited Access)
├── Register for events and competitions
├── View available courses
├── Submit suggestions and messages
├── View personal registrations
└── Access course materials (if enrolled)
```

#### Permission Matrix

| Resource | Student | Teacher | Volunteer | Admin |
|----------|---------|---------|-----------|-------|
| Events (GET) | ✅ | ✅ | ✅ | ✅ |
| Events (POST/PUT/DELETE) | ❌ | ❌ | ❌ | ✅ |
| Competitions (GET) | ✅ | ✅ | ✅ | ✅ |
| Competitions (POST/PUT/DELETE) | ❌ | ❌ | ❌ | ✅ |
| Courses (GET) | ✅ | ✅ | ✅ | ✅ |
| Courses (POST/PUT/DELETE) | ❌ | ✅ | ❌ | ✅ |
| Registrations (GET own) | ✅ | ❌ | ✅ | ✅ |
| Registrations (GET all) | ❌ | ✅ | ❌ | ✅ |
| Registrations (POST) | ✅ | ❌ | ✅ | ✅ |
| Volunteers (GET) | ❌ | ❌ | ✅ (own) | ✅ |
| Volunteers (POST/PUT) | ✅ | ❌ | ✅ (own) | ✅ |
| Volunteer Tasks (GET) | ❌ | ❌ | ✅ (assigned) | ✅ |
| Volunteer Tasks (POST/PUT) | ❌ | ❌ | ✅ (own) | ✅ |
| Volunteer Applications (GET) | ❌ | ❌ | ✅ (own) | ✅ |
| Volunteer Applications (POST) | ✅ | ❌ | ✅ | ✅ |
| Suggestions (GET) | ✅ | ✅ | ✅ | ✅ |
| Suggestions (POST) | ✅ | ✅ | ✅ | ✅ |
| Messages (GET) | ✅ | ✅ | ✅ | ✅ |
| Messages (POST) | ✅ | ✅ | ✅ | ✅ |
| Admin Stats | ❌ | ❌ | ❌ | ✅ |
| Payments (Create Order) | ✅ | ❌ | ✅ | ✅ |
| Payments (Webhook) | ❌ | ❌ | ❌ | ✅ |

### 3. Implementation Strategy

#### Phase 1: Infrastructure Setup
1. Create Cognito User Pool with groups and IAM roles
2. Create Cognito Identity Pool with role mappings
3. Update API Gateway with Cognito Authorizer
4. Create permission management system

#### Phase 2: Authentication Middleware
1. Create JWT validation Lambda middleware
2. Implement role-based permission checking
3. Update existing Lambda functions to use middleware
4. Add user context to Lambda functions

#### Phase 3: API Updates
1. Update API Gateway methods to require authorization
2. Implement fine-grained permission checks
3. Add user-specific data filtering
4. Update error responses for unauthorized access

#### Phase 4: Testing & Migration
1. Test all endpoints with different user roles
2. Migrate existing data to include user associations
3. Update frontend to handle authentication
4. Performance testing and optimization

## 📋 Detailed Implementation Plan

### 1. Terraform Infrastructure

#### New Terraform Module: `cognito`
```
terraform/modules/cognito/
├── main.tf          # Cognito User Pool, Identity Pool, IAM roles
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── README.md        # Module documentation
```

#### Key Resources to Create:
- `aws_cognito_user_pool` - User authentication and management
- `aws_cognito_user_groups` - Role-based groups (student, teacher, volunteer, admin)
- `aws_cognito_identity_pool` - AWS credentials for authenticated users
- `aws_iam_role` - IAM roles for each user group
- `aws_iam_role_policy` - Permission policies for each role
- `aws_api_gateway_authorizer` - Cognito authorizer for API Gateway

#### Environment Variables:
```hcl
# Cognito configuration
cognito_user_pool_name = "efy-{environment}-user-pool"
cognito_identity_pool_name = "efy-{environment}-identity-pool"
cognito_user_pool_domain = "efy-{environment}"

# IAM role names
cognito_authenticated_role_name = "efy-{environment}-cognito-authenticated"
cognito_unauthenticated_role_name = "efy-{environment}-cognito-unauthenticated"
```

### 2. Permission Management System

#### Option A: DynamoDB Permission Table (Recommended)
```json
{
  "pk": "PERMISSION#events:read",
  "sk": "ROLE#student",
  "resource": "events",
  "action": "read",
  "role": "student",
  "allowed": true,
  "conditions": {
    "public": true
  }
}

{
  "pk": "PERMISSION#volunteers:read",
  "sk": "ROLE#volunteer",
  "resource": "volunteers",
  "action": "read",
  "role": "volunteer",
  "allowed": true,
  "conditions": {
    "own_only": true
  }
}

{
  "pk": "PERMISSION#volunteer_tasks:read",
  "sk": "ROLE#volunteer",
  "resource": "volunteer_tasks",
  "action": "read",
  "role": "volunteer",
  "allowed": true,
  "conditions": {
    "assigned_only": true
  }
}
```

#### Option B: Inline IAM Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "execute-api:Invoke"
      ],
      "Resource": [
        "arn:aws:execute-api:region:account:api-id/*/GET/events",
        "arn:aws:execute-api:region:account:api-id/*/POST/registrations",
        "arn:aws:execute-api:region:account:api-id/*/GET/volunteers/tasks"
      ]
    }
  ]
}
```

#### Recommended Approach: Hybrid System
- **DynamoDB**: Store detailed permission rules and conditions
- **IAM Policies**: Basic API access control
- **Lambda Middleware**: Fine-grained permission checking

### 3. Lambda Middleware Architecture

#### Authentication Middleware
```javascript
// layers/utility/nodejs/auth.js
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

class AuthMiddleware {
  constructor() {
    this.client = jwksClient({
      jwksUri: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`
    });
  }

  async validateToken(token) {
    // JWT validation logic
  }

  async getUserInfo(token) {
    // Extract user info from JWT
  }

  async checkPermission(user, resource, action) {
    // Check DynamoDB permissions
  }

  async checkVolunteerPermission(user, resource, action, resourceId = null) {
    // Check volunteer-specific permissions with resource ownership
  }
}
```

#### Integration Pattern
```javascript
// Example Lambda function with auth
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { AuthMiddleware } = require('/opt/nodejs/auth');

const auth = new AuthMiddleware();

exports.handler = async (event) => {
  try {
    // 1. Extract and validate JWT token
    const token = event.headers.Authorization?.replace('Bearer ', '');
    if (!token) {
      return errorResponse('Unauthorized: No token provided', 401);
    }

    // 2. Validate token and get user info
    const user = await auth.validateToken(token);
    if (!user) {
      return errorResponse('Unauthorized: Invalid token', 401);
    }

    // 3. Check permissions
    const hasPermission = await auth.checkPermission(user, 'events', 'read');
    if (!hasPermission) {
      return errorResponse('Forbidden: Insufficient permissions', 403);
    }

    // 4. Execute business logic
    const result = await processEvent(event, user);

    return successResponse(result, 'Event processed successfully');
  } catch (error) {
    return errorResponse(error, 500);
  }
};
```

### 4. API Gateway Updates

#### Cognito Authorizer Configuration
```hcl
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "efy-${var.environment}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  provider_arns = [aws_cognito_user_pool.efy_user_pool.arn]
}
```

#### Method Authorization Updates
```hcl
# Example: Update events POST method to require authorization
resource "aws_api_gateway_method" "events_post" {
  rest_api_id   = aws_api_gateway_rest_api.efy_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}
```

### 5. Database Schema Updates

#### New Tables Required:
1. **Users Table**: Store user profiles and metadata
2. **Permissions Table**: Store role-based permissions
3. **User Sessions Table**: Track active sessions (optional)
4. **Volunteer Tasks Table**: Store volunteer task assignments
5. **Volunteer Applications Table**: Store volunteer applications

#### Volunteer Tasks Table Schema:
```json
{
  "pk": "TASK#task_123",
  "sk": "VOLUNTEER#vol_456",
  "taskId": "task_123",
  "volunteerId": "vol_456",
  "eventId": "event_789",
  "taskType": "registration_desk",
  "status": "assigned", // assigned, in_progress, completed, cancelled
  "assignedAt": "2024-01-25T10:30:00Z",
  "completedAt": null,
  "notes": "Help with registration desk from 2-4 PM",
  "createdBy": "admin_user_id",
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:30:00Z"
}
```

#### Volunteer Applications Table Schema:
```json
{
  "pk": "APPLICATION#app_123",
  "sk": "VOLUNTEER#vol_456",
  "applicationId": "app_123",
  "volunteerId": "vol_456",
  "eventId": "event_789",
  "status": "pending", // pending, approved, rejected, assigned
  "preferredRoles": ["registration_desk", "usher"],
  "availability": "Weekends and evenings",
  "experience": "Volunteered at local mosque events",
  "motivation": "Want to contribute to Islamic education",
  "appliedAt": "2024-01-25T10:00:00Z",
  "reviewedAt": null,
  "reviewedBy": null,
  "notes": null
}
```

#### Existing Table Updates:
- **Events**: Add `createdBy`, `updatedBy` fields
- **Competitions**: Add `createdBy`, `updatedBy` fields
- **Courses**: Add `createdBy`, `updatedBy`, `instructorId` fields
- **Registrations**: Add `userId` field (link to Cognito user)
- **Messages**: Add `userId` field
- **Suggestions**: Add `userId` field
- **Volunteers**: Add `userId` field (link to Cognito user)

### 6. New API Endpoints for Volunteers

#### Volunteer Management Endpoints:
```
POST   /volunteers/apply          # Apply for volunteer position
GET    /volunteers/applications   # Get volunteer applications (admin)
PUT    /volunteers/applications/{id} # Update application status
GET    /volunteers/tasks          # Get assigned tasks (volunteer)
PUT    /volunteers/tasks/{id}     # Update task status
POST   /volunteers/tasks          # Create task (admin)
GET    /volunteers/reports        # Get volunteer reports
POST   /volunteers/reports        # Submit volunteer report
```

### 7. Migration Strategy

#### Data Migration Plan:
1. **Backup existing data** before migration
2. **Create Cognito users** for existing registrations
3. **Update existing records** with user associations
4. **Create volunteer users** for existing volunteer records
5. **Test thoroughly** before switching to authenticated mode
6. **Gradual rollout** with feature flags

#### Migration Scripts:
```bash
# scripts/migrate_to_cognito.sh
#!/bin/bash
# 1. Export existing data
# 2. Create Cognito users
# 3. Update DynamoDB records
# 4. Create volunteer-specific data
# 5. Verify data integrity
```

## 🔧 Implementation Steps

### Step 1: Create Cognito Infrastructure
```bash
# Create new Terraform module
mkdir -p terraform/modules/cognito
touch terraform/modules/cognito/{main.tf,variables.tf,outputs.tf,README.md}

# Add module to main.tf
module "cognito" {
  source = "./modules/cognito"
  # ... configuration
}
```

### Step 2: Create Authentication Middleware
```bash
# Add auth utilities to utility layer
touch layers/utility/nodejs/auth.js
touch layers/utility/nodejs/permissions.js

# Install required dependencies
cd layers/dependencies/nodejs
npm install jsonwebtoken jwks-rsa
```

### Step 3: Update API Gateway
```bash
# Update existing API Gateway methods
# Change authorization from "NONE" to "COGNITO_USER_POOLS"
# Add Cognito authorizer to all protected endpoints
```

### Step 4: Update Lambda Functions
```bash
# Add authentication middleware to each Lambda function
# Update business logic to use user context
# Add permission checks where needed
```

### Step 5: Create Permission Management
```bash
# Create DynamoDB permission table
# Populate with role-based permissions
# Create permission checking utilities
```

### Step 6: Create Volunteer-Specific Functions
```bash
# Create new Lambda functions for volunteer management
mkdir -p lambda_functions/volunteers_apply
mkdir -p lambda_functions/volunteers_tasks_get
mkdir -p lambda_functions/volunteers_tasks_post
mkdir -p lambda_functions/volunteers_tasks_put
mkdir -p lambda_functions/volunteers_reports_get
mkdir -p lambda_functions/volunteers_reports_post
```

### Step 7: Testing and Validation
```bash
# Test with different user roles
# Validate permission enforcement
# Test volunteer-specific functionality
# Performance testing
# Security testing
```

## 🛡️ Security Considerations

### JWT Token Security
- **Token Expiration**: Set appropriate expiration times
- **Token Refresh**: Implement refresh token mechanism
- **Token Validation**: Validate signature, issuer, audience
- **Token Storage**: Secure storage in frontend

### API Security
- **HTTPS Only**: All API calls must use HTTPS
- **CORS Configuration**: Restrict to trusted domains
- **Rate Limiting**: Implement API rate limiting
- **Input Validation**: Validate all inputs

### Data Security
- **Encryption**: Encrypt sensitive data at rest
- **Access Logging**: Log all access attempts
- **Audit Trail**: Maintain audit logs for admin actions
- **Data Retention**: Implement data retention policies

### Volunteer Data Privacy
- **Personal Information**: Secure storage of volunteer contact details
- **Task Assignments**: Ensure volunteers only see their own tasks
- **Application Data**: Protect volunteer application information
- **Reporting**: Secure volunteer report submissions

## 📈 Monitoring and Logging

### CloudWatch Metrics
- **Authentication Success/Failure Rates**
- **Permission Denial Rates**
- **API Response Times**
- **Error Rates by Endpoint**
- **Volunteer Activity Metrics**

### CloudWatch Logs
- **Authentication Events**
- **Permission Check Events**
- **User Activity Logs**
- **Security Event Logs**
- **Volunteer Task Management Logs**

### Alerts
- **High Authentication Failure Rate**
- **Unusual Permission Denial Patterns**
- **API Performance Degradation**
- **Security Anomalies**
- **Volunteer Task Assignment Issues**

## 📈 Testing Strategy

### Unit Tests
- **JWT Token Validation**
- **Permission Checking Logic**
- **User Context Extraction**
- **Error Handling**
- **Volunteer Permission Logic**

### Integration Tests
- **End-to-End Authentication Flow**
- **Role-Based Access Control**
- **API Endpoint Authorization**
- **Database Permission Queries**
- **Volunteer Task Management Flow**

### Security Tests
- **Token Tampering Detection**
- **Permission Bypass Attempts**
- **Unauthorized Access Attempts**
- **Session Hijacking Prevention**
- **Volunteer Data Access Control**

## 📈 Performance Considerations

### Caching Strategy
- **Permission Cache**: Cache user permissions in memory
- **JWT Cache**: Cache validated JWT tokens
- **User Info Cache**: Cache user profile information
- **CDN**: Use CloudFront for static assets
- **Volunteer Task Cache**: Cache volunteer task assignments

### Optimization Techniques
- **Connection Pooling**: Reuse database connections
- **Batch Operations**: Batch permission checks
- **Async Processing**: Use async/await for I/O operations
- **Lambda Warm-up**: Keep Lambda functions warm
- **Volunteer Data Indexing**: Optimize volunteer queries

## 🚀 Deployment Strategy

### Blue-Green Deployment
1. **Deploy new infrastructure** alongside existing
2. **Test thoroughly** with new authentication
3. **Switch traffic** to new authenticated endpoints
4. **Monitor closely** for issues
5. **Rollback plan** if needed

### Feature Flags
- **Authentication Toggle**: Enable/disable authentication per environment
- **Permission Toggle**: Enable/disable specific permissions
- **Role Toggle**: Enable/disable specific roles
- **Volunteer Features**: Enable/disable volunteer-specific features

### Gradual Rollout
1. **Start with read-only endpoints**
2. **Add authentication to write endpoints**
3. **Enable volunteer management features**
4. **Enable admin-only endpoints**
5. **Full authentication rollout**

## 📝 Next Steps

### Immediate Actions (Week 1-2)
1. **Create Cognito Terraform module**
2. **Set up development environment**
3. **Create authentication middleware**
4. **Test basic authentication flow**
5. **Design volunteer data models**

### Short Term (Week 3-4)
1. **Implement permission system**
2. **Update API Gateway configuration**
3. **Migrate existing Lambda functions**
4. **Create migration scripts**
5. **Implement volunteer management functions**

### Medium Term (Week 5-6)
1. **Complete data migration**
2. **Implement monitoring and logging**
3. **Security testing and validation**
4. **Performance optimization**
5. **Volunteer feature testing**

### Long Term (Week 7-8)
1. **Production deployment**
2. **User training and documentation**
3. **Ongoing monitoring and maintenance**
4. **Feature enhancements and improvements**
5. **Volunteer onboarding process**

## 🔗 Related Documentation

- [Amazon Cognito Developer Guide](https://docs.aws.amazon.com/cognito/)
- [API Gateway Authorization](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-authorization.html)
- [JWT Token Validation](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📞 Support and Resources

### Internal Resources
- **Infrastructure Team**: For Terraform and AWS setup
- **Development Team**: For Lambda function updates
- **Security Team**: For security review and validation
- **Volunteer Management Team**: For volunteer feature requirements

### External Resources
- **AWS Support**: For Cognito and API Gateway issues
- **Terraform Community**: For infrastructure questions
- **Security Consultants**: For security audit and validation

---

**Document Version**: 1.1  
**Last Updated**: January 2024  
**Next Review**: February 2024  
**Approved By**: Infrastructure Team
```

The key changes I made to include volunteers as a 4th user type:

1. **Updated Overview**: Changed from "Three user types" to "Four user types"

2. **Enhanced Role Hierarchy**: Added a complete Volunteer role with specific responsibilities

3. **Updated Permission Matrix**: Added a Volunteer column with appropriate permissions, including:
   - Volunteer-specific permissions (own data access)
   - Volunteer task management
   - Volunteer application handling

4. **New Database Tables**: Added schemas for:
   - Volunteer Tasks Table
   - Volunteer Applications Table

5. **New API Endpoints**: Added volunteer management endpoints

6. **Enhanced Security**: Added volunteer data privacy considerations

7. **Updated Implementation Steps**: Added volunteer-specific Lambda functions

8. **Enhanced Testing**: Added volunteer-specific testing scenarios

9. **Updated Timeline**: Included volunteer feature development in the roadmap

This approach gives volunteers their own distinct role with appropriate permissions while maintaining clear boundaries with other user types, making the system more scalable and maintainable.
