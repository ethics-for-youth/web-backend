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
        validateRequired(body, ['senderName', 'senderEmail', 'messageType', 'content']);
        
        const tableName = process.env.MESSAGES_TABLE_NAME;
        const messageId = `msg_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        const messageItem = {
            id: messageId,
            senderName: body.senderName,
            senderEmail: body.senderEmail,
            senderPhone: body.senderPhone || null,
            messageType: body.messageType, // 'feedback', 'thank-you', 'suggestion', 'complaint', 'general'
            subject: body.subject || null,
            content: body.content,
            isPublic: body.isPublic || false, // Whether message can be displayed publicly
            status: 'new', // new, reviewed, responded, archived
            priority: body.priority || 'normal', // low, normal, high, urgent
            tags: body.tags || [], // Array of tags for categorization
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        const command = new PutCommand({
            TableName: tableName,
            Item: messageItem
        });
        
        await docClient.send(command);
        
        const data = {
            message: messageItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Message submitted successfully');
        
    } catch (error) {
        console.error('Error in messages_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};