const { successResponse, errorResponse, createAuthMiddleware } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

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
            // Authenticate and authorize request
            const authResult = await auth.authenticateRequest(event, 'volunteer_applications', 'read');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated user:', authContext.email, 'Role:', authContext.role);
        }

        const tableName = process.env.VOLUNTEER_APPLICATIONS_TABLE_NAME;
        const queryParams = event.queryStringParameters || {};

        let command;
        let queryDescription;

        if (authContext && authContext.role === 'volunteer') {
            // Volunteers can only see their own applications
            command = new QueryCommand({
                TableName: tableName,
                IndexName: 'VolunteerIndex',
                KeyConditionExpression: 'volunteerId = :volunteerId',
                ExpressionAttributeValues: {
                    ':volunteerId': authContext.userId
                }
            });
            queryDescription = `applications for volunteer ${authContext.userId}`;
        } else if (authContext && authContext.role === 'admin') {
            // Admins can see all applications or filter by event/volunteer/status
            if (queryParams.volunteerId) {
                command = new QueryCommand({
                    TableName: tableName,
                    IndexName: 'VolunteerIndex',
                    KeyConditionExpression: 'volunteerId = :volunteerId',
                    ExpressionAttributeValues: {
                        ':volunteerId': queryParams.volunteerId
                    }
                });
                queryDescription = `applications for volunteer ${queryParams.volunteerId}`;
            } else if (queryParams.eventId) {
                command = new QueryCommand({
                    TableName: tableName,
                    IndexName: 'EventIndex',
                    KeyConditionExpression: 'eventId = :eventId',
                    ExpressionAttributeValues: {
                        ':eventId': queryParams.eventId
                    }
                });
                queryDescription = `applications for event ${queryParams.eventId}`;
            } else {
                command = new ScanCommand({
                    TableName: tableName
                });
                queryDescription = 'all volunteer applications';
            }

            // Add filter for status if specified
            if (queryParams.status && command.FilterExpression === undefined) {
                command.FilterExpression = '#status = :status';
                command.ExpressionAttributeNames = { '#status': 'status' };
                command.ExpressionAttributeValues = { 
                    ...command.ExpressionAttributeValues,
                    ':status': queryParams.status 
                };
                queryDescription += ` with status ${queryParams.status}`;
            }
        } else {
            // Default: scan all (for backward compatibility when auth is disabled)
            command = new ScanCommand({
                TableName: tableName
            });
            queryDescription = 'all volunteer applications';
        }

        const result = await docClient.send(command);

        const data = {
            applications: result.Items || [],
            count: result.Count || 0,
            query: queryDescription,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Volunteer applications retrieved successfully');

    } catch (error) {
        console.error('Error in volunteers_applications_get function:', error);
        return errorResponse(error, 500);
    }
};