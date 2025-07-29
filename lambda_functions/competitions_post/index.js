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
        validateRequired(body, ['title', 'description', 'category', 'startDate', 'endDate']);
        
        const tableName = process.env.COMPETITIONS_TABLE_NAME;
        const competitionId = `comp_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        const competitionItem = {
            id: competitionId,
            title: body.title,
            description: body.description,
            category: body.category,
            startDate: body.startDate,
            endDate: body.endDate,
            registrationDeadline: body.registrationDeadline || body.startDate,
            rules: body.rules || [],
            prizes: body.prizes || [],
            maxParticipants: body.maxParticipants || null,
            status: 'open',
            participants: [],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        const command = new PutItemCommand({
            TableName: tableName,
            Item: competitionItem
        });
        
        await docClient.send(command);
        
        const data = {
            competition: competitionItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Competition created successfully');
        
    } catch (error) {
        console.error('Error in competitions_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};