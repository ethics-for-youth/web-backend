// Import from utility layer
const { successResponse, errorResponse, parseJSON, createAuthMiddleware } = require('/opt/nodejs/utils');
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

        // Skip authentication if disabled (backward compatibility)
        if (process.env.ENABLE_AUTH === 'true') {
            // Authenticate and authorize request (admin only for updating events)
            const authResult = await auth.authenticateRequest(event, 'events', 'update');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated user updating event:', authContext.email, 'Role:', authContext.role);
        }

        const eventId = event.pathParameters?.id;
        if (!eventId) {
            return errorResponse('Event ID is required', 400);
        }

        // Parse request body
        const body = parseJSON(event.body || '{}');
        const tableName = process.env.EVENTS_TABLE_NAME;

        // Check if event exists
        const existingEvent = await docClient.send(
            new GetCommand({
                TableName: tableName,
                Key: { id: eventId }
            })
        );

        if (!existingEvent.Item) {
            return errorResponse('Event not found', 404);
        }

        // Build update expression dynamically
        const updateExpression = [];
        const expressionAttributeValues = {};
        const expressionAttributeNames = {};

        const updatableFields = [
            'title',
            'description',
            'date',
            'location',
            'category',
            'maxParticipants',
            'registrationDeadline',
            'registrationFee',
            'status'
        ];

        updatableFields.forEach(field => {
            if (body[field] !== undefined) {
                updateExpression.push(`#${field} = :${field}`);
                expressionAttributeNames[`#${field}`] = field;
                expressionAttributeValues[`:${field}`] = body[field];
            }
        });

        if (updateExpression.length === 0) {
            return errorResponse('No valid fields to update', 400);
        }

        // Always update updatedAt field
        updateExpression.push('#updatedAt = :updatedAt');
        expressionAttributeNames['#updatedAt'] = 'updatedAt';
        expressionAttributeValues[':updatedAt'] = new Date().toISOString();

        // Add updatedBy information if authenticated
        if (authContext) {
            updateExpression.push('#updatedBy = :updatedBy');
            expressionAttributeNames['#updatedBy'] = 'updatedBy';
            expressionAttributeValues[':updatedBy'] = authContext.userId;

            updateExpression.push('#updatedByEmail = :updatedByEmail');
            expressionAttributeNames['#updatedByEmail'] = 'updatedByEmail';
            expressionAttributeValues[':updatedByEmail'] = authContext.email;
        }

        // Perform update
        const result = await docClient.send(
            new UpdateCommand({
                TableName: tableName,
                Key: { id: eventId },
                UpdateExpression: `SET ${updateExpression.join(', ')}`,
                ExpressionAttributeNames: expressionAttributeNames,
                ExpressionAttributeValues: expressionAttributeValues,
                ReturnValues: 'ALL_NEW'
            })
        );

        const data = {
            event: result.Attributes,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Event updated successfully');
    } catch (error) {
        console.error('Error in events_put function:', error);
        return errorResponse(error, 500);
    }
};
