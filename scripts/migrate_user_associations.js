#!/usr/bin/env node

/**
 * Database Migration Script: Add User Associations
 * 
 * This script updates existing DynamoDB records to include user association fields
 * for the RBAC implementation.
 * 
 * Usage: node migrate_user_associations.js <environment>
 * Example: node migrate_user_associations.js dev
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');

class UserAssociationMigrator {
  constructor(region, environment) {
    this.region = region;
    this.environment = environment;
    this.client = new DynamoDBClient({ region });
    this.docClient = DynamoDBDocumentClient.from(this.client);
    
    // Table names based on environment
    this.tableNames = {
      events: `efy-${environment}-events`,
      competitions: `efy-${environment}-competitions`, 
      courses: `efy-${environment}-courses`,
      registrations: `efy-${environment}-registrations`,
      messages: `efy-${environment}-messages`,
      suggestions: `efy-${environment}-suggestions`,
      volunteers: `efy-${environment}-volunteers`,
      users: `efy-${environment}-users`,
      permissions: `efy-${environment}-permissions`
    };
  }

  async migrateTable(tableName, updateFields) {
    console.log(`\n🔄 Migrating ${tableName}...`);
    
    try {
      // Scan all items in the table
      const scanCommand = new ScanCommand({
        TableName: tableName
      });
      
      const result = await this.docClient.send(scanCommand);
      const items = result.Items || [];
      
      console.log(`Found ${items.length} items to migrate`);
      
      let migratedCount = 0;
      let skippedCount = 0;
      
      for (const item of items) {
        // Check if item already has user association fields
        if (item.createdBy || item.updatedBy) {
          skippedCount++;
          continue;
        }
        
        // Build update expression
        const updateExpressions = [];
        const expressionAttributeNames = {};
        const expressionAttributeValues = {};
        
        updateFields.forEach((field, index) => {
          const attrName = `#${field}`;
          const attrValue = `:${field}`;
          updateExpressions.push(`${attrName} = ${attrValue}`);
          expressionAttributeNames[attrName] = field;
          expressionAttributeValues[attrValue] = field.includes('Email') ? 'system@efy.com' : 'system';
        });
        
        // Always update timestamps
        if (!item.updatedAt) {
          updateExpressions.push('#updatedAt = :updatedAt');
          expressionAttributeNames['#updatedAt'] = 'updatedAt';
          expressionAttributeValues[':updatedAt'] = new Date().toISOString();
        }
        
        // Determine the key structure
        let key;
        if (item.id) {
          key = { id: item.id };
        } else if (item.pk && item.sk) {
          key = { pk: item.pk, sk: item.sk };
        } else if (item.orderId && item.paymentId) {
          key = { orderId: item.orderId, paymentId: item.paymentId };
        } else {
          console.warn(`⚠️  Skipping item with unknown key structure:`, Object.keys(item));
          skippedCount++;
          continue;
        }
        
        const updateCommand = new UpdateCommand({
          TableName: tableName,
          Key: key,
          UpdateExpression: `SET ${updateExpressions.join(', ')}`,
          ExpressionAttributeNames: expressionAttributeNames,
          ExpressionAttributeValues: expressionAttributeValues
        });
        
        await this.docClient.send(updateCommand);
        migratedCount++;
        
        if (migratedCount % 10 === 0) {
          console.log(`  ✅ Migrated ${migratedCount} items...`);
        }
      }
      
      console.log(`✅ Migration complete: ${migratedCount} migrated, ${skippedCount} skipped`);
      
    } catch (error) {
      console.error(`❌ Error migrating ${tableName}:`, error);
      throw error;
    }
  }

  async seedDefaultUsers() {
    console.log('\n👤 Creating default system users...');
    
    const systemUsers = [
      {
        userId: 'system',
        email: 'system@efy.com',
        username: 'system',
        role: 'admin',
        isSystemUser: true,
        fullName: 'System Administrator',
        status: 'active',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        userId: 'admin-seed',
        email: 'admin@efy.com', 
        username: 'admin',
        role: 'admin',
        isSystemUser: false,
        fullName: 'Default Administrator',
        status: 'active',
        cognitoStatus: 'PENDING_CREATION',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
    ];
    
    for (const user of systemUsers) {
      try {
        const putCommand = new PutCommand({
          TableName: this.tableNames.users,
          Item: user,
          ConditionExpression: 'attribute_not_exists(userId)'
        });
        
        await this.docClient.send(putCommand);
        console.log(`  ✅ Created user: ${user.email}`);
      } catch (error) {
        if (error.name === 'ConditionalCheckFailedException') {
          console.log(`  ⚠️  User already exists: ${user.email}`);
        } else {
          console.error(`  ❌ Error creating user ${user.email}:`, error);
        }
      }
    }
  }

  async seedDefaultPermissions() {
    console.log('\n🔐 Seeding default permissions...');
    
    try {
      const { PermissionsManager } = require('../layers/utility/nodejs/permissions');
      const permissionsManager = new PermissionsManager(
        this.region,
        this.tableNames.permissions
      );
      
      await permissionsManager.seedPermissions();
      console.log('  ✅ Default permissions seeded');
    } catch (error) {
      console.error('  ❌ Error seeding permissions:', error);
      // Don't fail the migration if permissions seeding fails
    }
  }

  async run() {
    console.log(`🚀 Starting user association migration for ${this.environment} environment`);
    console.log(`📊 Region: ${this.region}`);
    
    try {
      // Define migration tasks
      const migrationTasks = [
        {
          table: this.tableNames.events,
          fields: ['createdBy', 'createdByEmail', 'updatedBy', 'updatedByEmail']
        },
        {
          table: this.tableNames.competitions,
          fields: ['createdBy', 'createdByEmail', 'updatedBy', 'updatedByEmail']
        },
        {
          table: this.tableNames.courses,
          fields: ['createdBy', 'createdByEmail', 'updatedBy', 'updatedByEmail', 'instructorId']
        },
        {
          table: this.tableNames.registrations,
          fields: ['userId']
        },
        {
          table: this.tableNames.messages,
          fields: ['userId', 'createdBy', 'createdByEmail']
        },
        {
          table: this.tableNames.suggestions,
          fields: ['userId', 'createdBy', 'createdByEmail']
        },
        {
          table: this.tableNames.volunteers,
          fields: ['userId', 'createdBy', 'createdByEmail', 'updatedBy', 'updatedByEmail']
        }
      ];
      
      // Seed default users first
      await this.seedDefaultUsers();
      
      // Run migrations
      for (const task of migrationTasks) {
        await this.migrateTable(task.table, task.fields);
      }
      
      // Seed permissions
      await this.seedDefaultPermissions();
      
      console.log('\n🎉 Migration completed successfully!');
      
      console.log('\n📋 Next steps:');
      console.log('1. Create Cognito users for system administrators');
      console.log('2. Update ENABLE_AUTH environment variable to "true" when ready');
      console.log('3. Test authentication with created users');
      console.log('4. Update API Gateway to use Cognito authorizer');
      
    } catch (error) {
      console.error('\n💥 Migration failed:', error);
      process.exit(1);
    }
  }
}

// Main execution
async function main() {
  const environment = process.argv[2];
  
  if (!environment) {
    console.error('❌ Environment parameter is required');
    console.log('Usage: node migrate_user_associations.js <environment>');
    console.log('Examples:');
    console.log('  node migrate_user_associations.js dev');
    console.log('  node migrate_user_associations.js qa');
    console.log('  node migrate_user_associations.js prod');
    process.exit(1);
  }
  
  if (!['dev', 'qa', 'prod'].includes(environment)) {
    console.error('❌ Invalid environment. Must be dev, qa, or prod');
    process.exit(1);
  }
  
  const region = process.env.AWS_REGION || 'us-east-1';
  
  console.log(`🎯 Environment: ${environment}`);
  console.log(`🌍 Region: ${region}`);
  console.log('');
  
  const migrator = new UserAssociationMigrator(region, environment);
  await migrator.run();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { UserAssociationMigrator };