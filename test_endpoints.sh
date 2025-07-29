#!/bin/bash

# Simple test script for individual endpoints
API_BASE_URL="https://d4ca8ryveb.execute-api.ap-south-1.amazonaws.com/default"

echo "🧪 Testing Individual POST Endpoints..."
echo "API Base URL: $API_BASE_URL"
echo ""

# Test Events POST
echo "1️⃣ Testing Events POST endpoint:"
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Simple Test Event",
    "description": "A basic test event",
    "date": "2024-04-15T09:00:00Z",
    "location": "Test Location"
  }' \
  "$API_BASE_URL/events"
echo ""
echo ""

# Test Competitions POST
echo "2️⃣ Testing Competitions POST endpoint:"
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Simple Test Competition",
    "description": "A basic test competition",
    "category": "technology",
    "startDate": "2024-08-15T18:00:00Z",
    "endDate": "2024-08-17T18:00:00Z"
  }' \
  "$API_BASE_URL/competitions"
echo ""
echo ""

# Test Volunteers POST
echo "3️⃣ Testing Volunteers POST endpoint:"
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Volunteer",
    "email": "test@example.com",
    "skills": ["Testing"],
    "availability": "Weekends"
  }' \
  "$API_BASE_URL/volunteers/join"
echo ""
echo ""

# Test Suggestions POST
echo "4️⃣ Testing Suggestions POST endpoint:"
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Simple Test Suggestion",
    "description": "A basic test suggestion",
    "category": "improvement"
  }' \
  "$API_BASE_URL/suggestions"
echo ""
echo ""

echo "✅ Test completed!"