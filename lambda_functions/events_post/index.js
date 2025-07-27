// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        // Validate required fields
        validateRequired(body, ['title', 'description', 'date', 'location']);
        
        const tableName = process.env.EVENTS_TABLE_NAME;
        const eventId = `event_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        const eventItem = {
            id: eventId,
            title: body.title,
            description: body.description,
            date: body.date,
            location: body.location,
            category: body.category || 'general',
            maxParticipants: body.maxParticipants || null,
            registrationDeadline: body.registrationDeadline || null,
            status: 'active',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        const command = new PutItemCommand({
            TableName: tableName,
            Item: eventItem
        });
        
        await docClient.send(command);
        
        const data = {
            event: eventItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Event created successfully');
        
    } catch (error) {
        console.error('Error in events_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};