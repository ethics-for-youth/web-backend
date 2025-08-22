// Lambda function for creating Razorpay orders
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const Razorpay = require('razorpay');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// Database helper function
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
            metadata: {
                receipt: order.receipt,
                notes: notes || {},
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
        // Don't throw error here as order creation should succeed even if DB fails
        console.warn('Order created successfully but failed to store in database. Payment webhook will handle this.');
        return null;
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
        
        // Validate required fields
        validateRequired(body, ['amount']);
        
        // Extract and validate parameters
        const { amount, currency = 'INR', receipt, notes = {} } = body;
        
        // Validate amount
        if (!amount || amount <= 0) {
            throw new Error('Amount must be a positive number');
        }
        
        // Convert amount to smallest currency unit (paise for INR)
        const amountInSmallestUnit = Math.round(amount * 100);
        
        // Initialize Razorpay
        const razorpay = initializeRazorpay();
        
        // Create order options
        const orderOptions = {
            amount: amountInSmallestUnit,
            currency: currency.toUpperCase(),
            receipt: receipt || `receipt_${Date.now()}`,
            notes: {
                ...notes,
                created_via: 'efy_backend_lambda',
                created_at: new Date().toISOString()
            }
        };
        
        console.log('Creating order with options:', orderOptions);
        
        // Create order using Razorpay SDK
        const order = await razorpay.orders.create(orderOptions);
        
        console.log('Order created successfully:', order);
        
        // Store order record in database (non-blocking)
        await storeOrderRecord(order, amount, notes);
        
        // Prepare response data
        const responseData = {
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
            status: order.status,
            receipt: order.receipt,
            notes: order.notes,
            createdAt: order.created_at,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(responseData, 'Order created successfully', 201);
        
    } catch (error) {
        console.error('Error in payments_create_order function:', error);
        
        // Handle Razorpay specific errors
        if (error.statusCode) {
            return errorResponse({
                message: error.error?.description || error.message,
                code: error.error?.code || 'RAZORPAY_ERROR',
                details: error.error
            }, error.statusCode);
        }
        
        // Handle validation and other errors
        return errorResponse(error, 400);
    }
};