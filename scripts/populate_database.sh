#!/bin/bash

# EFY API Database Population Script
# This script populates the database with dummy data for testing

API_BASE_URL="https://d4ca8ryveb.execute-api.ap-south-1.amazonaws.com/default"

echo "🚀 Starting EFY API Database Population..."
echo "API Base URL: $API_BASE_URL"
echo ""

# Function to make POST request and show response
make_post_request() {
    local endpoint="$1"
    local data="$2"
    local description="$3"
    
    echo "📝 $description"
    echo "Endpoint: $endpoint"
    echo "Data: $data"
    
    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$data" \
        "$API_BASE_URL$endpoint")
    
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    if [ "$http_status" -eq 200 ]; then
        echo "✅ Success (HTTP $http_status)"
        echo "Response: $response_body"
    else
        echo "❌ Failed (HTTP $http_status)"
        echo "Response: $response_body"
    fi
    echo "----------------------------------------"
    echo ""
}

# 1. Create Events
echo "🎉 Creating Events..."

make_post_request "/events" '{
    "title": "Annual Tech Conference 2024",
    "description": "A comprehensive technology conference featuring the latest trends in AI, blockchain, and cloud computing. Join industry experts and network with peers.",
    "date": "2024-04-15T09:00:00Z",
    "location": "Mumbai Convention Center, Hall A",
    "category": "technology",
    "maxParticipants": 500,
    "registrationDeadline": "2024-04-10T23:59:59Z"
}' "Creating Annual Tech Conference"

make_post_request "/events" '{
    "title": "Green Energy Workshop",
    "description": "Learn about sustainable energy solutions and environmental conservation. Hands-on workshops on solar panel installation and energy efficiency.",
    "date": "2024-05-20T10:00:00Z",
    "location": "Delhi Environmental Center",
    "category": "environment",
    "maxParticipants": 100,
    "registrationDeadline": "2024-05-15T23:59:59Z"
}' "Creating Green Energy Workshop"

make_post_request "/events" '{
    "title": "Community Health Fair",
    "description": "Free health checkups, awareness sessions on preventive healthcare, and consultation with medical professionals.",
    "date": "2024-06-10T08:00:00Z",
    "location": "Bangalore Community Center",
    "category": "health",
    "maxParticipants": 300,
    "registrationDeadline": "2024-06-05T23:59:59Z"
}' "Creating Community Health Fair"

make_post_request "/events" '{
    "title": "Digital Literacy Program",
    "description": "Teaching basic computer skills and internet usage to senior citizens and underserved communities.",
    "date": "2024-07-01T14:00:00Z",
    "location": "Chennai Digital Learning Center",
    "category": "education",
    "maxParticipants": 50
}' "Creating Digital Literacy Program"

# 2. Create Competitions
echo "🏆 Creating Competitions..."

make_post_request "/competitions" '{
    "title": "CodeForGood Hackathon 2024",
    "description": "48-hour hackathon focused on developing solutions for social good. Build apps that make a positive impact on society.",
    "category": "technology",
    "startDate": "2024-08-15T18:00:00Z",
    "endDate": "2024-08-17T18:00:00Z",
    "registrationDeadline": "2024-08-10T23:59:59Z",
    "maxParticipants": 200,
    "rules": [
        "Teams of 2-4 members",
        "Original code only",
        "Must address a social issue",
        "Final presentation required"
    ],
    "prizes": [
        {"position": "1st", "amount": "₹1,00,000", "description": "First Prize + Internship opportunity"},
        {"position": "2nd", "amount": "₹50,000", "description": "Second Prize"},
        {"position": "3rd", "amount": "₹25,000", "description": "Third Prize"}
    ]
}' "Creating CodeForGood Hackathon"

make_post_request "/competitions" '{
    "title": "Sustainable Innovation Challenge",
    "description": "Design innovative solutions for environmental challenges. Focus on renewable energy, waste management, or sustainable agriculture.",
    "category": "environment",
    "startDate": "2024-09-01T09:00:00Z",
    "endDate": "2024-09-30T17:00:00Z",
    "registrationDeadline": "2024-08-25T23:59:59Z",
    "maxParticipants": 150,
    "rules": [
        "Individual or team participation",
        "Prototype required",
        "Environmental impact assessment needed",
        "Business model presentation"
    ],
    "prizes": [
        {"position": "1st", "amount": "₹2,00,000", "description": "Grand Prize + Mentorship"},
        {"position": "2nd", "amount": "₹1,00,000", "description": "Runner-up Prize"},
        {"position": "3rd", "amount": "₹50,000", "description": "Innovation Award"}
    ]
}' "Creating Sustainable Innovation Challenge"

make_post_request "/competitions" '{
    "title": "Youth Leadership Essay Contest",
    "description": "Write essays on leadership, social change, and community development. Open to students aged 16-25.",
    "category": "education",
    "startDate": "2024-10-01T00:00:00Z",
    "endDate": "2024-10-31T23:59:59Z",
    "registrationDeadline": "2024-09-25T23:59:59Z",
    "maxParticipants": 500,
    "rules": [
        "1000-1500 words",
        "Original work only",
        "Age verification required",
        "English or Hindi language"
    ],
    "prizes": [
        {"position": "1st", "amount": "₹25,000", "description": "First Prize + Publication opportunity"},
        {"position": "2nd", "amount": "₹15,000", "description": "Second Prize"},
        {"position": "3rd", "amount": "₹10,000", "description": "Third Prize"}
    ]
}' "Creating Youth Leadership Essay Contest"

# 3. Submit Volunteer Applications
echo "🤝 Creating Volunteer Applications..."

make_post_request "/volunteers/join" '{
    "name": "Priya Sharma",
    "email": "priya.sharma@example.com",
    "phone": "+91-9876543210",
    "skills": ["Event Management", "Communication", "Leadership"],
    "availability": "Weekends and evenings",
    "experience": "3 years of volunteer experience with NGOs",
    "motivation": "Passionate about making a positive impact in the community",
    "preferredRoles": ["Event Coordinator", "Community Outreach"]
}' "Creating volunteer application for Priya Sharma"

make_post_request "/volunteers/join" '{
    "name": "Rahul Gupta",
    "email": "rahul.gupta@example.com",
    "phone": "+91-9876543211",
    "skills": ["Web Development", "Teaching", "Technical Writing"],
    "availability": "Flexible, can work 10-15 hours per week",
    "experience": "Software engineer with passion for education",
    "motivation": "Want to use my technical skills to help others learn",
    "preferredRoles": ["Technical Mentor", "Workshop Facilitator"]
}' "Creating volunteer application for Rahul Gupta"

make_post_request "/volunteers/join" '{
    "name": "Anjali Reddy",
    "email": "anjali.reddy@example.com",
    "phone": "+91-9876543212",
    "skills": ["Healthcare", "First Aid", "Public Speaking"],
    "availability": "Weekends only",
    "experience": "Nurse with 5 years of clinical experience",
    "motivation": "Committed to improving community health outcomes",
    "preferredRoles": ["Health Advisor", "Medical Support"]
}' "Creating volunteer application for Anjali Reddy"

make_post_request "/volunteers/join" '{
    "name": "Vikram Singh",
    "email": "vikram.singh@example.com",
    "phone": "+91-9876543213",
    "skills": ["Photography", "Social Media", "Marketing"],
    "availability": "3-4 days per week",
    "experience": "Freelance photographer and digital marketer",
    "motivation": "Love capturing moments and promoting good causes",
    "preferredRoles": ["Event Photographer", "Social Media Manager"]
}' "Creating volunteer application for Vikram Singh"

make_post_request "/volunteers/join" '{
    "name": "Meera Patel",
    "email": "meera.patel@example.com",
    "phone": "+91-9876543214",
    "skills": ["Teaching", "Counseling", "Child Psychology"],
    "availability": "Mornings and early afternoons",
    "experience": "Former school teacher with specialization in special needs education",
    "motivation": "Dedicated to helping children reach their full potential",
    "preferredRoles": ["Education Coordinator", "Youth Mentor"]
}' "Creating volunteer application for Meera Patel"

# 4. Submit Suggestions
echo "💡 Creating Suggestions..."

make_post_request "/suggestions" '{
    "title": "Mobile App for Event Registration",
    "description": "Develop a user-friendly mobile application that allows participants to easily register for events, receive notifications, and access event materials on their smartphones.",
    "category": "technology",
    "submitterName": "Tech Enthusiast",
    "submitterEmail": "tech.user@example.com",
    "priority": "high",
    "tags": ["mobile", "app", "user-experience", "registration"]
}' "Creating mobile app suggestion"

make_post_request "/suggestions" '{
    "title": "Eco-Friendly Event Materials",
    "description": "Implement sustainable practices by using biodegradable materials for event supplies, digital certificates instead of paper, and reusable name tags.",
    "category": "environment",
    "submitterName": "Green Advocate",
    "submitterEmail": "green.advocate@example.com",
    "priority": "medium",
    "tags": ["sustainability", "eco-friendly", "waste-reduction"]
}' "Creating eco-friendly materials suggestion"

make_post_request "/suggestions" '{
    "title": "Mentorship Program for New Volunteers",
    "description": "Create a structured mentorship program where experienced volunteers guide newcomers, helping them integrate into the organization and develop their skills.",
    "category": "community",
    "submitterName": "Volunteer Coordinator",
    "submitterEmail": "coordinator@example.com",
    "priority": "high",
    "tags": ["mentorship", "training", "volunteer-development"]
}' "Creating mentorship program suggestion"

make_post_request "/suggestions" '{
    "title": "Partnership with Local Schools",
    "description": "Establish partnerships with local schools to promote events and competitions among students, creating a pipeline of young participants.",
    "category": "education",
    "submitterName": "Education Advocate",
    "priority": "medium",
    "tags": ["partnership", "schools", "outreach", "youth-engagement"]
}' "Creating school partnership suggestion"

make_post_request "/suggestions" '{
    "title": "Virtual Reality Training Sessions",
    "description": "Use VR technology to provide immersive training experiences for volunteers, especially for scenarios that are difficult to simulate in real life.",
    "category": "technology",
    "submitterName": "Innovation Team",
    "submitterEmail": "innovation@example.com",
    "priority": "low",
    "tags": ["VR", "training", "innovation", "simulation"]
}' "Creating VR training suggestion"

make_post_request "/suggestions" '{
    "title": "Community Impact Dashboard",
    "description": "Create a public dashboard showing the impact of all events and competitions - participants reached, communities served, and outcomes achieved.",
    "category": "transparency",
    "submitterName": "Data Analyst",
    "submitterEmail": "data.analyst@example.com",
    "priority": "medium",
    "tags": ["dashboard", "impact", "transparency", "metrics"]
}' "Creating impact dashboard suggestion"

echo ""
echo "🎯 Database population completed!"
echo ""
echo "📊 Summary of created records:"
echo "• Events: 4 records"
echo "• Competitions: 3 records"
echo "• Volunteer Applications: 5 records"
echo "• Suggestions: 6 records"
echo ""
echo "🔗 You can now test the GET endpoints to verify the data:"
echo "• GET $API_BASE_URL/events"
echo "• GET $API_BASE_URL/competitions"
echo "• GET $API_BASE_URL/volunteers"
echo "• GET $API_BASE_URL/suggestions"
echo ""
echo "✨ All done! Your EFY API database is now populated with comprehensive dummy data."