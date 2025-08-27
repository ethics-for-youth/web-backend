const { successResponse, errorResponse, PermissionsManager } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
  try {
    const permissionsManager = new PermissionsManager(
      process.env.AWS_REGION,
      process.env.PERMISSIONS_TABLE_NAME
    );

    console.log('Starting permissions seeding...');
    
    await permissionsManager.seedPermissions();
    
    console.log('Permissions seeding completed successfully');
    
    return successResponse(
      { 
        message: 'Permissions seeded successfully',
        timestamp: new Date().toISOString()
      }, 
      'Permissions table has been populated with default RBAC permissions'
    );

  } catch (error) {
    console.error('Error seeding permissions:', error);
    return errorResponse(
      `Failed to seed permissions: ${error.message}`, 
      500
    );
  }
};