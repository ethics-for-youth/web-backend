#!/bin/bash

# Test script for Razorpay payment integration with database
echo "🧪 Testing Razorpay Payment Integration with Database"
echo ""

# Check if API_BASE_URL is provided
if [ -z "$API_BASE_URL" ]; then
    echo "❌ Please set API_BASE_URL environment variable"
    echo "Example: export API_BASE_URL=https://your-api-gateway-url"
    exit 1
fi

echo "🌐 API Base URL: $API_BASE_URL"
echo ""

# Test 1: Create Payment Order
echo "1️⃣ Testing Create Payment Order endpoint:"
echo "Request: POST $API_BASE_URL/payments/create-order"

CREATE_ORDER_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 150.00,
    "currency": "INR",
    "receipt": "test_order_'$(date +%s)'",
    "notes": {
      "customer_id": "test_user_123",
      "event_id": "test_event_456",
      "test_mode": true,
      "purpose": "integration_test"
    }
  }' \
  "$API_BASE_URL/payments/create-order")

# Extract HTTP status
HTTP_STATUS=$(echo "$CREATE_ORDER_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$CREATE_ORDER_RESPONSE" | sed '/HTTP_STATUS:/d')

echo "Response Status: $HTTP_STATUS"
echo "Response Body:"
echo "$RESPONSE_BODY" | jq . 2>/dev/null || echo "$RESPONSE_BODY"
echo ""

# Check if order creation was successful
if [ "$HTTP_STATUS" = "201" ]; then
    echo "✅ Order creation test passed"
    
    # Extract order ID for webhook test
    ORDER_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.orderId' 2>/dev/null)
    
    if [ "$ORDER_ID" != "null" ] && [ -n "$ORDER_ID" ]; then
        echo "📝 Created Order ID: $ORDER_ID"
        
        # Test 2: Simulate Webhook Event
        echo ""
        echo "2️⃣ Testing Webhook endpoint with simulated payment.captured event:"
        echo "Request: POST $API_BASE_URL/payments/webhook"
        
        # Generate a fake signature for testing (in real scenario, this comes from Razorpay)
        WEBHOOK_SECRET="test_webhook_secret_123"
        WEBHOOK_PAYLOAD='{
          "event": "payment.captured",
          "payload": {
            "payment": {
              "entity": {
                "id": "pay_test_'$(date +%s)'",
                "order_id": "'$ORDER_ID'",
                "amount": 15000,
                "currency": "INR",
                "status": "captured",
                "method": "card",
                "captured_at": '$(date +%s)',
                "created_at": '$(date +%s)'
              }
            }
          }
        }'
        
        # Generate HMAC signature (simplified for testing)
        SIGNATURE=$(echo -n "$WEBHOOK_PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -hex | awk '{print $2}')
        
        WEBHOOK_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
          -H "Content-Type: application/json" \
          -H "X-Razorpay-Signature: $SIGNATURE" \
          -d "$WEBHOOK_PAYLOAD" \
          "$API_BASE_URL/payments/webhook")
        
        # Extract HTTP status
        WEBHOOK_HTTP_STATUS=$(echo "$WEBHOOK_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
        WEBHOOK_RESPONSE_BODY=$(echo "$WEBHOOK_RESPONSE" | sed '/HTTP_STATUS:/d')
        
        echo "Response Status: $WEBHOOK_HTTP_STATUS"
        echo "Response Body:"
        echo "$WEBHOOK_RESPONSE_BODY" | jq . 2>/dev/null || echo "$WEBHOOK_RESPONSE_BODY"
        echo ""
        
        if [ "$WEBHOOK_HTTP_STATUS" = "200" ]; then
            echo "✅ Webhook processing test passed"
        else
            echo "❌ Webhook processing test failed"
            echo "💡 Note: Webhook might fail due to signature validation in production"
        fi
    else
        echo "❌ Could not extract order ID from response"
    fi
else
    echo "❌ Order creation test failed"
    echo "💡 Check API Gateway URL and Lambda function configuration"
fi

echo ""
echo "🔍 Test Summary:"
echo "- Create Order: $([ "$HTTP_STATUS" = "201" ] && echo "✅ PASSED" || echo "❌ FAILED")"
echo "- Webhook Processing: $([ "$WEBHOOK_HTTP_STATUS" = "200" ] && echo "✅ PASSED" || echo "❌ FAILED" && echo "ℹ️  CHECK LOGS")"
echo ""
echo "📋 Next Steps:"
echo "1. Check CloudWatch logs for detailed information:"
echo "   - /aws/lambda/efy-web-backend-{env}-payments-create-order"
echo "   - /aws/lambda/efy-web-backend-{env}-payments-webhook"
echo "2. Check DynamoDB table for stored payment records:"
echo "   - Table: efy-web-backend-{env}-payments"
echo "3. Verify Razorpay webhook configuration in dashboard"
echo ""
echo "🔗 Useful Commands:"
echo "# Check DynamoDB records:"
echo "aws dynamodb scan --table-name efy-web-backend-dev-payments --region ap-south-1"
echo ""
echo "# View Lambda logs:"
echo "aws logs tail /aws/lambda/efy-web-backend-dev-payments-create-order --follow"
echo "aws logs tail /aws/lambda/efy-web-backend-dev-payments-webhook --follow"