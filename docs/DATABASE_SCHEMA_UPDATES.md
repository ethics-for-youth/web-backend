# Database Schema Updates for RBAC Implementation

This document outlines the database schema changes required to support role-based authentication and user associations.

## Overview

The RBAC implementation requires updating existing tables to track user associations and creating new tables for permission management and volunteer features.

## New Tables

### 1. Permissions Table
**Purpose**: Store role-based permissions for fine-grained access control

```javascript
// Table: efy-{environment}-permissions
{
  "pk": "PERMISSION#resource:action",     // Partition Key
  "sk": "ROLE#role_name",                 // Sort Key  
  "resource": "events",                   // Resource name
  "action": "read",                       // Action (read, create, update, delete)
  "role": "student",                      // Role name
  "allowed": true,                        // Permission granted
  "conditions": {                         // Optional conditions
    "public": true,                       // Resource is public
    "own_only": true,                     // User can only access own resources
    "assigned_only": true                 // Volunteer can only access assigned resources
  },
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

**Indexes**:
- ResourceIndex: GSI on resource + role
- RoleIndex: GSI on role + resource

### 2. Users Table
**Purpose**: Store Cognito user mappings and metadata

```javascript
// Table: efy-{environment}-users
{
  "userId": "cognito-user-id",            // Partition Key (Cognito sub)
  "email": "user@example.com",
  "username": "john_doe",
  "role": "student",                      // Primary role
  "fullName": "John Doe",
  "organization": "Local Mosque",
  "phoneNumber": "+1234567890",
  "status": "active",                     // active, inactive, suspended
  "cognitoStatus": "CONFIRMED",           // Cognito user status
  "isSystemUser": false,                  // System vs regular user
  "lastLoginAt": "2024-01-25T10:00:00Z",
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

**Indexes**:
- EmailIndex: GSI on email
- RoleIndex: GSI on role

### 3. Volunteer Tasks Table
**Purpose**: Store volunteer task assignments and tracking

```javascript
// Table: efy-{environment}-volunteer-tasks
{
  "pk": "TASK#task_123",                  // Partition Key
  "sk": "VOLUNTEER#vol_456",              // Sort Key
  "taskId": "task_123",
  "volunteerId": "vol_456",               // Links to Users table
  "eventId": "event_789",                 // Links to Events table
  "taskType": "registration_desk",        // Task category
  "description": "Help with registration desk from 2-4 PM",
  "status": "assigned",                   // assigned, in_progress, completed, cancelled
  "priority": "medium",                   // low, medium, high
  "scheduledStart": "2024-01-25T14:00:00Z",
  "scheduledEnd": "2024-01-25T16:00:00Z",
  "location": "Main Entrance",
  "requirements": ["ID verification", "Computer skills"],
  "notes": "Please arrive 15 minutes early",
  "assignedAt": "2024-01-25T10:30:00Z",
  "assignedBy": "admin_user_id",
  "assignedByEmail": "admin@efy.com",
  "completedAt": null,
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:30:00Z"
}
```

**Indexes**:
- VolunteerIndex: GSI on volunteerId + status
- EventIndex: GSI on eventId + status

### 4. Volunteer Applications Table
**Purpose**: Store volunteer applications for events

```javascript
// Table: efy-{environment}-volunteer-applications
{
  "pk": "APPLICATION#app_123",            // Partition Key
  "sk": "VOLUNTEER#vol_456",              // Sort Key
  "applicationId": "app_123",
  "volunteerId": "vol_456",               // Links to Users table
  "eventId": "event_789",                 // Links to Events table
  "status": "pending",                    // pending, approved, rejected, assigned
  "preferredRoles": ["registration_desk", "usher"],
  "availability": "Weekends and evenings",
  "experience": "Volunteered at local mosque events",
  "motivation": "Want to contribute to Islamic education",
  "skillSet": ["Communication", "Organization"],
  "emergencyContact": {
    "name": "Jane Doe",
    "phone": "+1234567890",
    "relationship": "spouse"
  },
  "appliedAt": "2024-01-25T10:00:00Z",
  "reviewedAt": null,
  "reviewedBy": null,
  "reviewNotes": null
}
```

**Indexes**:
- VolunteerIndex: GSI on volunteerId + status
- EventIndex: GSI on eventId + status

## Updated Existing Tables

### Events Table Updates
**Before**:
```javascript
{
  "id": "event_123",
  "title": "Islamic History Workshop",
  "description": "Learn about Islamic history",
  "date": "2024-02-15T19:00:00Z",
  "location": "Community Center",
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

**After**:
```javascript
{
  "id": "event_123",
  "title": "Islamic History Workshop",
  "description": "Learn about Islamic history", 
  "date": "2024-02-15T19:00:00Z",
  "location": "Community Center",
  // NEW FIELDS
  "createdBy": "admin_user_id",           // User who created the event
  "createdByEmail": "admin@efy.com",      // Email for display purposes
  "updatedBy": "admin_user_id",           // User who last updated
  "updatedByEmail": "admin@efy.com",      // Email for display purposes
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

### Competitions Table Updates
Same pattern as Events table with `createdBy`, `createdByEmail`, `updatedBy`, `updatedByEmail` fields.

### Courses Table Updates
**Before**:
```javascript
{
  "id": "course_123",
  "title": "Arabic Language Basics",
  "description": "Introduction to Arabic language",
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

**After**:
```javascript
{
  "id": "course_123", 
  "title": "Arabic Language Basics",
  "description": "Introduction to Arabic language",
  // NEW FIELDS
  "createdBy": "teacher_user_id",         // User who created the course
  "createdByEmail": "teacher@efy.com",
  "updatedBy": "teacher_user_id",         // User who last updated
  "updatedByEmail": "teacher@efy.com",
  "instructorId": "teacher_user_id",      // Course instructor
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

### Registrations Table Updates
**Before**:
```javascript
{
  "id": "reg_123",
  "eventId": "event_123",
  "participantName": "John Doe",
  "participantEmail": "john@example.com",
  "createdAt": "2024-01-25T10:00:00Z"
}
```

**After**:
```javascript
{
  "id": "reg_123",
  "eventId": "event_123", 
  "participantName": "John Doe",
  "participantEmail": "john@example.com",
  // NEW FIELD
  "userId": "john_cognito_id",            // Links to authenticated user
  "createdAt": "2024-01-25T10:00:00Z"
}
```

### Messages Table Updates
**Before**:
```javascript
{
  "id": "msg_123",
  "subject": "Question about event",
  "message": "When will the event start?",
  "senderName": "John Doe",
  "senderEmail": "john@example.com",
  "createdAt": "2024-01-25T10:00:00Z"
}
```

**After**:
```javascript
{
  "id": "msg_123",
  "subject": "Question about event", 
  "message": "When will the event start?",
  "senderName": "John Doe",
  "senderEmail": "john@example.com",
  // NEW FIELDS
  "userId": "john_cognito_id",            // Links to authenticated user
  "createdBy": "john_cognito_id",
  "createdByEmail": "john@example.com",
  "createdAt": "2024-01-25T10:00:00Z"
}
```

### Suggestions Table Updates
Similar to Messages table with `userId`, `createdBy`, `createdByEmail` fields.

### Volunteers Table Updates
**Before**:
```javascript
{
  "id": "vol_123",
  "name": "Jane Smith",
  "email": "jane@example.com",
  "phone": "+1234567890",
  "experience": "Event management",
  "createdAt": "2024-01-25T10:00:00Z"
}
```

**After**:
```javascript
{
  "id": "vol_123",
  "name": "Jane Smith",
  "email": "jane@example.com", 
  "phone": "+1234567890",
  "experience": "Event management",
  // NEW FIELDS
  "userId": "jane_cognito_id",            // Links to authenticated user
  "createdBy": "jane_cognito_id",
  "createdByEmail": "jane@example.com",
  "updatedBy": "admin_user_id",
  "updatedByEmail": "admin@efy.com",
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T12:00:00Z"
}
```

## Migration Process

### 1. Preparation
- Backup all existing tables
- Ensure new tables are created via Terraform
- Test migration script in development environment

### 2. Migration Script Execution
```bash
# Development environment
node scripts/migrate_user_associations.js dev

# QA environment  
node scripts/migrate_user_associations.js qa

# Production environment (with extra care)
node scripts/migrate_user_associations.js prod
```

### 3. Post-Migration Steps
1. **Create Admin Users**: Use Cognito console to create initial admin users
2. **Seed Permissions**: Run permissions seeding to populate RBAC rules
3. **Test Authentication**: Verify auth middleware works with real tokens
4. **Enable Authentication**: Set `ENABLE_AUTH=true` in Lambda environment variables
5. **Update API Gateway**: Enable Cognito authorizer for protected endpoints

### 4. Validation
- Verify all existing records have new user association fields
- Confirm new tables are populated with correct permissions
- Test API endpoints with different user roles
- Validate volunteer-specific functionality

## System User Defaults

For backward compatibility and system operations, default values are used:

```javascript
// Default system user for migrated records
const SYSTEM_DEFAULTS = {
  createdBy: 'system',
  createdByEmail: 'system@efy.com',
  updatedBy: 'system', 
  updatedByEmail: 'system@efy.com',
  userId: 'system'  // For user-linked records
};
```

## Rollback Plan

If migration needs to be rolled back:

1. **Remove New Fields**: Update Lambda functions to not expect new fields
2. **Revert Code Changes**: Deploy previous version without auth middleware
3. **Database Cleanup**: Optionally remove new user association fields
4. **Table Restoration**: Restore from backups if needed

## Performance Considerations

- **Batch Operations**: Migration script processes items in batches
- **Rate Limiting**: Built-in delays to avoid DynamoDB throttling
- **Indexing**: New GSI indexes may take time to build
- **Read/Write Capacity**: Monitor and adjust capacity during migration

## Security Implications

- **Data Integrity**: All user associations are properly linked
- **Access Control**: RBAC rules prevent unauthorized access
- **Audit Trail**: Complete tracking of who created/modified what
- **System Security**: Default system user for non-attributed actions