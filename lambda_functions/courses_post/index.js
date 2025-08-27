// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON, createAuthMiddleware } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Initialize auth middleware
const auth = createAuthMiddleware(
    process.env.COGNITO_USER_POOL_ID,
    process.env.AWS_REGION,
    process.env.PERMISSIONS_TABLE_NAME
);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        let authContext = null;

        // Skip authentication if disabled (backward compatibility)
        if (process.env.ENABLE_AUTH === 'true') {
            // Authenticate and authorize request (teachers and admins can create courses)
            const authResult = await auth.authenticateRequest(event, 'courses', 'create');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated user creating course:', authContext.email, 'Role:', authContext.role);
        }
        
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
            registrationFee: body.registrationFee || 0,
            status: 'active',
            createdBy: authContext ? authContext.userId : 'system',
            createdByEmail: authContext ? authContext.email : 'system@efy.com',
            instructorId: authContext ? authContext.userId : 'system', // Link to instructor
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