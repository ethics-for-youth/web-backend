# RBAC Implementation Testing and Validation Guide

This guide provides comprehensive testing procedures for validating the Amazon Cognito RBAC implementation.

## 📋 Pre-Testing Checklist

### Infrastructure Validation
- [ ] ✅ Cognito User Pool created and configured
- [ ] ✅ Cognito Identity Pool created with role mappings
- [ ] ✅ IAM roles created for each user type (student, teacher, volunteer, admin)
- [ ] ✅ DynamoDB tables created (permissions, users, volunteer_tasks, volunteer_applications)
- [ ] ✅ Lambda functions updated with authentication middleware
- [ ] ✅ API Gateway has Cognito authorizer (optional - can be enabled later)

### Code Validation
- [ ] ✅ Authentication middleware deployed to utility layer
- [ ] ✅ Permission management system deployed
- [ ] ✅ Lambda functions have required environment variables
- [ ] ✅ Database migration script ready

### Environment Configuration
```bash
# Check these environment variables are set in Lambda functions
COGNITO_USER_POOL_ID=your-user-pool-id
COGNITO_USER_POOL_CLIENT_ID=your-client-id  
PERMISSIONS_TABLE_NAME=efy-dev-permissions
ENABLE_AUTH=false  # Set to true when ready to test
```

## 🚀 Deployment Testing

### 1. Infrastructure Deployment
```bash
# Validate Terraform configuration
cd terraform
terraform validate

# Plan deployment (review changes carefully)
terraform plan -var-file="terraform.dev.tfvars"

# Apply changes
terraform apply -var-file="terraform.dev.tfvars"
```

**Expected Outputs:**
- Cognito User Pool ID
- Cognito User Pool Client ID  
- Identity Pool ID
- API Gateway URL
- Lambda function ARNs

### 2. Database Migration
```bash
# Install migration script dependencies
cd scripts
npm install

# Run migration for development
npm run migrate:dev
```

**Expected Results:**
- ✅ System users created in Users table
- ✅ Existing records updated with user associations
- ✅ Permissions table populated with RBAC rules
- ✅ Migration summary shows counts of migrated items

### 3. Permission Seeding Validation
```bash
# Check permissions table content
aws dynamodb scan --table-name efy-dev-permissions --max-items 10
```

**Expected Content:**
- Student permissions for read-only access
- Teacher permissions for course management
- Volunteer permissions for task and application management
- Admin permissions for full system access

## 🔧 Functional Testing

### Phase 1: Authentication Disabled (Backward Compatibility)

Test that existing functionality works with `ENABLE_AUTH=false`:

```bash
# Test existing endpoints still work
curl -X GET "https://your-api-gateway-url/dev/events"
curl -X GET "https://your-api-gateway-url/dev/courses"
curl -X GET "https://your-api-gateway-url/dev/competitions"
```

**Expected Results:**
- ✅ All GET endpoints return data successfully
- ✅ No authentication errors
- ✅ Existing functionality unchanged

### Phase 2: Cognito User Creation

Create test users in Cognito User Pool:

1. **Admin User**
   - Email: `admin@test.efy.com`
   - Role: Admin
   - Groups: `admin`

2. **Teacher User**
   - Email: `teacher@test.efy.com`
   - Role: Teacher
   - Groups: `teacher`

3. **Volunteer User**
   - Email: `volunteer@test.efy.com`
   - Role: Volunteer
   - Groups: `volunteer`

4. **Student User**
   - Email: `student@test.efy.com`
   - Role: Student
   - Groups: `student`

### Phase 3: JWT Token Testing

#### Get JWT Tokens
```javascript
// Use AWS SDK or Cognito client to authenticate users
const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

const authResult = await cognito.adminInitiateAuth({
    UserPoolId: 'your-user-pool-id',
    ClientId: 'your-client-id',
    AuthFlow: 'ADMIN_NO_SRP_AUTH',
    AuthParameters: {
        USERNAME: 'admin@test.efy.com',
        PASSWORD: 'TempPassword123!'
    }
}).promise();

const accessToken = authResult.AuthenticationResult.AccessToken;
```

#### Token Validation Test
```bash
# Test JWT decoding (use jwt.io or custom script)
node -e "
const jwt = require('jsonwebtoken');
const token = 'YOUR_JWT_TOKEN';
console.log(jwt.decode(token, { complete: true }));
"
```

**Expected Token Content:**
- `sub`: Cognito user ID
- `cognito:groups`: User's assigned groups
- `email`: User's email address
- `token_use`: "access"

### Phase 4: Authentication Enabled Testing

Enable authentication by setting `ENABLE_AUTH=true` in Lambda environment variables.

#### Admin User Tests
```bash
ADMIN_TOKEN="your-admin-jwt-token"

# Should succeed - Admin can create events
curl -X POST "https://your-api-gateway-url/dev/events" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Event",
    "description": "Admin created event",
    "date": "2024-03-15T19:00:00Z",
    "location": "Test Location"
  }'

# Should succeed - Admin can view all data
curl -X GET "https://your-api-gateway-url/dev/admin/stats" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

#### Teacher User Tests
```bash
TEACHER_TOKEN="your-teacher-jwt-token"

# Should succeed - Teachers can create courses
curl -X POST "https://your-api-gateway-url/dev/courses" \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Course", 
    "description": "Teacher created course",
    "duration": "4 weeks"
  }'

# Should fail - Teachers cannot create events
curl -X POST "https://your-api-gateway-url/dev/events" \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Unauthorized Event"}'
```

**Expected Result**: 403 Forbidden

#### Volunteer User Tests
```bash
VOLUNTEER_TOKEN="your-volunteer-jwt-token"

# Should succeed - Volunteers can view their tasks
curl -X GET "https://your-api-gateway-url/dev/volunteers/tasks" \
  -H "Authorization: Bearer $VOLUNTEER_TOKEN"

# Should succeed - Volunteers can update their task status
curl -X PUT "https://your-api-gateway-url/dev/volunteers/tasks/task_123" \
  -H "Authorization: Bearer $VOLUNTEER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "notes": "Task completed successfully"
  }'

# Should fail - Volunteers cannot create events
curl -X POST "https://your-api-gateway-url/dev/events" \
  -H "Authorization: Bearer $VOLUNTEER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Unauthorized Event"}'
```

#### Student User Tests
```bash
STUDENT_TOKEN="your-student-jwt-token"

# Should succeed - Students can view public content
curl -X GET "https://your-api-gateway-url/dev/events" \
  -H "Authorization: Bearer $STUDENT_TOKEN"

# Should succeed - Students can register for events
curl -X POST "https://your-api-gateway-url/dev/registrations" \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "event_123",
    "participantName": "Test Student"
  }'

# Should fail - Students cannot create courses
curl -X POST "https://your-api-gateway-url/dev/courses" \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Unauthorized Course"}'
```

### Phase 5: Error Handling Tests

#### Missing Token Test
```bash
# Should return 401 Unauthorized
curl -X POST "https://your-api-gateway-url/dev/events" \
  -H "Content-Type: application/json" \
  -d '{"title": "No Token Event"}'
```

#### Invalid Token Test
```bash
# Should return 401 Unauthorized
curl -X GET "https://your-api-gateway-url/dev/events" \
  -H "Authorization: Bearer invalid_token_here"
```

#### Expired Token Test
```bash
# Use an expired JWT token - Should return 401 Unauthorized
curl -X GET "https://your-api-gateway-url/dev/events" \
  -H "Authorization: Bearer $EXPIRED_TOKEN"
```

## 🧪 Automated Testing Scripts

### Create Test Script
```bash
# scripts/test_rbac.sh
#!/bin/bash

API_URL="https://your-api-gateway-url/dev"
ADMIN_TOKEN="admin-jwt-token"
TEACHER_TOKEN="teacher-jwt-token" 
VOLUNTEER_TOKEN="volunteer-jwt-token"
STUDENT_TOKEN="student-jwt-token"

echo "🧪 Starting RBAC Tests..."

# Test 1: Admin permissions
echo "Testing admin permissions..."
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/events" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Event","description":"Admin test","date":"2024-03-15T19:00:00Z","location":"Test"}')

if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
  echo "✅ Admin can create events"
else
  echo "❌ Admin cannot create events (HTTP $response)"
fi

# Test 2: Student restrictions
echo "Testing student restrictions..."
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/events" \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Unauthorized Event"}')

if [ "$response" -eq 403 ]; then
  echo "✅ Student correctly blocked from creating events"
else
  echo "❌ Student should not be able to create events (HTTP $response)"
fi

# Add more tests...
echo "🎉 RBAC tests completed"
```

## 📊 Performance Testing

### Load Testing
```javascript
// scripts/load_test.js
const https = require('https');

async function loadTest(endpoint, token, iterations = 100) {
    console.log(`Load testing ${endpoint} with ${iterations} requests...`);
    
    const promises = [];
    for (let i = 0; i < iterations; i++) {
        promises.push(makeRequest(endpoint, token));
    }
    
    const start = Date.now();
    const results = await Promise.allSettled(promises);
    const duration = Date.now() - start;
    
    const successful = results.filter(r => r.status === 'fulfilled').length;
    const failed = results.filter(r => r.status === 'rejected').length;
    
    console.log(`Results: ${successful} successful, ${failed} failed`);
    console.log(`Total time: ${duration}ms, Average: ${duration/iterations}ms per request`);
}
```

### Memory and CPU Testing
Monitor CloudWatch metrics for:
- Lambda function duration
- Memory utilization
- Error rates
- Throttling events

## 🔍 Security Testing

### SQL Injection Tests
Test that authentication middleware properly validates JWT tokens and doesn't allow injection attacks.

### Token Manipulation Tests
- Test with modified JWT payloads
- Test with different signing algorithms
- Test with missing claims

### Permission Escalation Tests
- Attempt to access resources with insufficient permissions
- Test ownership-based access controls
- Validate role-based restrictions

## 📈 Monitoring and Alerting

Set up CloudWatch alarms for:
- Authentication failure rates > 10%
- Authorization failure rates > 15%
- Lambda function errors > 1%
- API Gateway 4xx/5xx rates

## ✅ Test Results Validation

### Success Criteria
- [ ] All infrastructure deployed successfully
- [ ] Database migration completed without errors
- [ ] JWT tokens generated and validated correctly
- [ ] Role-based permissions enforced properly
- [ ] Backward compatibility maintained
- [ ] Performance within acceptable limits
- [ ] Security controls working as expected
- [ ] Error handling provides appropriate responses
- [ ] Monitoring and logging functional

### Common Issues and Solutions

#### Issue: JWT Validation Fails
**Solution**: Verify JWKS URI is accessible and Cognito User Pool ID is correct

#### Issue: Permission Denied Errors
**Solution**: Check permission seeding and user group assignments

#### Issue: Lambda Timeout Errors
**Solution**: Review authentication middleware performance, consider caching

#### Issue: DynamoDB Throttling
**Solution**: Check read/write capacity settings, implement exponential backoff

## 📝 Test Documentation

Document all test results including:
- Test execution dates
- Pass/fail results for each test case
- Performance benchmarks
- Security validation results
- Any issues found and resolutions
- Recommendations for production deployment

## 🚀 Production Readiness Checklist

Before enabling authentication in production:
- [ ] All tests passing in QA environment
- [ ] Performance benchmarks meet requirements
- [ ] Security review completed
- [ ] Monitoring and alerting configured
- [ ] Rollback plan documented and tested
- [ ] User training completed
- [ ] Support documentation updated