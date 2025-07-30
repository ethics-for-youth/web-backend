// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const tableName = process.env.REGISTRATIONS_TABLE_NAME;
        
        // Get query parameters for filtering
        const queryParams = event.queryStringParameters || {};
        
        let command = new ScanCommand({
            TableName: tableName
        });
        
        // Add filter if itemType is specified
        if (queryParams.itemType) {
            command.input.FilterExpression = 'itemType = :itemType';
            command.input.ExpressionAttributeValues = {
                ':itemType': queryParams.itemType
            };
        }
        
        // Add filter if itemId is specified
        if (queryParams.itemId) {
            if (command.input.FilterExpression) {
                command.input.FilterExpression += ' AND itemId = :itemId';
                command.input.ExpressionAttributeValues[':itemId'] = queryParams.itemId;
            } else {
                command.input.FilterExpression = 'itemId = :itemId';
                command.input.ExpressionAttributeValues = {
                    ':itemId': queryParams.itemId
                };
            }
        }
        
        const result = await docClient.send(command);
        
        const data = {
            registrations: result.Items || [],
            count: result.Count || 0,
            filters: queryParams,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Registrations retrieved successfully');
        
    } catch (error) {
        console.error('Error in registrations_get function:', error);
        return errorResponse(error, 500);
    }
};