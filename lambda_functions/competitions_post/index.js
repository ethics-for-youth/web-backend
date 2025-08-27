// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON, isEmptyString, createAuthMiddleware } = require('/opt/nodejs/utils');
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
            // Authenticate and authorize request (admin only for creating competitions)
            const authResult = await auth.authenticateRequest(event, 'competitions', 'create');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated admin creating competition:', authContext.email, 'Role:', authContext.role);
        }

        // Parse request body
        const body = parseJSON(event.body || '{}');

        // Validate required fields
        validateRequired(body, ['title', 'description', 'category', 'startDate', 'endDate']);

        // Empty string check for required fields
        ['title', 'description', 'category'].forEach(field => {
            if (isEmptyString(body[field])) {
                throw new Error(`Field '${field}' cannot be empty or whitespace`);
            }
        });

        if (new Date(body.startDate) > new Date(body.endDate)) {
            return errorResponse(new Error(`startDate cannot be after endDate`), 400);
        }
        if (body.registrationDeadline && new Date(body.registrationDeadline) > new Date(body.startDate)) {
            return errorResponse(new Error(`registrationDeadline cannot be after startDate`), 400);
        }

        // Type checks
        if (body.rules && !Array.isArray(body.rules)) {
            return errorResponse(new Error(`rules must be an array`), 400);
        }
        if (body.prizes && !Array.isArray(body.prizes)) {
            return errorResponse(new Error(`prizes must be an array`), 400);
        }
        if (body.maxParticipants !== undefined) {
            if (typeof body.maxParticipants !== 'number' || body.maxParticipants < 0) {
                return errorResponse(new Error(`maxParticipants must be a non-negative number`), 400);
            }
        }

        const tableName = process.env.COMPETITIONS_TABLE_NAME;
        const competitionId = `comp_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        const competitionItem = {
            id: competitionId,
            title: body.title.trim(),
            description: body.description.trim(),
            category: body.category.trim(),
            startDate: body.startDate,
            endDate: body.endDate,
            registrationDeadline: body.registrationDeadline || body.startDate,
            rules: body.rules || [],
            prizes: body.prizes || [],
            maxParticipants: body.maxParticipants || null,
            registrationFee: body.registrationFee || 0,
            isPublish: false,
            status: 'open',
            participants: [],
            createdBy: authContext ? authContext.userId : 'system',
            createdByEmail: authContext ? authContext.email : 'system@efy.com',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: competitionItem
        });

        await docClient.send(command);

        const data = {
            competition: competitionItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Competition created successfully', 201);

    } catch (error) {
        console.error('Error in competitions_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};