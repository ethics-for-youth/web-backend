# Razorpay Payment Gateway Setup Guide

This guide explains how to set up and deploy the Razorpay payment gateway integration with AWS Lambda and API Gateway.

## 🏗️ Architecture Overview

The payment system consists of:
- **`/payments/create-order`** - Lambda function that creates Razorpay orders
- **`/payments/webhook`** - Lambda function that handles Razorpay webhook events
- **Razorpay SDK** - Integrated as a shared dependency in Lambda layers
- **Environment Variables** - Secure storage of API keys and secrets

## 📋 Prerequisites

1. **Razorpay Account**: Sign up at [razorpay.com](https://razorpay.com) and get test credentials
2. **AWS CLI** configured with appropriate permissions
3. **Terraform** >= 1.0 installed
4. **Node.js** 18.x+ installed
5. **Existing EFY Backend** infrastructure deployed

## 🔑 Razorpay Credentials Setup

### Step 1: Get Razorpay Test Credentials

1. Log in to [Razorpay Dashboard](https://dashboard.razorpay.com)
2. Navigate to **Settings** → **API Keys**
3. Download **Test Mode** credentials:
   - `Key ID` (starts with `rzp_test_`)
   - `Key Secret` (starts with `rz_test_`)

### Step 2: Generate Webhook Secret

1. In Razorpay Dashboard, go to **Settings** → **Webhooks**
2. Click **Create Webhook**
3. Set webhook URL: `https://your-api-domain/payments/webhook`
4. Select events to track:
   - `payment.captured`
   - `payment.failed`
   - `payment.authorized`
   - `order.paid`
   - `refund.created`
5. Generate and save the **Webhook Secret**

## 🚀 Deployment Steps

### Step 1: Add Razorpay Credentials to Terraform Variables

Create or update your environment-specific `.tfvars` file:

```bash
# terraform/terraform.dev.tfvars
razorpay_key_id         = "rzp_test_your_key_id_here"
razorpay_key_secret     = "your_secret_key_here"
razorpay_webhook_secret = "your_webhook_secret_here"
```

⚠️ **Security Note**: Keep these files in `.gitignore` and never commit credentials to version control.

### Step 2: Install Dependencies

```bash
# Install Razorpay SDK in the dependencies layer
npm run install:layers
```

### Step 3: Deploy Infrastructure

```bash
# Validate configuration
npm run validate

# Plan deployment
npm run plan:dev

# Deploy to development
npm run deploy:dev
```

### Step 4: Configure Razorpay Webhook URL

After deployment, get your API Gateway URL:

```bash
# Get the API Gateway URL from Terraform outputs
cd terraform
terraform output api_gateway_url
```

Update your Razorpay webhook URL to:
```
https://your-api-gateway-url/payments/webhook
```

## 📡 API Endpoints

### POST /payments/create-order

Creates a new payment order with Razorpay.

**Request:**
```json
{
  \"amount\": 100.00,
  \"currency\": \"INR\",
  \"receipt\": \"order_receipt_123\",
  \"notes\": {
    \"customer_id\": \"cust_123\",
    \"event_id\": \"event_456\"
  }
}
```

**Response:**
```json
{
  \"success\": true,
  \"message\": \"Order created successfully\",
  \"data\": {
    \"orderId\": \"order_razorpay_order_id\",
    \"amount\": 10000,
    \"currency\": \"INR\",
    \"status\": \"created\",
    \"receipt\": \"order_receipt_123\",
    \"notes\": {
      \"customer_id\": \"cust_123\",
      \"event_id\": \"event_456\",
      \"created_via\": \"efy_backend_lambda\",
      \"created_at\": \"2024-01-01T10:00:00.000Z\"
    },
    \"createdAt\": 1704096000,
    \"requestId\": \"aws-request-id\",
    \"timestamp\": \"2024-01-01T10:00:00.000Z\"
  }
}
```

**Error Response:**
```json
{
  \"success\": false,
  \"error\": {
    \"message\": \"Amount must be a positive number\",
    \"code\": \"VALIDATION_ERROR\"
  }
}
```

### POST /payments/webhook

Handles Razorpay webhook events for payment status updates.

**Headers Required:**
```
X-Razorpay-Signature: webhook_signature_from_razorpay
Content-Type: application/json
```

**Sample Webhook Payload:**
```json
{
  \"event\": \"payment.captured\",
  \"payload\": {
    \"payment\": {
      \"entity\": {
        \"id\": \"pay_razorpay_payment_id\",
        \"order_id\": \"order_razorpay_order_id\",
        \"amount\": 10000,
        \"currency\": \"INR\",
        \"status\": \"captured\",
        \"method\": \"card\",
        \"captured_at\": 1704096000
      }
    }
  }
}
```

**Response:**
```json
{
  \"success\": true,
  \"message\": \"Webhook processed successfully\",
  \"data\": {
    \"eventType\": \"payment.captured\",
    \"processed\": true,
    \"timestamp\": \"2024-01-01T10:00:00.000Z\",
    \"requestId\": \"aws-request-id\"
  }
}
```

## 🧪 Testing

### Test Create Order Endpoint

```bash
curl -X POST https://your-api-gateway-url/payments/create-order \\
  -H \"Content-Type: application/json\" \\
  -d '{
    \"amount\": 100.00,
    \"currency\": \"INR\",
    \"receipt\": \"test_receipt_123\"
  }'
```

### Test with Frontend Integration

Use the order ID returned from `/create-order` with Razorpay Checkout:

```javascript
const options = {
  key: 'rzp_test_your_key_id',
  amount: data.amount, // Amount from create-order response
  currency: data.currency,
  order_id: data.orderId, // Order ID from create-order response
  name: 'Ethics For Youth',
  description: 'Event Registration Payment',
  handler: function(response) {
    console.log('Payment successful:', response);
    // Handle successful payment
  },
  modal: {
    ondismiss: function() {
      console.log('Payment cancelled');
    }
  }
};

const rzp = new Razorpay(options);
rzp.open();
```

### Webhook Testing

1. Use Razorpay's webhook testing tool in the dashboard
2. Or use ngrok for local testing:
   ```bash
   ngrok http 3000
   # Use the ngrok URL as your webhook URL in Razorpay dashboard
   ```

## 🔧 Environment Variables

Each Lambda function automatically receives these environment variables:

**Create Order Function:**
- `RAZORPAY_KEY_ID` - Your Razorpay API Key ID
- `RAZORPAY_KEY_SECRET` - Your Razorpay API Secret

**Webhook Function:**
- `RAZORPAY_WEBHOOK_SECRET` - Secret for webhook signature validation

## 📊 Monitoring and Logging

### CloudWatch Logs

Monitor Lambda function logs in AWS CloudWatch:
- `/aws/lambda/efy-web-backend-dev-payments-create-order`
- `/aws/lambda/efy-web-backend-dev-payments-webhook`

### Key Log Events

**Successful Order Creation:**
```
[INFO] Creating order with options: {amount: 10000, currency: 'INR', ...}
[INFO] Order created successfully: {id: 'order_...', ...}
```

**Webhook Processing:**
```
[INFO] Webhook signature validated successfully
[INFO] Processing webhook event: payment.captured
[INFO] Payment Captured: {paymentId: 'pay_...', orderId: 'order_...', ...}
```

**Error Examples:**
```
[ERROR] Invalid webhook signature
[ERROR] Razorpay API Error: {statusCode: 400, error: {...}}
```

## 🛡️ Security Best Practices

1. **Environment Variables**: Store all secrets as encrypted environment variables
2. **Webhook Validation**: Always validate webhook signatures using HMAC SHA256
3. **HTTPS Only**: Use HTTPS for all API endpoints
4. **IP Whitelisting**: Consider whitelisting Razorpay IPs for webhook endpoints
5. **Rate Limiting**: Implement rate limiting for payment endpoints
6. **Logging**: Log payment events for audit trails (exclude sensitive data)

## 💾 Database Integration

The payment system now includes full DynamoDB integration for persistent storage of payment data.

### Database Schema

**Payments Table**: `efy-web-backend-{environment}-payments`

**Primary Key:**
- `orderId` (Hash Key) - Razorpay order ID
- `paymentId` (Range Key) - Razorpay payment ID or unique identifier

**Attributes:**
```json
{
  "orderId": "order_29QQoUBi66xm2f",
  "paymentId": "pay_29QQoUBi66xm2f",
  "amount": 15000,
  "currency": "INR", 
  "status": "captured",
  "method": "card",
  "razorpayOrderId": "order_29QQoUBi66xm2f",
  "razorpayPaymentId": "pay_29QQoUBi66xm2f",
  "originalAmount": 150.00,
  "createdAt": "2024-01-25T10:30:00Z",
  "updatedAt": "2024-01-25T10:31:00Z",
  "metadata": {
    "receipt": "event_reg_123",
    "notes": {
      "customer_id": "user_123",
      "event_id": "event_456"
    },
    "captured_at": 1704096060,
    "created_at": 1704096000,
    "error_code": null,
    "error_description": null
  }
}
```

**Global Secondary Indexes:**
1. **StatusIndex** - Query by payment status and creation time
   - Hash Key: `status`
   - Range Key: `createdAt`
   
2. **PaymentIndex** - Query by payment ID only
   - Hash Key: `paymentId`

### Payment Flow with Database

1. **Order Creation** (`/payments/create-order`):
   - Creates Razorpay order
   - Stores initial order record in DynamoDB
   - Status: `created`, Method: `pending`

2. **Payment Processing** (via webhooks):
   - `payment.authorized` → Updates status to `authorized`
   - `payment.captured` → Updates status to `captured`
   - `payment.failed` → Updates status to `failed`
   - `order.paid` → Updates status to `paid`

3. **Refund Processing**:
   - `refund.created` → Creates new record with negative amount
   - Status: `refunded`, Method: `refund`

### Database Operations

**Automatic Operations:**
- Order records created during order creation
- Payment status updates via webhook events
- Refund records for refund events
- Idempotent operations (duplicate events handled gracefully)

**Query Examples:**
```bash
# Get all payments for an order
aws dynamodb query \
  --table-name efy-web-backend-dev-payments \
  --key-condition-expression "orderId = :orderId" \
  --expression-attribute-values '{":orderId":{"S":"order_29QQoUBi66xm2f"}}'

# Get payments by status
aws dynamodb query \
  --table-name efy-web-backend-dev-payments \
  --index-name StatusIndex \
  --key-condition-expression "#status = :status" \
  --expression-attribute-names '{"#status":"status"}' \
  --expression-attribute-values '{":status":{"S":"captured"}}'

# Get specific payment
aws dynamodb get-item \
  --table-name efy-web-backend-dev-payments \
  --key '{"orderId":{"S":"order_29QQoUBi66xm2f"},"paymentId":{"S":"pay_29QQoUBi66xm2f"}}'
```

### Error Handling

**Database Error Handling:**
- Non-blocking order creation (order succeeds even if DB write fails)
- Webhook events retry automatically via DynamoDB
- Idempotent operations prevent duplicate records
- Comprehensive error logging for troubleshooting

**Graceful Degradation:**
- Order creation continues if database is unavailable
- Webhook will recreate missing records
- Payment flow remains functional during DB issues

## 🧪 Testing Database Integration

Use the provided test script to validate the complete payment flow:

```bash
# Set your API Gateway URL
export API_BASE_URL="https://your-api-gateway-url"

# Run integration test
./scripts/test_payment_integration.sh
```

**Test Coverage:**
1. Creates a payment order via API
2. Verifies order record in database
3. Simulates webhook event processing
4. Validates payment status updates
5. Checks error handling scenarios

## 🚨 Troubleshooting

### Common Issues

1. **\"Invalid signature\" webhook errors**
   - Verify `RAZORPAY_WEBHOOK_SECRET` matches dashboard
   - Check webhook URL is correct
   - Ensure HTTPS is used

2. **\"Razorpay credentials not configured\"**
   - Verify environment variables are set in Terraform
   - Check `.tfvars` file has correct values
   - Redeploy after adding credentials

3. **\"Amount must be a positive number\"**
   - Ensure amount is sent as a number, not string
   - Amount should be in the major currency unit (INR, USD)

4. **Lambda timeout errors**
   - Check CloudWatch logs for specific errors
   - Verify network connectivity to Razorpay APIs
   - Increase Lambda timeout if needed

### Support Resources

- [Razorpay API Documentation](https://razorpay.com/docs/api/)
- [Razorpay Node.js SDK](https://www.npmjs.com/package/razorpay)
- [Razorpay Webhook Guide](https://razorpay.com/docs/payments/payment-gateway/webhooks/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)

## 📝 Next Steps

1. **Test thoroughly** in Razorpay's test mode
2. **Implement database storage** for payment records
3. **Add payment status endpoints** for frontend queries
4. **Set up monitoring alerts** for payment failures
5. **Configure production credentials** when ready to go live
6. **Implement refund functionality** if needed
7. **Add payment analytics** and reporting features