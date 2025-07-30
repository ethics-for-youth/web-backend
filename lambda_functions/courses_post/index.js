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
        validateRequired(body, ['title', 'description', 'instructor', 'duration']);
        
        const tableName = process.env.COURSES_TABLE_NAME;
        const courseId = `course_${Date.now()}_${Math.random().toString(36).substring(7)}`;
        
        const courseItem = {
            id: courseId,
            title: body.title,
            description: body.description,
            instructor: body.instructor,
            duration: body.duration, // Duration in hours or sessions
            category: body.category || 'general',
            level: body.level || 'beginner', // beginner, intermediate, advanced
            maxParticipants: body.maxParticipants || null,
            startDate: body.startDate || null,
            endDate: body.endDate || null,
            schedule: body.schedule || null, // e.g., "Sundays 2-4 PM"
            materials: body.materials || null, // Required materials or resources
            status: 'active',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        const command = new PutCommand({
            TableName: tableName,
            Item: courseItem
        });
        
        await docClient.send(command);
        
        const data = {
            course: courseItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Course created successfully');
        
    } catch (error) {
        console.error('Error in courses_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};