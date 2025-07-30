// Import from utility layer
const { successResponse, errorResponse, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const registrationId = event.pathParameters?.id;
        if (!registrationId) {
            return errorResponse('Registration ID is required', 400);
        }
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        const tableName = process.env.REGISTRATIONS_TABLE_NAME;
        
        // First, check if the registration exists
        const getCommand = new GetCommand({
            TableName: tableName,
            Key: { id: registrationId }
        });
        
        const existingResult = await docClient.send(getCommand);
        
        if (!existingResult.Item) {
            return errorResponse('Registration not found', 404);
        }
        
        // Update the registration with new data
        const updatedRegistration = {
            ...existingResult.Item,
            ...body,
            id: registrationId, // Ensure ID cannot be changed
            updatedAt: new Date().toISOString()
        };
        
        const putCommand = new PutCommand({
            TableName: tableName,
            Item: updatedRegistration
        });
        
        await docClient.send(putCommand);
        
        const data = {
            registration: updatedRegistration,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Registration updated successfully');
        
    } catch (error) {
        console.error('Error in registrations_put function:', error);
        return errorResponse(error, 500);
    }
};