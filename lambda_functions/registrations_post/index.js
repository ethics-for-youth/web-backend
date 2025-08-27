// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON, createAuthMiddleware } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Initialize auth middleware
const auth = createAuthMiddleware(
    process.env.COGNITO_USER_POOL_ID,
    process.env.AWS_REGION,
    process.env.PERMISSIONS_TABLE_NAME
);

async function validateItemExists(itemId, itemType) {
    let tableName;
    console.log("itemType", itemType, itemId)
    switch (itemType) {
        case 'event':
            tableName = process.env.EVENTS_TABLE_NAME;
            break;
        case 'competition':
            tableName = process.env.COMPETITIONS_TABLE_NAME;
            break;
        case 'course':
            tableName = process.env.COURSES_TABLE_NAME;
            break;
        default:
            throw new Error(`Invalid itemType: ${itemType}`);
    }
    const command = new GetCommand({
        TableName: tableName,
        Key: { id: itemId }
    });
    const result = await docClient.send(command);

    if (!result.Item) {
        const error = new Error(`${itemType} with ID ${itemId} does not exist`);
        error.code = "ITEM_NOT_FOUND";
        throw error;
    }

    return result.Item;
}

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        let authContext = null;

        // Skip authentication if disabled (backward compatibility)
        if (process.env.ENABLE_AUTH === 'true') {
            // Authenticate and authorize request (students, volunteers, admins can register)
            const authResult = await auth.authenticateRequest(event, 'registrations', 'create');
            
            if (!authResult.isAuthenticated) {
                console.log('Authentication failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            if (!authResult.isAuthorized) {
                console.log('Authorization failed:', authResult.error);
                return errorResponse(authResult.error, authResult.statusCode);
            }
            
            authContext = authResult.authContext;
            console.log('Authenticated user registering:', authContext.email, 'Role:', authContext.role);
        }

        // Parse request body
        const body = parseJSON(event.body || '{}');

        // Use authenticated user's information if available, otherwise use body
        const userId = authContext ? authContext.userId : body.userId;
        const userEmail = authContext ? authContext.email : body.userEmail;
        const userName = authContext ? authContext.username || authContext.email : body.userName;

        // Validate required fields
        validateRequired(body, ['itemId', 'itemType']);
        
        // When authenticated, we don't require userId, userEmail, userName in body
        if (!authContext) {
            validateRequired(body, ['userId', 'userEmail', 'userName']);
        }

        // Validate existence of event, competition, or course
        await validateItemExists(body.itemId, body.itemType);

        const tableName = process.env.REGISTRATIONS_TABLE_NAME;
        const registrationId = `reg_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        const registrationItem = {
            id: registrationId,
            userId: userId,
            itemId: body.itemId, // Event, competition, or course ID
            itemType: body.itemType, // 'event', 'competition', or 'course'
            userEmail: userEmail,
            userName: userName,
            userPhone: body.userPhone || null,
            registrationFee: body.registrationFee || 0, // Fee applicable at time of registration
            paymentStatus: body.paymentStatus || 'pending', // pending, paid, failed
            paymentId: body.paymentId || null, // Razorpay payment/order ID if applicable
            status: 'registered', // registered, cancelled, completed
            notes: body.notes || null,
            registeredAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: registrationItem
        });

        await docClient.send(command);

        const data = {
            registration: registrationItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Registration created successfully');

    } catch (error) {
        console.error('Error in registrations_post function:', error);
        if (error.message.includes('Missing required')) {
            return errorResponse(error, 400);
        } else if (error.code === "ITEM_NOT_FOUND") {
            return errorResponse(error, 404);
        } else if (error.message.startsWith('Invalid itemType')) {
            return errorResponse(error, 400);
        } else {
            return errorResponse(error, 500);
        }
    }
};