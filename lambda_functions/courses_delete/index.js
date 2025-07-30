// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

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
        
        // First, check if the course exists
        const getCommand = new GetCommand({
            TableName: tableName,
            Key: { id: courseId }
        });
        
        const existingResult = await docClient.send(getCommand);
        
        if (!existingResult.Item) {
            return errorResponse('Course not found', 404);
        }
        
        // Delete the course
        const deleteCommand = new DeleteCommand({
            TableName: tableName,
            Key: { id: courseId }
        });
        
        await docClient.send(deleteCommand);
        
        const data = {
            deletedCourse: existingResult.Item,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Course deleted successfully');
        
    } catch (error) {
        console.error('Error in courses_delete function:', error);
        return errorResponse(error, 500);
    }
};