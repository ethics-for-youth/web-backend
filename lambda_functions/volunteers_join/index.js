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
        validateRequired(body, ['name', 'email', 'skills', 'availability']);
        
        const tableName = process.env.VOLUNTEERS_TABLE_NAME;
        const volunteerId = `volunteer_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        const volunteerItem = {
            id: volunteerId,
            name: body.name,
            email: body.email,
            phone: body.phone || null,
            skills: Array.isArray(body.skills) ? body.skills : [body.skills],
            availability: body.availability,
            experience: body.experience || null,
            motivation: body.motivation || null,
            preferredRoles: body.preferredRoles || [],
            status: 'pending',
            appliedAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        const command = new PutItemCommand({
            TableName: tableName,
            Item: volunteerItem
        });
        
        await docClient.send(command);
        
        const data = {
            volunteer: {
                id: volunteerItem.id,
                name: volunteerItem.name,
                email: volunteerItem.email,
                status: volunteerItem.status,
                appliedAt: volunteerItem.appliedAt
            },
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Volunteer application submitted successfully');
        
    } catch (error) {
        console.error('Error in volunteers_join function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};