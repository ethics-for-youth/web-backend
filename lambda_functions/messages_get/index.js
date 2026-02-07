// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const tableName = process.env.MESSAGES_TABLE_NAME;
        
        // Get query parameters for filtering
        const queryParams = event.queryStringParameters || {};
        
        let command = new ScanCommand({
            TableName: tableName
        });
        
        let filterExpressions = [];
        let expressionAttributeValues = {};
        
        // Filter by public visibility (default: show only public messages unless admin=true)
        if (queryParams.admin !== 'true') {
            filterExpressions.push('isPublic = :isPublic');
            expressionAttributeValues[':isPublic'] = true;
        }
        
        // Filter by message type
        if (queryParams.messageType) {
            filterExpressions.push('messageType = :messageType');
            expressionAttributeValues[':messageType'] = queryParams.messageType;
        }
        
        // Filter by status
        if (queryParams.status) {
            filterExpressions.push('#status = :status');
            expressionAttributeValues[':status'] = queryParams.status;
            command.input.ExpressionAttributeNames = { '#status': 'status' };
        }
        
        // Filter by priority
        if (queryParams.priority) {
            filterExpressions.push('priority = :priority');
            expressionAttributeValues[':priority'] = queryParams.priority;
        }
        
        // Apply filters if any
        if (filterExpressions.length > 0) {
            command.input.FilterExpression = filterExpressions.join(' AND ');
            command.input.ExpressionAttributeValues = expressionAttributeValues;
        }
        
        const result = await docClient.send(command);
        
        const data = {
            messages: result.Items || [],
            count: result.Count || 0,
            filters: queryParams,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Messages retrieved successfully from the database');
        
    } catch (error) {
        console.error('Error in messages_get function:', error);
        return errorResponse(error, 500);
    }
};