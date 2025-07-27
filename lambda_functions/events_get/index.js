// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const tableName = process.env.EVENTS_TABLE_NAME;
        
        const command = new ScanCommand({
            TableName: tableName
        });
        
        const result = await docClient.send(command);
        
        const data = {
            events: result.Items || [],
            count: result.Count || 0,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Events retrieved successfully');
        
    } catch (error) {
        console.error('Error in events_get function:', error);
        return errorResponse(error, 500);
    }
};