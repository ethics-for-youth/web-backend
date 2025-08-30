// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        // Validate required fields
        validateRequired(body, ['title', 'description', 'category']);
        
        const tableName = process.env.SUGGESTIONS_TABLE_NAME;
        const suggestionId = `suggestion_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        const suggestionItem = {
            id: suggestionId,
            title: body.title,
            description: body.description,
            category: body.category,
            submitterName: body.submitterName || 'Anonymous',
            submitterEmail: body.submitterEmail || null,
            priority: body.priority || 'medium',
            tags: body.tags || [],
            status: 'submitted',
            votes: 0,
            submittedAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        const command = new PutCommand({
            TableName: tableName,
            Item: suggestionItem
        });
        
        await docClient.send(command);
        
        const data = {
            suggestion: {
                id: suggestionItem.id,
                title: suggestionItem.title,
                category: suggestionItem.category,
                submitterName: suggestionItem.submitterName,
                status: suggestionItem.status,
                submittedAt: suggestionItem.submittedAt
            },
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Suggestion submitted successfully');
        
    } catch (error) {
        console.error('Error in suggestions_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};