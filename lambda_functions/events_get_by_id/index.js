// Import from utility layer
const { successResponse, errorResponse, createAuthMiddleware } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

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

        // Skip authentication if disabled (backward compatibility)
        if (process.env.ENABLE_AUTH === 'true') {
            // Authenticate and authorize request
            const authResult = await auth.authenticateRequest(event, 'events', 'read');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            console.log('Authenticated user:', authResult.user.email, 'Role:', authResult.user.role);
        }

        const eventId = event.pathParameters?.id;
        if (!eventId) {
            return errorResponse('Event ID is required', 400);
        }

        const tableName = process.env.EVENTS_TABLE_NAME;

        const command = new GetCommand({
            TableName: tableName,
            Key: { id: eventId }
        });

        const result = await docClient.send(command);

        if (!result.Item) {
            return errorResponse('Event not found', 404);
        }

        const data = {
            event: result.Item,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Event retrieved successfully');

    } catch (error) {
        console.error('Error in events_get_by_id function:', error);
        return errorResponse(error, 500);
    }
};
