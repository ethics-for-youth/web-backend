// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        const tableName = process.env.DUA_TABLE_NAME;

        const command = new QueryCommand({
            TableName: tableName,
            IndexName: 'StatusIndex',
            KeyConditionExpression: 'status = :status',
            ExpressionAttributeValues: {
                ':status': 'active'
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