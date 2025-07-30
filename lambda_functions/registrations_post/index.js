// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        // Validate required fields
        validateRequired(body, ['userId', 'itemId', 'itemType', 'userEmail', 'userName']);
        
        const tableName = process.env.REGISTRATIONS_TABLE_NAME;
        const registrationId = `reg_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        const registrationItem = {
            id: registrationId,
            userId: body.userId,
            itemId: body.itemId, // Event, competition, or course ID
            itemType: body.itemType, // 'event', 'competition', or 'course'
            userEmail: body.userEmail,
            userName: body.userName,
            userPhone: body.userPhone || null,
            status: 'registered', // registered, cancelled, completed
            notes: body.notes || null,
            registeredAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        const command = new PutCommand({
            TableName: tableName,
            Item: registrationItem
        });
        
        await docClient.send(command);
        
        const data = {
            registration: registrationItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Registration created successfully');
        
    } catch (error) {
        console.error('Error in registrations_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};