const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const crypto = require('crypto');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client, {
    marshallOptions: {
        removeUndefinedValues: true // Automatically remove undefined values
    }
});

const removeUndefinedValues = (obj) => {
    const cleanObj = {};
    for (const key of Object.keys(obj)) {
        if (obj[key] !== undefined) {
            if (typeof obj[key] === 'object' && obj[key] !== null) {
                cleanObj[key] = removeUndefinedValues(obj[key]); // Recursively clean nested objects
            } else {
                cleanObj[key] = obj[key];
            }
        }
    }
    return cleanObj;
};

// Database helper functions
const createPaymentRecord = async (orderId, paymentId, paymentData) => {
    try {
        const tableName = process.env.PAYMENTS_TABLE_NAME;

        const paymentRecord = {
            orderId: orderId,
            paymentId: paymentId,
            amount: paymentData.amount,
            currency: paymentData.currency,
            status: paymentData.status,
            method: paymentData.method || null,
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            notes: paymentData.notes || {},
            metadata: {
                captured_at: paymentData.captured_at || null,
                created_at: paymentData.created_at || null,
                error_code: paymentData.error_code || null,
                error_description: paymentData.error_description || null
            }
        };

        const cleanPaymentRecord = removeUndefinedValues(paymentRecord);

        const command = new PutCommand({
            TableName: tableName,
            Item: cleanPaymentRecord,
            ConditionExpression: 'attribute_not_exists(paymentId)'
        });

        await docClient.send(command);
        console.log(`Payment record created: ${paymentId} for order: ${orderId}`);

        return cleanPaymentRecord;
    } catch (error) {
        if (error.name === 'ConditionalCheckFailedException') {
            console.log(`Payment record already exists: ${paymentId}`);
            return await getPaymentRecord(orderId, paymentId);
        }
        console.error('Error creating payment record:', error);
        throw new Error(`Failed to create payment record: ${error.message}`);
    }
};

const updatePaymentStatus = async (orderId, paymentId, status, paymentData = {}) => {
    try {
        const tableName = process.env.PAYMENTS_TABLE_NAME;

        let updateExpression = 'SET #status = :status, updatedAt = :updatedAt';
        const expressionAttributeNames = { '#status': 'status' };
        const expressionAttributeValues = {
            ':status': status,
            ':updatedAt': new Date().toISOString()
        };

        // Initialize metadata if it doesn't exist
        const existingRecord = await getPaymentRecord(orderId, paymentId);
        if (!existingRecord?.metadata) {
            updateExpression += ', metadata = :metadata';
            expressionAttributeValues[':metadata'] = {};
        }

        if (paymentData.captured_at) {
            updateExpression += ', metadata.captured_at = :captured_at';
            expressionAttributeValues[':captured_at'] = paymentData.captured_at;
        }

        if (paymentData.error_code) {
            updateExpression += ', metadata.error_code = :error_code, metadata.error_description = :error_description';
            expressionAttributeValues[':error_code'] = paymentData.error_code;
            expressionAttributeValues[':error_description'] = paymentData.error_description || null;
        }

        if (paymentData.notes) {
            updateExpression += ', notes = :notes';
            expressionAttributeValues[':notes'] = {
                ...existingRecord?.notes, // Preserve existing notes
                ...paymentData.notes // Merge with new notes
            };
        }

        // Update razorpayPaymentId if provided
        if (paymentData.razorpayPaymentId) {
            updateExpression += ', razorpayPaymentId = :razorpayPaymentId';
            expressionAttributeValues[':razorpayPaymentId'] = paymentData.razorpayPaymentId;
        }

        // Update method if provided
        if (paymentData.method) {
            updateExpression += ', #method = :method';
            expressionAttributeNames['#method'] = 'method'; // Handle reserved keyword
            expressionAttributeValues[':method'] = paymentData.method;
        }

        // Update order_status in metadata if provided
        if (paymentData.order_status) {
            updateExpression += ', metadata.order_status = :order_status';
            expressionAttributeValues[':order_status'] = paymentData.order_status;
        }

        const command = new UpdateCommand({
            TableName: tableName,
            Key: { orderId, paymentId },
            UpdateExpression: updateExpression,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        });

        const result = await docClient.send(command);
        console.log(`Payment status updated: ${paymentId} -> ${status}`);

        return result.Attributes;
    } catch (error) {
        console.error('Error updating payment status:', error);
        throw new Error(`Failed to update payment status: ${error.message}`);
    }
};

const getPaymentRecord = async (orderId, paymentId) => {
    try {
        const tableName = process.env.PAYMENTS_TABLE_NAME;

        const command = new GetCommand({
            TableName: tableName,
            Key: { orderId, paymentId }
        });

        const result = await docClient.send(command);
        return result.Item || null;
    } catch (error) {
        console.error('Error retrieving payment record:', error);
        throw new Error(`Failed to retrieve payment record: ${error.message}`);
    }
};

const updateRegistrationStatus = async (registrationId, paymentStatus, status, paymentId, additionalData = {}) => {
    try {
        if (!registrationId) {
            console.warn('No registrationId provided; skipping registration update');
            return null;
        }

        const tableName = process.env.REGISTRATIONS_TABLE_NAME;

        // Use placeholder for reserved keyword 'status'
        let updateExpression = 'SET paymentStatus = :paymentStatus, #status = :status, updatedAt = :updatedAt, paymentId = :paymentId';
        const expressionAttributeValues = {
            ':paymentStatus': paymentStatus,
            ':updatedAt': new Date().toISOString(),
            ':paymentId': paymentId,
            ':status': status
        };

        // Define ExpressionAttributeNames to handle reserved word
        const expressionAttributeNames = {
            '#status': 'status'
        };

        if (additionalData.error_description) {
            updateExpression += ', notes = :notes';
            expressionAttributeValues[':notes'] = additionalData.error_description;
        }

        const command = new UpdateCommand({
            TableName: tableName,
            Key: { id: registrationId },
            UpdateExpression: updateExpression,
            ExpressionAttributeValues: expressionAttributeValues,
            ExpressionAttributeNames: expressionAttributeNames, // <-- Added here
            ConditionExpression: 'attribute_exists(id)', // Ensure registration exists
            ReturnValues: 'ALL_NEW'
        });

        const result = await docClient.send(command);
        console.log(`Registration updated: ${registrationId} -> paymentStatus: ${paymentStatus}, paymentId: ${paymentId}`);
        return result.Attributes;
    } catch (error) {
        console.error('Error updating registration:', error);
        return null; // Don't throw; webhook should succeed for payment updates
    }
};

const createRefundRecord = async (refundData) => {
    try {
        const tableName = process.env.PAYMENTS_TABLE_NAME;

        const originalPayment = await getPaymentRecord(refundData.order_id || 'unknown', refundData.payment_id);

        const refundRecord = {
            orderId: originalPayment?.orderId || 'unknown',
            paymentId: `refund_${refundData.id}`,
            amount: -Math.abs(refundData.amount),
            currency: refundData.currency,
            status: 'refunded',
            method: 'refund',
            razorpayRefundId: refundData.id,
            razorpayPaymentId: refundData.payment_id,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            notes: originalPayment?.notes || {},
            metadata: {
                refund_status: refundData.status,
                created_at: refundData.created_at,
                original_payment_id: refundData.payment_id
            }
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: refundRecord
        });

        await docClient.send(command);
        console.log(`Refund record created: ${refundData.id} for payment: ${refundData.payment_id}`);

        return refundRecord;
    } catch (error) {
        console.error('Error creating refund record:', error);
        throw new Error(`Failed to create refund record: ${error.message}`);
    }
};

const validateWebhookSignature = (body, signature, secret) => {
    try {
        const receivedSignature = signature;
        const expectedSignature = crypto
            .createHmac('sha256', secret)
            .update(body, 'utf8')
            .digest('hex');

        const receivedBuffer = Buffer.from(receivedSignature, 'hex');
        const expectedBuffer = Buffer.from(expectedSignature, 'hex');

        if (receivedBuffer.length !== expectedBuffer.length) {
            return false;
        }

        return crypto.timingSafeEqual(receivedBuffer, expectedBuffer);
    } catch (error) {
        console.error('Error validating webhook signature:', error);
        return false;
    }
};

const processWebhookEvent = async (event, eventData) => {
    const { event: eventType, payload } = eventData;

    console.log(`Processing webhook event: ${eventType}`);
    console.log('Payload:', JSON.stringify(payload, null, 2));

    switch (eventType) {
        case 'payment.captured':
            await handleOrderPaid(payload.payment.entity, payload.payment.entity);
            break;
        case 'payment.failed':
            await handlePaymentFailed(payload.payment.entity);
            break;
        case 'payment.authorized':
            await handlePaymentAuthorized(payload.payment.entity);
            break;
        case 'order.paid':
            await handleOrderPaid(payload.order.entity, payload.payment.entity);
            break;
        case 'refund.created':
            await handleRefundCreated(payload.refund.entity);
            break;
        default:
            console.log(`Unhandled webhook event type: ${eventType}`);
            break;
    }

    return {
        eventType,
        processed: true,
        timestamp: new Date().toISOString(),
        requestId: event.requestContext?.requestId
    };
};

const handlePaymentFailed = async (payment) => {
    console.log('Payment Failed:', {
        paymentId: payment.id,
        orderId: payment.order_id,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        errorCode: payment.error_code,
        errorDescription: payment.error_description,
        failedAt: payment.created_at
    });

    try {
        let paymentRecord = await getPaymentRecord(payment.order_id, `order_${payment.order_id}`);
        if (paymentRecord) {
            paymentRecord = await updatePaymentStatus(payment.order_id, `order_${payment.order_id}`, 'failed', {
                ...payment,
                razorpayPaymentId: payment.id,
                method: payment.method || 'unknown',
                notes: { ...paymentRecord.notes, ...payment.notes }
            });
            console.log('Updated existing payment record:', paymentRecord);
        } else {
            paymentRecord = await getPaymentRecord(payment.order_id, payment.id);
            if (!paymentRecord) {
                console.log(`No record found for order_${payment.order_id}; creating new record with paymentId: ${payment.id}`);
                paymentRecord = await createPaymentRecord(payment.order_id, payment.id, {
                    ...payment,
                    notes: payment.notes || {},
                    originalAmount: payment.amount / 100
                });
            } else {
                paymentRecord = await updatePaymentStatus(payment.order_id, payment.id, 'failed', {
                    ...payment,
                    notes: { ...paymentRecord.notes, ...payment.notes }
                });
                console.log('Updated existing payment record with actual paymentId:', paymentRecord);
            }
        }

        const registrationId = payment.notes?.registrationId;
        await updateRegistrationStatus(registrationId, 'failed', 'failed', payment.id, payment);

        console.log('Payment failure saved to database:', paymentRecord);
        return paymentRecord;
    } catch (error) {
        console.error('Error handling payment failed event:', error);
        throw error;
    }
};

const handlePaymentAuthorized = async (payment) => {
    console.log('Payment Authorized:', {
        paymentId: payment.id,
        orderId: payment.order_id,
        amount: payment.amount,
        currency: payment.currency,
        status: payment.status,
        method: payment.method,
        authorizedAt: payment.created_at
    });

    try {
        let paymentRecord = await getPaymentRecord(payment.order_id, `order_${payment.order_id}`);
        if (paymentRecord) {
            paymentRecord = await updatePaymentStatus(payment.order_id, `order_${payment.order_id}`, 'authorized', {
                ...payment,
                razorpayPaymentId: payment.id,
                method: payment.method || 'unknown',
                notes: { ...paymentRecord.notes, ...payment.notes }
            });
            console.log('Updated existing payment record:', paymentRecord);
        } else {
            paymentRecord = await getPaymentRecord(payment.order_id, payment.id);
            if (!paymentRecord) {
                console.log(`No record found for order_${payment.order_id}; creating new record with paymentId: ${payment.id}`);
                paymentRecord = await createPaymentRecord(payment.order_id, payment.id, {
                    ...payment,
                    notes: payment.notes || {},
                    originalAmount: payment.amount / 100
                });
            } else {
                paymentRecord = await updatePaymentStatus(payment.order_id, payment.id, 'authorized', {
                    ...payment,
                    notes: { ...paymentRecord.notes, ...payment.notes }
                });
                console.log('Updated existing payment record with actual paymentId:', paymentRecord);
            }
        }

        const registrationId = payment.notes?.registrationId;
        await updateRegistrationStatus(registrationId, 'authorized', 'Sent but not received', payment.id, payment);

        console.log('Payment authorization saved to database:', paymentRecord);
        return paymentRecord;
    } catch (error) {
        console.error('Error handling payment authorized event:', error);
        throw error;
    }
};

const handleOrderPaid = async (order, payment) => {
    console.log('Order/Payment Paid or Captured:', {
        orderId: order.id || order.order_id,
        paymentId: payment.id,
        amount: order.amount || payment.amount,
        currency: order.currency || payment.currency,
        status: order.status || payment.status,
        method: payment.method,
        paidAt: order.created_at || payment.captured_at || new Date().toISOString()
    });

    try {
        const orderId = order.id || payment.order_id;
        const paymentId = payment.id;

        let paymentRecord = await getPaymentRecord(orderId, `order_${orderId}`);
        if (paymentRecord) {
            // Update existing placeholder record
            paymentRecord = await updatePaymentStatus(orderId, `order_${orderId}`, 'paid', {
                ...payment,
                order_status: 'paid',
                razorpayPaymentId: payment.id,
                method: payment.method || 'unknown',
                notes: { ...paymentRecord.notes, ...payment.notes }
            });
            console.log('Updated existing payment record:', paymentRecord);
        } else {
            // Check if actual paymentId exists
            paymentRecord = await getPaymentRecord(orderId, paymentId);
            if (!paymentRecord) {
                // Create new record
                console.log(`No record found for order_${order.id}; creating new record with paymentId: ${paymentId}`);
                paymentRecord = await createPaymentRecord(orderId, paymentId, {
                    ...payment,
                    notes: payment.notes || {},
                    originalAmount: (order.amount || payment.amount) / 100
                });
            } else {
                // Update existing real record
                paymentRecord = await updatePaymentStatus(orderId, paymentId, 'paid', {
                    ...payment,
                    order_status: 'paid',
                    notes: { ...paymentRecord.notes, ...payment.notes }
                });
                console.log('Updated existing payment record with actual paymentId:', paymentRecord);
            }
        }

        const registrationId = order.notes?.registrationId || payment.notes?.registrationId;
        await updateRegistrationStatus(registrationId, 'paid', 'paid', paymentId, { ...order, ...payment });

        console.log('Final Paid record saved to database:', paymentRecord);
        return paymentRecord;
    } catch (error) {
        console.error('Error handling order/payment paid event:', error);
        throw error;
    }
};

const handleRefundCreated = async (refund) => {
    console.log('Refund Created:', {
        refundId: refund.id,
        paymentId: refund.payment_id,
        amount: refund.amount,
        currency: refund.currency,
        status: refund.status,
        createdAt: refund.created_at
    });

    try {
        const refundRecord = await createRefundRecord(refund);

        const originalPayment = await getPaymentRecord(refund.order_id || 'unknown', refund.payment_id);
        const registrationId = originalPayment?.notes?.registrationId;
        await updateRegistrationStatus(registrationId, 'refunded', 'refunded', `refund_${refund.id}`, refund);

        console.log('Refund saved to database:', refundRecord);
        return refundRecord;
    } catch (error) {
        console.error('Error handling refund created event:', error);
        throw error;
    }
};

exports.handler = async (event) => {
    try {
        console.log('Webhook Event:', JSON.stringify(event, null, 2));

        const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
        if (!webhookSecret) {
            console.error('RAZORPAY_WEBHOOK_SECRET not configured');
            return errorResponse('Webhook secret not configured', 500);
        }

        const body = event.body;
        const signature = event.headers['x-razorpay-signature'] || event.headers['X-Razorpay-Signature'];

        if (!body) {
            return errorResponse('Missing request body', 400);
        }

        if (!signature) {
            return errorResponse('Missing webhook signature', 400);
        }

        const isValidSignature = validateWebhookSignature(body, signature, webhookSecret);

        if (!isValidSignature) {
            console.error('Invalid webhook signature');
            return errorResponse('Invalid signature', 400);
        }

        console.log('Webhook signature validated successfully');

        let webhookData;
        try {
            webhookData = JSON.parse(body);
        } catch (error) {
            console.error('Error parsing webhook JSON:', error);
            return errorResponse('Invalid JSON in webhook body', 400);
        }

        const result = await processWebhookEvent(event, webhookData);

        console.log('Webhook processed successfully:', result);

        return successResponse(result, 'Webhook processed successfully');
    } catch (error) {
        console.error('Error in payments_webhook function:', error);

        if (error.message && error.message.includes('Failed to')) {
            return errorResponse({
                message: 'Database operation failed',
                code: 'DATABASE_ERROR',
                details: error.message
            }, 500);
        }

        return errorResponse(error, 500);
    }
};