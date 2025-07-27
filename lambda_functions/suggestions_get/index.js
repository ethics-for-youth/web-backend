// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient, ScanCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const tableName = process.env.SUGGESTIONS_TABLE_NAME;
        
        // Get query parameters for filtering
        const queryParams = event.queryStringParameters || {};
        const category = queryParams.category;
        const status = queryParams.status;
        
        let scanCommand = {
            TableName: tableName
        };
        
        // Add filters if provided
        if (category || status) {
            const filterExpressions = [];
            const expressionAttributeValues = {};
            const expressionAttributeNames = {};
            
            if (category) {
                filterExpressions.push('#category = :category');
                expressionAttributeNames['#category'] = 'category';
                expressionAttributeValues[':category'] = category;
            }
            
            if (status) {
                filterExpressions.push('#status = :status');
                expressionAttributeNames['#status'] = 'status';
                expressionAttributeValues[':status'] = status;
            }
            
            scanCommand.FilterExpression = filterExpressions.join(' AND ');
            scanCommand.ExpressionAttributeNames = expressionAttributeNames;
            scanCommand.ExpressionAttributeValues = expressionAttributeValues;
        }
        
        const command = new ScanCommand(scanCommand);
        const result = await docClient.send(command);
        
        // Sort suggestions by submission date (newest first)
        const suggestions = (result.Items || []).sort((a, b) => 
            new Date(b.submittedAt) - new Date(a.submittedAt)
        );
        
        const data = {
            suggestions: suggestions,
            count: suggestions.length,
            categoryBreakdown: {},
            statusBreakdown: {},
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        // Calculate category and status breakdowns
        suggestions.forEach(suggestion => {
            const cat = suggestion.category || 'uncategorized';
            const stat = suggestion.status || 'unknown';
            
            data.categoryBreakdown[cat] = (data.categoryBreakdown[cat] || 0) + 1;
            data.statusBreakdown[stat] = (data.statusBreakdown[stat] || 0) + 1;
        });
        
        return successResponse(data, 'Suggestions retrieved successfully');
        
    } catch (error) {
        console.error('Error in suggestions_get function:', error);
        return errorResponse(error, 500);
    }
};