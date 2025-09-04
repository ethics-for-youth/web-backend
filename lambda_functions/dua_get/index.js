// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');
exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        const tableName = process.env.DUA_TABLE_NAME;

        const command = new ScanCommand({
            TableName: tableName,
            FilterExpression: '#st = :active',
            ExpressionAttributeNames: {
                '#st': 'status'
            },
            ExpressionAttributeValues: {
                ':active': 'active'
            }
        });
        
        const response = await docClient.send(command);
        const data = {
            duas: response.Items || [],
            count: response.Count || 0,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        

        return successResponse(data, 'Duas retrieved successfully');

    } catch (error) {
        console.error('Error in dua_get function:', error);
        return errorResponse(error, 500);
    }
};