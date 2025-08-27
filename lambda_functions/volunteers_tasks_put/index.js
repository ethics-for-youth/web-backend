const { successResponse, errorResponse, validateRequired, parseJSON, createAuthMiddleware, extractResourceId } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

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
        const taskId = event.pathParameters?.id || event.pathParameters?.taskId;

        if (!taskId) {
            return errorResponse('Task ID is required', 400);
        }

        // Skip authentication if disabled (backward compatibility)
        if (process.env.ENABLE_AUTH === 'true') {
            // Custom resource ID extractor for volunteer tasks
            const resourceIdExtractor = (event, user) => {
                // For volunteers, they can only update their own tasks
                // We'll verify ownership after getting the task
                return taskId;
            };

            const authResult = await auth.authenticateRequest(event, 'volunteer_tasks', 'update', resourceIdExtractor);
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated user updating task:', authContext.email, 'Role:', authContext.role);
        }

        const tableName = process.env.VOLUNTEER_TASKS_TABLE_NAME;

        // First, get the current task to verify ownership and get the volunteer ID
        const getCommand = new GetCommand({
            TableName: tableName,
            Key: {
                pk: `TASK#${taskId}`
            }
        });

        // We need to scan to find the task since we don't have the SK (volunteerId)
        const { QueryCommand } = require('@aws-sdk/lib-dynamodb');
        const findCommand = new QueryCommand({
            TableName: tableName,
            KeyConditionExpression: 'pk = :pk',
            ExpressionAttributeValues: {
                ':pk': `TASK#${taskId}`
            }
        });

        const findResult = await docClient.send(findCommand);
        const existingTask = findResult.Items?.[0];

        if (!existingTask) {
            return errorResponse('Task not found', 404);
        }

        // Verify ownership for volunteers
        if (authContext && authContext.role === 'volunteer' && existingTask.volunteerId !== authContext.userId) {
            return errorResponse('You can only update your own tasks', 403);
        }

        // Parse request body
        const body = parseJSON(event.body || '{}');

        // Determine allowed updates based on role
        const allowedUpdates = {};
        
        if (authContext?.role === 'admin') {
            // Admins can update everything
            if (body.status) allowedUpdates.status = body.status;
            if (body.notes !== undefined) allowedUpdates.notes = body.notes;
            if (body.description) allowedUpdates.description = body.description;
            if (body.scheduledStart !== undefined) allowedUpdates.scheduledStart = body.scheduledStart;
            if (body.scheduledEnd !== undefined) allowedUpdates.scheduledEnd = body.scheduledEnd;
            if (body.priority) allowedUpdates.priority = body.priority;
        } else {
            // Volunteers can only update status and notes
            if (body.status && ['in_progress', 'completed'].includes(body.status)) {
                allowedUpdates.status = body.status;
            }
            if (body.notes !== undefined) allowedUpdates.notes = body.notes;
        }

        // Add completion timestamp if status is being set to completed
        if (allowedUpdates.status === 'completed') {
            allowedUpdates.completedAt = new Date().toISOString();
        }

        // Build update expression
        const updateExpressions = [];
        const expressionAttributeNames = {};
        const expressionAttributeValues = {};

        Object.keys(allowedUpdates).forEach((key, index) => {
            const attrName = `#attr${index}`;
            const attrValue = `:val${index}`;
            updateExpressions.push(`${attrName} = ${attrValue}`);
            expressionAttributeNames[attrName] = key;
            expressionAttributeValues[attrValue] = allowedUpdates[key];
        });

        // Always update the updatedAt timestamp
        updateExpressions.push('#updatedAt = :updatedAt');
        expressionAttributeNames['#updatedAt'] = 'updatedAt';
        expressionAttributeValues[':updatedAt'] = new Date().toISOString();

        // Add updatedBy information if authenticated
        if (authContext) {
            updateExpressions.push('#updatedBy = :updatedBy');
            expressionAttributeNames['#updatedBy'] = 'updatedBy';
            expressionAttributeValues[':updatedBy'] = authContext.userId;

            updateExpressions.push('#updatedByEmail = :updatedByEmail');
            expressionAttributeNames['#updatedByEmail'] = 'updatedByEmail';
            expressionAttributeValues[':updatedByEmail'] = authContext.email;
        }

        if (updateExpressions.length === 1) { // Only updatedAt
            return errorResponse('No valid updates provided', 400);
        }

        const updateCommand = new UpdateCommand({
            TableName: tableName,
            Key: {
                pk: existingTask.pk,
                sk: existingTask.sk
            },
            UpdateExpression: `SET ${updateExpressions.join(', ')}`,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        });

        const updateResult = await docClient.send(updateCommand);

        const data = {
            task: updateResult.Attributes,
            updatesApplied: allowedUpdates,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Volunteer task updated successfully');

    } catch (error) {
        console.error('Error in volunteers_tasks_put function:', error);
        return errorResponse(error, 500);
    }
};