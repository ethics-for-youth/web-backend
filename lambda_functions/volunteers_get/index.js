const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
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

        const volunteers = (result.Items || []).map(v => ({
            id: v.id,
            name: v.name,
            email: v.email,
            status: v.status,
            skills: v.skills || [],
            appliedAt: v.appliedAt,
            updatedAt: v.updatedAt
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
