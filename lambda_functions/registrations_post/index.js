// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

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
    console.log("objectaaa", tableName)
    const command = new GetCommand({
        TableName: tableName,
        Key: { id: itemId }
    });
    console.log("add", command)
    const result = await docClient.send(command);

    if (!result.Item) {
        throw new Error(`${itemType} with ID ${itemId} does not exist`);
    }

    return result.Item;
}

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        // Parse request body
        const body = parseJSON(event.body || '{}');

        // Validate required fields
        validateRequired(body, ['userId', 'itemId', 'itemType', 'userEmail', 'userName']);

        // Validate existance of event or competition or course
        validateItemExists(body.itemId, body.itemType)

        const tableName = process.env.REGISTRATIONS_TABLE_NAME;
        const registrationId = `reg_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        const registrationItem = {
            id: registrationId,
            userId: body.userId,
            itemId: body.itemId, // Event, competition, or course ID
            itemType: body.itemType, // 'event', 'competition', or 'course'
            userEmail: body.userEmail,
            userName: body.userName,
            userPhone: body.userPhone || null,
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
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};