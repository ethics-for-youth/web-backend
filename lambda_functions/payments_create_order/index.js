// Lambda function for creating Razorpay orders
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const Razorpay = require('razorpay');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Validate item exists (event, competition, or course)
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

// Database helper function for order storage
const storeOrderRecord = async (order, originalAmount, notes) => {
    try {
        const tableName = process.env.PAYMENTS_TABLE_NAME;

        const orderRecord = {
            orderId: order.id,
            paymentId: `order_${order.id}`, // Temporary payment ID for order record
            amount: order.amount,
            currency: order.currency,
            status: 'created',
            method: 'pending',
            razorpayOrderId: order.id,
            razorpayPaymentId: null, // Will be updated when payment is made
            originalAmount: originalAmount, // Store original amount in major currency unit
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            notes: notes || {},
            metadata: {
                receipt: order.receipt,
                razorpay_created_at: order.created_at,
                order_status: 'created'
            }
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: orderRecord
        });

        await docClient.send(command);
        console.log(`Order record stored: ${order.id}`);

        return orderRecord;
    } catch (error) {
        console.error('Error storing order record:', error);
        console.warn('Order created successfully but failed to store in database. Payment webhook will handle this.');
        return null;
    }
};

// Database helper function for registration storage
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
            registrationFee: body.amount || 0,
            paymentStatus: 'pending',
            paymentId: null,
            status: 'pending',
            notes: body.notes || null,
            registeredAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: registrationItem,
            ConditionExpression: 'attribute_not_exists(id)' // Prevent overwriting
        });

        await docClient.send(command);
        console.log(`Registration record stored: ${registrationId}`);

        return registrationItem;
    } catch (error) {
        console.error('Error storing registration record:', error);
        throw new Error(`Failed to create registration: ${error.message}`);
    }
};

// Initialize Razorpay instance
let razorpayInstance;

const initializeRazorpay = () => {
    if (!razorpayInstance) {
        const keyId = process.env.RAZORPAY_KEY_ID;
        const keySecret = process.env.RAZORPAY_KEY_SECRET;

        if (!keyId || !keySecret) {
            throw new Error('Razorpay credentials not configured. Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET environment variables.');
        }

        razorpayInstance = new Razorpay({
            key_id: keyId,
            key_secret: keySecret,
        });
    }
    return razorpayInstance;
};

exports.handler = async (event) => {
    try {
        console.log('Create Order Event:', JSON.stringify(event, null, 2));

        // Parse request body
        const body = parseJSON(event.body);

        // Validate required fields for both order and registration
        validateRequired(body, ['amount', 'userId', 'itemId', 'itemType', 'userEmail', 'userName']);

        // Validate amount
        if (!body.amount || body.amount <= 0) {
            throw new Error('Amount must be a positive number');
        }

        // Validate existence of event, competition, or course
        await validateItemExists(body.itemId, body.itemType);

        // Generate registration ID
        const registrationId = `reg_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        // Store registration record
        const registrationItem = await storeRegistrationRecord(body, registrationId);

        // Convert amount to smallest currency unit (paise for INR)
        const amountInSmallestUnit = Math.round(body.amount * 100);

        // Initialize Razorpay
        const razorpay = initializeRazorpay();

        // Create order options with registrationId in notes
        const orderOptions = {
            amount: amountInSmallestUnit,
            currency: body.currency?.toUpperCase() || 'INR',
            receipt: body.receipt || `receipt_${Date.now()}`,
            notes: {
                registrationId: registrationId,
                created_via: 'efy_backend_lambda',
                created_at: new Date().toISOString(),
            }
        };

        console.log('Creating order with options:', orderOptions);

        // Create order using Razorpay SDK
        const order = await razorpay.orders.create(orderOptions);

        console.log('Order created successfully:', order);

        // Store order record in database (non-blocking)
        await storeOrderRecord(order, body.amount, orderOptions.notes);

        // Prepare response data
        const responseData = {
            orderId: order.id,
            registrationId: registrationItem.id,
            amount: order.amount,
            currency: order.currency,
            status: order.status,
            receipt: order.receipt,
            notes: order.notes,
            createdAt: order.created_at,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(responseData, 'Order and registration created successfully', 201);

    } catch (error) {
        console.error('Error in payments_create_order function:', error);

        // Handle Razorpay-specific errors
        if (error.statusCode) {
            return errorResponse({
                message: error.error?.description || error.message,
                code: error.error?.code || 'RAZORPAY_ERROR',
                details: error.error
            }, error.statusCode);
        }

        // Handle item validation errors
        if (error.code === "ITEM_NOT_FOUND") {
            return errorResponse(error, 404);
        } else if (error.message.startsWith('Invalid itemType')) {
            return errorResponse(error, 400);
        } else if (error.message.includes('Failed to create registration')) {
            return errorResponse(error, 500);
        }

        // Handle validation and other errors
        return errorResponse(error, 400);
    }
};