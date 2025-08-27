const { DynamoDBDocumentClient, PutCommand, BatchWriteCommand } = require('@aws-sdk/lib-dynamodb');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');

class PermissionsManager {
  constructor(region, permissionsTableName) {
    this.permissionsTableName = permissionsTableName;
    const dynamoClient = new DynamoDBClient({ region });
    this.dynamoDb = DynamoDBDocumentClient.from(dynamoClient);
  }

  async seedPermissions() {
    const permissions = this.getDefaultPermissions();
    const batchRequests = [];

    for (const permission of permissions) {
      batchRequests.push({
        PutRequest: {
          Item: permission
        }
      });

      if (batchRequests.length === 25) {
        await this.batchWritePermissions(batchRequests);
        batchRequests.length = 0;
      }
    }

    if (batchRequests.length > 0) {
      await this.batchWritePermissions(batchRequests);
    }
  }

  async batchWritePermissions(requests) {
    const params = {
      RequestItems: {
        [this.permissionsTableName]: requests
      }
    };

    try {
      await this.dynamoDb.send(new BatchWriteCommand(params));
    } catch (error) {
      console.error('Error writing permissions batch:', error);
      throw error;
    }
  }

  getDefaultPermissions() {
    const permissions = [];
    const roles = ['student', 'teacher', 'volunteer', 'admin'];
    const resources = [
      { name: 'events', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'competitions', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'courses', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'registrations', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'suggestions', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'messages', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'volunteers', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'volunteer_tasks', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'volunteer_applications', actions: ['read', 'create', 'update', 'delete'] },
      { name: 'admin_stats', actions: ['read'] },
      { name: 'payments', actions: ['create', 'webhook'] }
    ];

    for (const resource of resources) {
      for (const action of resource.actions) {
        for (const role of roles) {
          const permission = this.createPermission(resource.name, action, role);
          if (permission) {
            permissions.push(permission);
          }
        }
      }
    }

    return permissions;
  }

  createPermission(resource, action, role) {
    const permissionKey = `PERMISSION#${resource}:${action}`;
    const roleKey = `ROLE#${role}`;

    let allowed = false;
    let conditions = {};

    switch (role) {
      case 'admin':
        allowed = true;
        break;

      case 'teacher':
        switch (resource) {
          case 'events':
          case 'competitions':
          case 'suggestions':
          case 'messages':
            allowed = action === 'read' || action === 'create';
            conditions = action === 'read' ? { public: true } : {};
            break;
          case 'courses':
            allowed = ['read', 'create', 'update', 'delete'].includes(action);
            conditions = action === 'read' ? { public: true } : { own_only: true };
            break;
          case 'registrations':
            allowed = action === 'read';
            conditions = { course_instructor: true };
            break;
        }
        break;

      case 'volunteer':
        switch (resource) {
          case 'events':
          case 'competitions':
          case 'courses':
          case 'suggestions':
          case 'messages':
            allowed = action === 'read' || action === 'create';
            conditions = action === 'read' ? { public: true } : {};
            break;
          case 'registrations':
            allowed = ['read', 'create'].includes(action);
            conditions = action === 'read' ? { own_only: true } : {};
            break;
          case 'volunteers':
            allowed = ['read', 'update'].includes(action);
            conditions = { own_only: true };
            break;
          case 'volunteer_tasks':
            allowed = ['read', 'update'].includes(action);
            conditions = { assigned_only: true };
            break;
          case 'volunteer_applications':
            allowed = ['read', 'create'].includes(action);
            conditions = action === 'read' ? { own_only: true } : {};
            break;
          case 'payments':
            allowed = action === 'create';
            break;
        }
        break;

      case 'student':
        switch (resource) {
          case 'events':
          case 'competitions':
          case 'courses':
          case 'suggestions':
          case 'messages':
            allowed = action === 'read' || action === 'create';
            conditions = action === 'read' ? { public: true } : {};
            break;
          case 'registrations':
            allowed = ['read', 'create'].includes(action);
            conditions = action === 'read' ? { own_only: true } : {};
            break;
          case 'volunteer_applications':
            allowed = action === 'create';
            break;
          case 'payments':
            allowed = action === 'create';
            break;
        }
        break;
    }

    if (!allowed) {
      return null;
    }

    return {
      pk: permissionKey,
      sk: roleKey,
      resource,
      action,
      role,
      allowed,
      conditions,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  }

  async createPermission(resource, action, role, allowed = true, conditions = {}) {
    const permission = {
      pk: `PERMISSION#${resource}:${action}`,
      sk: `ROLE#${role}`,
      resource,
      action,
      role,
      allowed,
      conditions,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const params = {
      TableName: this.permissionsTableName,
      Item: permission
    };

    try {
      await this.dynamoDb.send(new PutCommand(params));
      return permission;
    } catch (error) {
      console.error('Error creating permission:', error);
      throw error;
    }
  }
}

module.exports = {
  PermissionsManager
};