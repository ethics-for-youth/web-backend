// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient, ScanCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const tableName = process.env.VOLUNTEERS_TABLE_NAME;
        
        const command = new ScanCommand({
            TableName: tableName,
            ProjectionExpression: 'id, #name, email, #status, skills, appliedAt, updatedAt',
            ExpressionAttributeNames: {
                '#name': 'name',
                '#status': 'status'
            }
        });
        
        const result = await docClient.send(command);
        
        // Filter out sensitive information and provide only basic metadata
        const volunteers = (result.Items || []).map(volunteer => ({
            id: volunteer.id,
            name: volunteer.name,
            email: volunteer.email,
            status: volunteer.status,
            skills: volunteer.skills || [],
            appliedAt: volunteer.appliedAt,
            updatedAt: volunteer.updatedAt
        }));
        
        const data = {
            volunteers: volunteers,
            count: volunteers.length,
            statusBreakdown: {
                pending: volunteers.filter(v => v.status === 'pending').length,
                approved: volunteers.filter(v => v.status === 'approved').length,
                active: volunteers.filter(v => v.status === 'active').length,
                inactive: volunteers.filter(v => v.status === 'inactive').length
            },
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Volunteers retrieved successfully');
        
    } catch (error) {
        console.error('Error in volunteers_get function:', error);
        return errorResponse(error, 500);
    }
};