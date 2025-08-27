const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');
const fetch = require('node-fetch');
const { DynamoDBDocumentClient, GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');

class AuthMiddleware {
  constructor(userPoolId, region, permissionsTableName = null) {
    this.userPoolId = userPoolId;
    this.region = region;
    this.permissionsTableName = permissionsTableName;
    
    this.client = jwksClient({
      jwksUri: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`,
      cache: true,
      rateLimit: true,
      jwksRequestsPerMinute: 5,
      jwksUri: `https://cognito-idp.${region}.amazonaws.com/${userPoolId}/.well-known/jwks.json`
    });

    if (permissionsTableName) {
      const dynamoClient = new DynamoDBClient({ region });
      this.dynamoDb = DynamoDBDocumentClient.from(dynamoClient);
    }
  }

  async getKey(header, callback) {
    this.client.getSigningKey(header.kid, (err, key) => {
      const signingKey = key.getPublicKey();
      callback(null, signingKey);
    });
  }

  async validateToken(token) {
    try {
      return new Promise((resolve, reject) => {
        jwt.verify(token, this.getKey.bind(this), {
          audience: process.env.COGNITO_USER_POOL_CLIENT_ID,
          issuer: `https://cognito-idp.${this.region}.amazonaws.com/${this.userPoolId}`,
          algorithms: ['RS256']
        }, (err, decoded) => {
          if (err) {
            reject(err);
          } else {
            resolve(decoded);
          }
        });
      });
    } catch (error) {
      throw new Error(`Token validation failed: ${error.message}`);
    }
  }

  async getUserInfo(token) {
    try {
      const decoded = await this.validateToken(token);
      
      return {
        userId: decoded.sub,
        email: decoded.email,
        username: decoded['cognito:username'],
        groups: decoded['cognito:groups'] || [],
        role: this.getPrimaryRole(decoded['cognito:groups'] || []),
        tokenUse: decoded.token_use,
        customAttributes: {
          role: decoded['custom:role'],
          organization: decoded['custom:organization']
        }
      };
    } catch (error) {
      throw new Error(`Failed to extract user info: ${error.message}`);
    }
  }

  getPrimaryRole(groups) {
    const roleHierarchy = ['admin', 'teacher', 'volunteer', 'student'];
    
    for (const role of roleHierarchy) {
      if (groups.includes(role)) {
        return role;
      }
    }
    
    return 'student';
  }

  async checkPermission(user, resource, action, resourceId = null) {
    if (!this.permissionsTableName) {
      return this.checkBasicRolePermission(user.role, resource, action);
    }

    try {
      const params = {
        TableName: this.permissionsTableName,
        Key: {
          pk: `PERMISSION#${resource}:${action}`,
          sk: `ROLE#${user.role}`
        }
      };

      const result = await this.dynamoDb.send(new GetCommand(params));

      if (!result.Item) {
        return false;
      }

      const permission = result.Item;
      
      if (!permission.allowed) {
        return false;
      }

      if (permission.conditions) {
        return this.checkPermissionConditions(permission.conditions, user, resourceId);
      }

      return true;
    } catch (error) {
      console.error('Permission check error:', error);
      return false;
    }
  }

  checkBasicRolePermission(role, resource, action) {
    const permissionMatrix = {
      admin: {
        '*': ['*']
      },
      teacher: {
        events: ['read'],
        competitions: ['read'],
        courses: ['read', 'create', 'update', 'delete'],
        registrations: ['read'],
        suggestions: ['read', 'create'],
        messages: ['read', 'create']
      },
      volunteer: {
        events: ['read'],
        competitions: ['read'],
        courses: ['read'],
        registrations: ['read', 'create'],
        suggestions: ['read', 'create'],
        messages: ['read', 'create'],
        volunteers: ['read', 'update'],
        volunteer_tasks: ['read', 'update'],
        volunteer_applications: ['read', 'create'],
        payments: ['create']
      },
      student: {
        events: ['read'],
        competitions: ['read'],
        courses: ['read'],
        registrations: ['read', 'create'],
        suggestions: ['read', 'create'],
        messages: ['read', 'create'],
        volunteer_applications: ['create'],
        payments: ['create']
      }
    };

    const rolePermissions = permissionMatrix[role];
    if (!rolePermissions) {
      return false;
    }

    if (rolePermissions['*'] && rolePermissions['*'].includes('*')) {
      return true;
    }

    const resourcePermissions = rolePermissions[resource];
    if (!resourcePermissions) {
      return false;
    }

    return resourcePermissions.includes(action) || resourcePermissions.includes('*');
  }

  checkPermissionConditions(conditions, user, resourceId) {
    if (conditions.public) {
      return true;
    }

    if (conditions.own_only && !resourceId) {
      return false;
    }

    if (conditions.own_only) {
      return resourceId === user.userId;
    }

    if (conditions.assigned_only && !resourceId) {
      return false;
    }

    return true;
  }

  async checkVolunteerPermission(user, resource, action, resourceId = null) {
    if (user.role !== 'volunteer' && user.role !== 'admin') {
      return false;
    }

    if (user.role === 'admin') {
      return true;
    }

    const volunteerPermissions = {
      volunteers: ['read', 'update'],
      volunteer_tasks: ['read', 'update'],
      volunteer_applications: ['read']
    };

    const resourcePermissions = volunteerPermissions[resource];
    if (!resourcePermissions || !resourcePermissions.includes(action)) {
      return false;
    }

    if (resourceId && (resource === 'volunteers' || resource === 'volunteer_tasks')) {
      return resourceId === user.userId;
    }

    return true;
  }

  generateAuthContext(user) {
    return {
      userId: user.userId,
      email: user.email,
      username: user.username,
      role: user.role,
      groups: user.groups,
      organization: user.customAttributes.organization
    };
  }

  async authenticateRequest(event, requiredResource, requiredAction, resourceIdExtractor = null) {
    try {
      const authHeader = event.headers.Authorization || event.headers.authorization;
      
      if (!authHeader) {
        return {
          isAuthenticated: false,
          error: 'No authorization header provided',
          statusCode: 401
        };
      }

      const token = authHeader.replace('Bearer ', '').replace('bearer ', '');
      
      if (!token) {
        return {
          isAuthenticated: false,
          error: 'No token provided',
          statusCode: 401
        };
      }

      const user = await this.getUserInfo(token);

      let resourceId = null;
      if (resourceIdExtractor && typeof resourceIdExtractor === 'function') {
        resourceId = resourceIdExtractor(event, user);
      }

      const hasPermission = await this.checkPermission(user, requiredResource, requiredAction, resourceId);

      if (!hasPermission) {
        return {
          isAuthenticated: true,
          isAuthorized: false,
          error: `Insufficient permissions for ${requiredAction} on ${requiredResource}`,
          statusCode: 403,
          user
        };
      }

      return {
        isAuthenticated: true,
        isAuthorized: true,
        user,
        authContext: this.generateAuthContext(user)
      };

    } catch (error) {
      console.error('Authentication error:', error);
      return {
        isAuthenticated: false,
        error: `Authentication failed: ${error.message}`,
        statusCode: 401
      };
    }
  }
}

function createAuthMiddleware(userPoolId, region, permissionsTableName = null) {
  return new AuthMiddleware(userPoolId, region, permissionsTableName);
}

function extractUserIdFromPath(event) {
  const pathParameters = event.pathParameters || {};
  return pathParameters.userId || pathParameters.id;
}

function extractResourceId(event, resourceType = 'id') {
  const pathParameters = event.pathParameters || {};
  return pathParameters[resourceType] || pathParameters.id;
}

module.exports = {
  AuthMiddleware,
  createAuthMiddleware,
  extractUserIdFromPath,
  extractResourceId
};