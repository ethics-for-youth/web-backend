const { successResponse, errorResponse, validateRequired, parseJSON, createAuthMiddleware } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Initialize auth middleware
const auth = createAuthMiddleware(
    process.env.COGNITO_USER_POOL_ID,
    process.env.AWS_REGION,
    process.env.PERMISSIONS_TABLE_NAME
);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        let authContext = null;

        // Skip authentication if disabled (backward compatibility)
        if (process.env.ENABLE_AUTH === 'true') {
            // Only admins can create volunteer tasks
            const authResult = await auth.authenticateRequest(event, 'volunteer_tasks', 'create');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated admin creating task:', authContext.email, 'Role:', authContext.role);
        }

        // Parse request body
        const body = parseJSON(event.body || '{}');

        // Validate required fields
        validateRequired(body, ['volunteerId', 'eventId', 'taskType', 'description']);

        const tableName = process.env.VOLUNTEER_TASKS_TABLE_NAME;
        const taskId = `task_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        const taskItem = {
            pk: `TASK#${taskId}`,
            sk: `VOLUNTEER#${body.volunteerId}`,
            taskId: taskId,
            volunteerId: body.volunteerId,
            eventId: body.eventId,
            taskType: body.taskType,
            description: body.description,
            status: 'assigned', // assigned, in_progress, completed, cancelled
            priority: body.priority || 'medium', // low, medium, high
            scheduledStart: body.scheduledStart || null,
            scheduledEnd: body.scheduledEnd || null,
            location: body.location || null,
            requirements: body.requirements || [],
            notes: body.notes || '',
            assignedAt: new Date().toISOString(),
            assignedBy: authContext ? authContext.userId : 'system',
            assignedByEmail: authContext ? authContext.email : 'system@efy.com',
            completedAt: null,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: taskItem
        });

        await docClient.send(command);

        const data = {
            task: taskItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Volunteer task created successfully');

    } catch (error) {
        console.error('Error in volunteers_tasks_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};