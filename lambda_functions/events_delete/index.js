// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient, DeleteItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
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