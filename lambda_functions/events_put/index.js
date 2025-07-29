// Import from utility layer
const { successResponse, errorResponse, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient, UpdateItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');
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
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
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
        
        // Build update expression dynamically
        const updateExpression = [];
        const expressionAttributeValues = {};
        const expressionAttributeNames = {};
        
        const updatableFields = ['title', 'description', 'date', 'location', 'category', 'maxParticipants', 'registrationDeadline', 'status'];
        
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
        
        // Always update the updatedAt field
        updateExpression.push('#updatedAt = :updatedAt');
        expressionAttributeNames['#updatedAt'] = 'updatedAt';
        expressionAttributeValues[':updatedAt'] = new Date().toISOString();
        
        const command = new UpdateItemCommand({
            TableName: tableName,
            Key: {
                id: { S: eventId }
            },
            UpdateExpression: `SET ${updateExpression.join(', ')}`,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        });
        
        const result = await docClient.send(command);
        
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