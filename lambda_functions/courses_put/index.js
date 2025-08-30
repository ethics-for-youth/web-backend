// Import from utility layer
const { successResponse, errorResponse, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const courseId = event.pathParameters?.id;
        if (!courseId) {
            return errorResponse('Course ID is required', 400);
        }
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
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
        
        // Update the course with new data
        const updatedCourse = {
            ...existingResult.Item,
            ...body,
            id: courseId, // Ensure ID cannot be changed
            updatedAt: new Date().toISOString()
        };
        
        const putCommand = new PutCommand({
            TableName: tableName,
            Item: updatedCourse
        });
        
        await docClient.send(putCommand);
        
        const data = {
            course: updatedCourse,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Course updated successfully');
        
    } catch (error) {
        console.error('Error in courses_put function:', error);
        return errorResponse(error, 500);
    }
};