// Lambda function for creating Razorpay orders
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

async function validateItemExists(itemId, itemType) {
    let tableName;
    console.log("itemType", itemType, itemId);
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
const storeRegistrationRecord = async (body, registrationId) => {
    try {
        const tableName = process.env.REGISTRATIONS_TABLE_NAME;

        const registrationItem = {
            id: registrationId,
            userId: body.userId,
            itemId: body.itemId,
            itemType: body.itemType,
            userEmail: body.userEmail,
            userName: body.userName,
            userPhone: body.userPhone || null,
            userGender: body.userGender || null,
            userAge: body.userAge || null,
            userJoinCommunity: body.userJoinCommunity || null,
            registrationFee: body.amount || 0,
            paymentStatus: 'pending',
            paymentId: null,
            status: 'pending',
            paymentVia: 'whatsapp',
            notes: body.notes.details || null,
            registeredAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: registrationItem,
            ConditionExpression: 'attribute_not_exists(id)'
        });

        await docClient.send(command);
        console.log(`Registration record stored: ${registrationId}`);

        return registrationItem;
    } catch (error) {
        console.error('Error storing registration record:', error);
        throw new Error(`Failed to create registration: ${error.message}`);
    }
};

exports.handler = async (event) => {
    try {
        console.log('Create Pending Registration Event:', JSON.stringify(event, null, 2));

        // Parse body
        const body = parseJSON(event.body);

        // Validate required fields
        validateRequired(body, [
            'userId', 'itemId', 'itemType', 'userEmail', 'userPhone',
            'userName', 'userGender', 'userAge', 'userJoinCommunity', 'userEducation'
        ]);

        // Validate item exists
        await validateItemExists(body.itemId, body.itemType);

        // Generate registration ID
        const registrationId = `reg_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        // Store registration with paymentStatus = pending
        const registrationItem = await storeRegistrationRecord({
            ...body,
            amount: body.amount || 0,
        }, registrationId);

        const responseData = {
            registrationId: registrationItem.id,
            status: 'pending',
            message: 'You will be contacted soon for the payment',
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(responseData, 'Registration created with pending payment', 201);

    } catch (error) {
        console.error('Error in createRegistrationPending:', error);
        return errorResponse(error, 400);
    }
};
