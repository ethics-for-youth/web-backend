// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const courseId = event.pathParameters?.id;
        if (!courseId) {
            return errorResponse('Course ID is required', 400);
        }
        
        const tableName = process.env.COURSES_TABLE_NAME;
        
        const command = new GetCommand({
            TableName: tableName,
            Key: {
                id: courseId
            }
        });
        
        const result = await docClient.send(command);
        
        if (!result.Item) {
            return errorResponse('Course not found', 404);
        }
        
        const data = {
            course: result.Item,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Course retrieved successfully');
        
    } catch (error) {
        console.error('Error in courses_get_by_id function:', error);
        return errorResponse(error, 500);
    }
};