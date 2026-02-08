#!/bin/bash

# EFY API Database Population Script
# This script populates the database with dummy data for testing

API_BASE_URL="https://dev.efy.org.in/api"

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

# 3. Create Courses
echo "📚 Creating Courses..."

make_post_request "/courses" '{
    "title": "Quran Memorization Fundamentals",
    "description": "Learn effective techniques for memorizing the Holy Quran with proper tajweed and pronunciation. Suitable for beginners and intermediate learners.",
    "instructor": "Sheikh Ahmed Al-Hafiz",
    "duration": "8 weeks",
    "category": "religious-studies",
    "level": "beginner",
    "maxParticipants": 30,
    "startDate": "2024-02-15T14:00:00Z",
    "endDate": "2024-04-15T16:00:00Z",
    "schedule": "Tuesdays & Thursdays 6-8 PM",
    "materials": "Mushaf, notebook, recording app"
}' "Creating Quran Memorization Course"

make_post_request "/courses" '{
    "title": "Islamic History & Civilization",
    "description": "Explore the golden age of Islamic civilization, from the Prophet Muhammad (PBUH) to the Ottoman Empire. Learn about contributions to science, art, and culture.",
    "instructor": "Dr. Fatima Rahman",
    "duration": "12 weeks",
    "category": "religious-studies",
    "level": "intermediate",
    "maxParticipants": 25,
    "startDate": "2024-03-01T10:00:00Z",
    "endDate": "2024-05-24T12:00:00Z",
    "schedule": "Mondays & Wednesdays 4-6 PM",
    "materials": "Course materials provided, recommended readings"
}' "Creating Islamic History Course"

make_post_request "/courses" '{
    "title": "Arabic Language for Beginners",
    "description": "Learn Modern Standard Arabic with focus on reading, writing, and basic conversation. Perfect for those interested in understanding Islamic texts.",
    "instructor": "Ustadha Aisha Hassan",
    "duration": "16 weeks",
    "category": "language",
    "level": "beginner",
    "maxParticipants": 20,
    "startDate": "2024-02-20T15:00:00Z",
    "endDate": "2024-06-10T17:00:00Z",
    "schedule": "Saturdays 10 AM - 12 PM",
    "materials": "Textbook, workbook, online resources"
}' "Creating Arabic Language Course"

make_post_request "/courses" '{
    "title": "Islamic Ethics & Character Building",
    "description": "Study Islamic ethics and character development based on Quran and Hadith. Learn practical applications for daily life.",
    "instructor": "Imam Omar Hassan",
    "duration": "6 weeks",
    "category": "religious-studies",
    "level": "beginner",
    "maxParticipants": 35,
    "startDate": "2024-04-01T18:00:00Z",
    "endDate": "2024-05-13T20:00:00Z",
    "schedule": "Fridays 6-8 PM",
    "materials": "Course handbook, reflection journal"
}' "Creating Islamic Ethics Course"

make_post_request "/courses" '{
    "title": "Advanced Tajweed & Qiraat",
    "description": "Master advanced tajweed rules and different qiraat styles. For students who have completed basic Quran memorization.",
    "instructor": "Qari Muhammad Ali",
    "duration": "10 weeks",
    "category": "religious-studies",
    "level": "advanced",
    "maxParticipants": 15,
    "startDate": "2024-03-15T19:00:00Z",
    "endDate": "2024-05-24T21:00:00Z",
    "schedule": "Sundays 4-6 PM",
    "materials": "Advanced tajweed manual, audio recordings"
}' "Creating Advanced Tajweed Course"

# 4. Submit Volunteer Applications
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

# 5. Submit Suggestions
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

# 6. Submit Messages
echo "💬 Creating Community Messages..."

make_post_request "/messages" '{
    "senderName": "Ahmed Abdullah",
    "senderEmail": "ahmed.abdullah@example.com",
    "senderPhone": "+91-9876543215",
    "messageType": "thank-you",
    "subject": "Excellent Islamic History Workshop",
    "content": "JazakAllahu khairan for organizing such an enlightening workshop. I learned so much about our Islamic heritage and the contributions of Muslim scholars to science and culture. The instructor was very knowledgeable and engaging.",
    "isPublic": true,
    "priority": "normal",
    "tags": ["workshop", "history", "positive-feedback", "education"]
}' "Creating thank you message from Ahmed"

make_post_request "/messages" '{
    "senderName": "Fatima Al-Zahra",
    "senderEmail": "fatima.alzahra@example.com",
    "senderPhone": "+91-9876543216",
    "messageType": "feedback",
    "subject": "Quran Memorization Course Feedback",
    "content": "The Quran memorization course was excellent! The instructor was very patient and the teaching methods were effective. I would suggest adding more audio resources for practice at home.",
    "isPublic": true,
    "priority": "normal",
    "tags": ["course", "quran", "memorization", "feedback"]
}' "Creating feedback message from Fatima"

make_post_request "/messages" '{
    "senderName": "Omar Hassan",
    "senderEmail": "omar.hassan@example.com",
    "senderPhone": "+91-9876543217",
    "messageType": "suggestion",
    "subject": "Arabic Language Course Suggestion",
    "content": "I would love to see an advanced Arabic course that focuses on classical texts and Islamic literature. This would help students better understand traditional Islamic sources.",
    "isPublic": true,
    "priority": "medium",
    "tags": ["course", "arabic", "advanced", "suggestion"]
}' "Creating suggestion message from Omar"

make_post_request "/messages" '{
    "senderName": "Aisha Rahman",
    "senderEmail": "aisha.rahman@example.com",
    "senderPhone": "+91-9876543218",
    "messageType": "general",
    "subject": "Volunteer Experience",
    "content": "I have been volunteering with EFY for the past year and it has been an amazing experience. The community is supportive and the work is meaningful. Thank you for this opportunity!",
    "isPublic": true,
    "priority": "normal",
    "tags": ["volunteer", "experience", "community", "positive"]
}' "Creating general message from Aisha"

make_post_request "/messages" '{
    "senderName": "Yusuf Khan",
    "senderEmail": "yusuf.khan@example.com",
    "senderPhone": "+91-9876543219",
    "messageType": "complaint",
    "subject": "Event Registration Issue",
    "content": "I tried to register for the Tech Conference but the registration form was not working properly. I hope this can be fixed for future events.",
    "isPublic": false,
    "priority": "high",
    "tags": ["registration", "technical-issue", "complaint"]
}' "Creating complaint message from Yusuf"

make_post_request "/messages" '{
    "senderName": "Zara Ahmed",
    "senderEmail": "zara.ahmed@example.com",
    "senderPhone": "+91-9876543220",
    "messageType": "thank-you",
    "subject": "Youth Leadership Program",
    "content": "The youth leadership program helped me develop confidence and public speaking skills. I am now more active in my community and feel empowered to make a difference.",
    "isPublic": true,
    "priority": "normal",
    "tags": ["leadership", "youth", "empowerment", "positive"]
}' "Creating thank you message from Zara"

# 7. Create Registrations
echo "📝 Creating Registrations..."

make_post_request "/registrations" '{
    "userId": "user_1706123456_def456",
    "itemId": "event_1706123456_abc123",
    "itemType": "event",
    "userEmail": "participant1@example.com",
    "userName": "Ahmed Abdullah",
    "userPhone": "+91-9876543221",
    "notes": "First time participant, excited to join the tech conference!"
}' "Creating registration for Ahmed to Tech Conference"

make_post_request "/registrations" '{
    "userId": "user_1706123457_def457",
    "itemId": "comp_1706123456_xyz789",
    "itemType": "competition",
    "userEmail": "participant2@example.com",
    "userName": "Fatima Al-Zahra",
    "userPhone": "+91-9876543222",
    "notes": "Looking forward to the hackathon challenge!"
}' "Creating registration for Fatima to Hackathon"

make_post_request "/registrations" '{
    "userId": "user_1706123458_def458",
    "itemId": "event_1706123457_abc124",
    "itemType": "event",
    "userEmail": "participant3@example.com",
    "userName": "Omar Hassan",
    "userPhone": "+91-9876543223",
    "notes": "Interested in sustainable energy solutions"
}' "Creating registration for Omar to Green Energy Workshop"

make_post_request "/registrations" '{
    "userId": "user_1706123459_def459",
    "itemId": "comp_1706123457_xyz790",
    "itemType": "competition",
    "userEmail": "participant4@example.com",
    "userName": "Aisha Rahman",
    "userPhone": "+91-9876543224",
    "notes": "Passionate about environmental innovation"
}' "Creating registration for Aisha to Innovation Challenge"

make_post_request "/registrations" '{
    "userId": "user_1706123460_def460",
    "itemId": "event_1706123458_abc125",
    "itemType": "event",
    "userEmail": "participant5@example.com",
    "userName": "Yusuf Khan",
    "userPhone": "+91-9876543225",
    "notes": "Healthcare professional interested in community service"
}' "Creating registration for Yusuf to Health Fair"

make_post_request "/registrations" '{
    "userId": "user_1706123461_def461",
    "itemId": "comp_1706123458_xyz791",
    "itemType": "competition",
    "userEmail": "participant6@example.com",
    "userName": "Zara Ahmed",
    "userPhone": "+91-9876543226",
    "notes": "Young writer excited about the essay contest"
}' "Creating registration for Zara to Essay Contest"

echo ""
echo "🎯 Database population completed!"
echo ""
echo "📊 Summary of created records:"
echo "• Events: 4 records"
echo "• Competitions: 3 records"
echo "• Courses: 5 records"
echo "• Volunteer Applications: 5 records"
echo "• Suggestions: 6 records"
echo "• Messages: 6 records"
echo "• Registrations: 6 records"
echo ""
echo "🔗 You can now test the GET endpoints to verify the data:"
echo "• GET $API_BASE_URL/events"
echo "• GET $API_BASE_URL/competitions"
echo "• GET $API_BASE_URL/courses"
echo "• GET $API_BASE_URL/volunteers"
echo "• GET $API_BASE_URL/suggestions"
echo "• GET $API_BASE_URL/messages"
echo "• GET $API_BASE_URL/registrations"
echo ""
echo "✨ All done! Your EFY API database is now populated with comprehensive dummy data."
