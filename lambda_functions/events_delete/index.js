// Import from utility layer
const { successResponse, errorResponse, createAuthMiddleware } = require('/opt/nodejs/utils');
const { DynamoDBClient, DeleteItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');

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
            // Authenticate and authorize request (admin only for deleting events)
            const authResult = await auth.authenticateRequest(event, 'events', 'delete');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated user deleting event:', authContext.email, 'Role:', authContext.role);
        }
        
        const eventId = event.pathParameters?.id;
        if (!eventId) {
            return errorResponse('Event ID is required', 400);
        }
        
        const tableName = process.env.EVENTS_TABLE_NAME;
        
        // First check if event exists
        const getCommand = new GetItemCommand({
            TableName: tableName,
            Key: {
                id: { S: eventId }
            }
        });
        
        const existingEvent = await docClient.send(getCommand);
        if (!existingEvent.Item) {
            return errorResponse('Event not found', 404);
        }
        
        const command = new DeleteItemCommand({
            TableName: tableName,
            Key: {
                id: { S: eventId }
            }
        });
        
        await docClient.send(command);
        
        const data = {
            deletedEventId: eventId,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Event deleted successfully');
        
    } catch (error) {
        console.error('Error in events_delete function:', error);
        return errorResponse(error, 500);
    }
};