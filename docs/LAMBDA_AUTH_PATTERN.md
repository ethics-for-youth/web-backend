# Lambda Function Authentication Pattern

This document provides the standard pattern for adding authentication to existing Lambda functions.

## Environment Variables Required

Each Lambda function that uses authentication needs these environment variables:

```javascript
// In Terraform main.tf
environment_variables = {
  // Existing variables...
  COGNITO_USER_POOL_ID     = module.cognito.user_pool_id
  COGNITO_USER_POOL_CLIENT_ID = module.cognito.user_pool_client_id  
  PERMISSIONS_TABLE_NAME   = module.dynamodb.permissions_table_name
  ENABLE_AUTH              = "false"  // Set to "true" to enable
}

// DynamoDB permissions
dynamodb_table_arns = [
  // Existing table ARNs...
  module.dynamodb.permissions_table_arn
]
```

## Lambda Function Code Pattern

### 1. Import Authentication Middleware

```javascript
const { successResponse, errorResponse, createAuthMiddleware } = require('/opt/nodejs/utils');

// Initialize auth middleware
const auth = createAuthMiddleware(
    process.env.COGNITO_USER_POOL_ID,
    process.env.AWS_REGION,
    process.env.PERMISSIONS_TABLE_NAME
);
```

### 2. Authentication Check (Standard Pattern)

```javascript
exports.handler = async (event) => {
    try {
        let authContext = null;

        // Skip authentication if disabled (backward compatibility)
        if (process.env.ENABLE_AUTH === 'true') {
            const authResult = await auth.authenticateRequest(event, 'resource_name', 'action_name');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated user:', authContext.email, 'Role:', authContext.role);
        }

        // Your existing business logic continues here...
    } catch (error) {
        // Error handling...
    }
};
```

### 3. Resource-Specific Patterns

#### GET Endpoints (Read Operations)
- Resource: Entity name (e.g., 'events', 'courses')
- Action: 'read'  
- Available to: All authenticated users

#### POST Endpoints (Create Operations)
- Resource: Entity name
- Action: 'create'
- Available to: Based on permission matrix (admin, teacher for courses, etc.)

#### PUT/PATCH Endpoints (Update Operations)  
- Resource: Entity name
- Action: 'update'
- Available to: Based on permission matrix + ownership checks

#### DELETE Endpoints (Delete Operations)
- Resource: Entity name  
- Action: 'delete'
- Available to: Usually admin only

#### User-Specific Operations
For operations that should be limited to the user's own data:

```javascript
// Extract resource ID for ownership check
const resourceIdExtractor = (event, user) => {
    // Return the resource ID to check ownership
    return event.pathParameters?.userId || event.pathParameters?.id;
};

const authResult = await auth.authenticateRequest(
    event, 
    'resource_name', 
    'action_name', 
    resourceIdExtractor
);
```

### 4. Adding Creator/Modifier Information

For create/update operations, add user context to the data:

```javascript
const itemData = {
    // Existing fields...
    createdBy: authContext ? authContext.userId : 'system',
    createdByEmail: authContext ? authContext.email : 'system@efy.com',
    updatedBy: authContext ? authContext.userId : 'system',
    updatedByEmail: authContext ? authContext.email : 'system@efy.com',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
};
```

## Permission Matrix Reference

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
| Volunteers (GET own) | ❌ | ❌ | ✅ | ✅ |
| Volunteers (POST/PUT own) | ✅ | ❌ | ✅ | ✅ |
| Admin Stats | ❌ | ❌ | ❌ | ✅ |
| Payments (Create Order) | ✅ | ❌ | ✅ | ✅ |
| Payments (Webhook) | ❌ | ❌ | ❌ | ✅ |

## Testing Authentication

### Without Authentication (Current State)
```bash
curl -X GET https://api.example.com/events
```

### With Authentication  
```bash
# Get Cognito token first, then:
curl -X GET https://api.example.com/events \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Expected Error Responses
- 401: Authentication failed (no/invalid token)
- 403: Authorization failed (insufficient permissions)

## Migration Strategy

1. **Update Lambda function code** with auth pattern
2. **Update Terraform configuration** with environment variables  
3. **Keep ENABLE_AUTH=false** for backward compatibility
4. **Test deployment** ensures existing functionality works
5. **Deploy and test** with authentication disabled
6. **Enable authentication** by setting ENABLE_AUTH=true
7. **Test with valid tokens** to ensure auth works
8. **Update API Gateway** to use Cognito authorizer (optional)

## Functions Updated So Far

- ✅ `events_get` - Read operations for all users
- ✅ `events_post` - Admin-only create operations
- ⏳ More functions to be updated following this pattern

## Next Steps

1. Update remaining Lambda functions following this pattern
2. Test authentication with actual Cognito tokens
3. Enable authentication globally by setting ENABLE_AUTH=true
4. Update API Gateway methods to use Cognito authorizer