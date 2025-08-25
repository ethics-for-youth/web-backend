#!/bin/bash

# EFY Registration Table Population Script
# This script fetches real IDs from events, courses, and competitions tables
# then creates realistic mock registrations using those IDs

API_BASE_URL="https://qa.efy.org.in/api"

echo "🚀 Starting EFY Registration Table Population..."
echo "API Base URL: $API_BASE_URL"
echo ""

# Arrays to store fetched IDs
declare -a EVENT_IDS
declare -a COURSE_IDS  
declare -a COMPETITION_IDS

# Function to extract IDs from API response
extract_ids() {
    local response="$1"
    local item_type="$2"
    
    # Use jq to extract IDs from the response
    if command -v jq >/dev/null 2>&1; then
        echo "$response" | jq -r ".data.${item_type}[]?.id" 2>/dev/null | grep -v "null"
    else
        # Fallback: basic grep extraction if jq is not available
        echo "$response" | grep -o '"id":"[^"]*"' | sed 's/"id":"//g' | sed 's/"//g'
    fi
}

# Function to make registration request
create_registration() {
    local user_id="$1"
    local item_id="$2"
    local item_type="$3"
    local user_email="$4"
    local user_name="$5"
    local user_phone="$6"
    local notes="$7"
    local registration_fee="$8"
    local payment_status="$9"
    local payment_id="${10}"
    
    local data="{
        \"userId\": \"$user_id\",
        \"itemId\": \"$item_id\",
        \"itemType\": \"$item_type\",
        \"userEmail\": \"$user_email\",
        \"userName\": \"$user_name\",
        \"userPhone\": \"$user_phone\",
        \"notes\": \"$notes\""
    
    if [ ! -z "$registration_fee" ] && [ "$registration_fee" != "0" ]; then
        data="$data, \"registrationFee\": $registration_fee"
    fi
    
    if [ ! -z "$payment_status" ]; then
        data="$data, \"paymentStatus\": \"$payment_status\""
    fi
    
    if [ ! -z "$payment_id" ]; then
        data="$data, \"paymentId\": \"$payment_id\""
    fi
    
    data="$data}"
    
    echo "📝 Creating registration for $user_name"
    echo "   Item: $item_type ($item_id)"
    
    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$data" \
        "$API_BASE_URL/registrations")
    
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    if [ "$http_status" -eq 200 ]; then
        echo "   ✅ Success (HTTP $http_status)"
    else
        echo "   ❌ Failed (HTTP $http_status)"
        echo "   Response: $response_body"
    fi
    echo ""
}

# Step 1: Fetch Event IDs
echo "📅 Fetching Event IDs..."
events_response=$(curl -s "$API_BASE_URL/events")
if [ $? -eq 0 ]; then
    event_ids=$(extract_ids "$events_response" "events")
    if [ ! -z "$event_ids" ]; then
        while IFS= read -r id; do
            [ ! -z "$id" ] && EVENT_IDS+=("$id")
        done <<< "$event_ids"
        echo "   Found ${#EVENT_IDS[@]} events"
        for id in "${EVENT_IDS[@]}"; do
            echo "   - $id"
        done
    else
        echo "   ⚠️  No events found"
    fi
else
    echo "   ❌ Failed to fetch events"
fi
echo ""

# Step 2: Fetch Course IDs
echo "📚 Fetching Course IDs..."
courses_response=$(curl -s "$API_BASE_URL/courses")
if [ $? -eq 0 ]; then
    course_ids=$(extract_ids "$courses_response" "courses")
    if [ ! -z "$course_ids" ]; then
        while IFS= read -r id; do
            [ ! -z "$id" ] && COURSE_IDS+=("$id")
        done <<< "$course_ids"
        echo "   Found ${#COURSE_IDS[@]} courses"
        for id in "${COURSE_IDS[@]}"; do
            echo "   - $id"
        done
    else
        echo "   ⚠️  No courses found"
    fi
else
    echo "   ❌ Failed to fetch courses"
fi
echo ""

# Step 3: Fetch Competition IDs
echo "🏆 Fetching Competition IDs..."
competitions_response=$(curl -s "$API_BASE_URL/competitions")
if [ $? -eq 0 ]; then
    competition_ids=$(extract_ids "$competitions_response" "competitions")
    if [ ! -z "$competition_ids" ]; then
        while IFS= read -r id; do
            [ ! -z "$id" ] && COMPETITION_IDS+=("$id")
        done <<< "$competition_ids"
        echo "   Found ${#COMPETITION_IDS[@]} competitions"
        for id in "${COMPETITION_IDS[@]}"; do
            echo "   - $id"
        done
    else
        echo "   ⚠️  No competitions found"
    fi
else
    echo "   ❌ Failed to fetch competitions"
fi
echo ""

# Step 4: Create Mock Registrations
echo "📝 Creating Mock Registrations..."
echo "=========================================="

# Mock user data arrays - Expanded to 50 users
declare -a USERS=(
    "user_$(date +%s)_001:ahmed.abdullah@example.com:Ahmed Abdullah:+91-9876543001:First time participant, very excited to join!"
    "user_$(date +%s)_002:fatima.alzahra@example.com:Fatima Al-Zahra:+91-9876543002:Looking forward to learning new skills and meeting like-minded people."
    "user_$(date +%s)_003:omar.hassan@example.com:Omar Hassan:+91-9876543003:Passionate about technology and innovation. Can't wait to participate!"
    "user_$(date +%s)_004:aisha.rahman@example.com:Aisha Rahman:+91-9876543004:Healthcare professional interested in community development."
    "user_$(date +%s)_005:yusuf.khan@example.com:Yusuf Khan:+91-9876543005:Young entrepreneur eager to contribute to society."
    "user_$(date +%s)_006:zara.ahmed@example.com:Zara Ahmed:+91-9876543006:Student leader with passion for education and youth empowerment."
    "user_$(date +%s)_007:hassan.ali@example.com:Hassan Ali:+91-9876543007:Software developer interested in using tech for social good."
    "user_$(date +%s)_008:mariam.shah@example.com:Mariam Shah:+91-9876543008:Teacher passionate about Islamic education and character building."
    "user_$(date +%s)_009:ibrahim.malik@example.com:Ibrahim Malik:+91-9876543009:Business analyst with interest in sustainable development."
    "user_$(date +%s)_010:khadija.rose@example.com:Khadija Rose:+91-9876543010:Environmental activist and sustainability enthusiast."
    "user_$(date +%s)_011:muhammad.tariq@example.com:Muhammad Tariq:+91-9876543011:Islamic scholar interested in interfaith dialogue."
    "user_$(date +%s)_012:safiya.ahmed@example.com:Safiya Ahmed:+91-9876543012:Medical student with passion for community health."
    "user_$(date +%s)_013:ali.hassan@example.com:Ali Hassan:+91-9876543013:Engineer interested in renewable energy solutions."
    "user_$(date +%s)_014:noor.fatima@example.com:Noor Fatima:+91-9876543014:Social worker dedicated to youth development programs."
    "user_$(date +%s)_015:usman.ahmed@example.com:Usman Ahmed:+91-9876543015:Graphic designer with experience in nonprofit campaigns."
    "user_$(date +%s)_016:layla.khan@example.com:Layla Khan:+91-9876543016:Psychology student interested in mental health awareness."
    "user_$(date +%s)_017:bilal.shah@example.com:Bilal Shah:+91-9876543017:Marketing professional passionate about social causes."
    "user_$(date +%s)_018:amina.ali@example.com:Amina Ali:+91-9876543018:Nutritionist interested in community wellness programs."
    "user_$(date +%s)_019:tariq.rahman@example.com:Tariq Rahman:+91-9876543019:IT consultant with experience in educational technology."
    "user_$(date +%s)_020:sara.hassan@example.com:Sara Hassan:+91-9876543020:Journalist interested in highlighting social issues and solutions."
    "user_$(date +%s)_021:rashid.ahmed@example.com:Rashid Ahmed:+91-9876543021:University student studying computer science, eager to learn and contribute."
    "user_$(date +%s)_022:maryam.khan@example.com:Maryam Khan:+91-9876543022:High school teacher with 10 years experience, loves inspiring young minds."
    "user_$(date +%s)_023:khalid.malik@example.com:Khalid Malik:+91-9876543023:Small business owner committed to ethical practices and community service."
    "user_$(date +%s)_024:halima.sheikh@example.com:Halima Sheikh:+91-9876543024:Nurse practitioner focused on maternal and child health in underserved areas."
    "user_$(date +%s)_025:abdullah.shah@example.com:Abdullah Shah:+91-9876543025:Recent graduate in environmental science, passionate about climate action."
    "user_$(date +%s)_026:khadija.ali@example.com:Khadija Ali:+91-9876543026:Social media manager who uses platforms to spread positive messages."
    "user_$(date +%s)_027:hamza.rahman@example.com:Hamza Rahman:+91-9876543027:Civil engineer working on sustainable infrastructure projects."
    "user_$(date +%s)_028:zaynab.hassan@example.com:Zaynab Hassan:+91-9876543028:PhD student in Islamic studies researching modern applications of classical texts."
    "user_$(date +%s)_029:mustafa.ahmed@example.com:Mustafa Ahmed:+91-9876543029:Youth counselor helping teenagers navigate challenges and build confidence."
    "user_$(date +%s)_030:sumaya.khan@example.com:Sumaya Khan:+91-9876543030:Freelance graphic designer specializing in nonprofit and social cause branding."
    "user_$(date +%s)_031:idris.malik@example.com:Idris Malik:+91-9876543031:Data scientist working on AI solutions for social good and education."
    "user_$(date +%s)_032:ruqayya.shah@example.com:Ruqayya Shah:+91-9876543032:Pediatrician dedicated to improving child healthcare in rural communities."
    "user_$(date +%s)_033:sulaiman.ali@example.com:Sulaiman Ali:+91-9876543033:Financial advisor helping families achieve economic stability and halal investing."
    "user_$(date +%s)_034:hafsa.rahman@example.com:Hafsa Rahman:+91-9876543034:Architect designing eco-friendly mosques and community centers."
    "user_$(date +%s)_035:ismail.hassan@example.com:Ismail Hassan:+91-9876543035:Cybersecurity specialist protecting nonprofits and educational institutions."
    "user_$(date +%s)_036:naima.ahmed@example.com:Naima Ahmed:+91-9876543036:Community organizer mobilizing neighbors for local improvement projects."
    "user_$(date +%s)_037:dawud.khan@example.com:Dawud Khan:+91-9876543037:Emergency medical technician with 15 years of service helping save lives."
    "user_$(date +%s)_038:safiya.malik@example.com:Safiya Malik:+91-9876543038:Mental health counselor specializing in trauma recovery and family therapy."
    "user_$(date +%s)_039:ibrahim.shah@example.com:Ibrahim Shah:+91-9876543039:Agricultural scientist developing sustainable farming techniques for small farmers."
    "user_$(date +%s)_040:aminah.ali@example.com:Aminah Ali:+91-9876543040:Elementary school principal committed to inclusive education and character development."
    "user_$(date +%s)_041:yahya.rahman@example.com:Yahya Rahman:+91-9876543041:Renewable energy engineer installing solar systems for low-income households."
    "user_$(date +%s)_042:khadijah.hassan@example.com:Khadijah Hassan:+91-9876543042:Food security researcher working to end hunger in urban communities."
    "user_$(date +%s)_043:umar.ahmed@example.com:Umar Ahmed:+91-9876543043:Public health officer coordinating vaccination and disease prevention programs."
    "user_$(date +%s)_044:asma.khan@example.com:Asma Khan:+91-9876543044:Human rights lawyer advocating for refugee rights and social justice."
    "user_$(date +%s)_045:yaqub.malik@example.com:Yaqub Malik:+91-9876543045:Urban planner designing inclusive public spaces and affordable housing."
    "user_$(date +%s)_046:umm.shah@example.com:Umm Kulthum Shah:+91-9876543046:Community health worker educating families about preventive healthcare."
    "user_$(date +%s)_047:salman.ali@example.com:Salman Ali:+91-9876543047:Volunteer firefighter and EMT serving rural communities for over a decade."
    "user_$(date +%s)_048:rabia.rahman@example.com:Rabia Rahman:+91-9876543048:Special education teacher creating innovative learning methods for children with disabilities."
    "user_$(date +%s)_049:musa.hassan@example.com:Musa Hassan:+91-9876543049:Water engineer building wells and clean water systems in underserved villages."
    "user_$(date +%s)_050:hadijah.ahmed@example.com:Hadijah Ahmed:+91-9876543050:Senior care coordinator ensuring elderly community members receive proper support."
)

# Registration counter
registration_count=0

# Allow users to register for multiple items by cycling through users
get_user_data() {
    local index=$((registration_count % ${#USERS[@]}))
    echo "${USERS[$index]}"
}

# Create registrations for Events
if [ ${#EVENT_IDS[@]} -gt 0 ]; then
    echo "🎉 Creating Event Registrations..."
    
    for event_id in "${EVENT_IDS[@]}"; do
        # Create 5-10 registrations per event
        num_registrations=$((5 + RANDOM % 6))
        
        for i in $(seq 1 $num_registrations); do
            user_data=$(get_user_data)
            IFS=':' read -r user_id email name phone notes <<< "$user_data"
                
                # Random registration fee (0 for free events, or 50-500 for paid)
                if [ $((RANDOM % 3)) -eq 0 ]; then
                    reg_fee=$((50 + RANDOM % 451))  # 50-500 range
                    payment_status_options=("pending" "paid" "failed")
                    payment_status="${payment_status_options[$((RANDOM % 3))]}"
                    if [ "$payment_status" = "paid" ]; then
                        payment_id="pay_$(date +%s)_${RANDOM}"
                    else
                        payment_id=""
                    fi
                else
                    reg_fee="0"
                    payment_status="paid"
                    payment_id=""
                fi
                
                create_registration "$user_id" "$event_id" "event" "$email" "$name" "$phone" "$notes" "$reg_fee" "$payment_status" "$payment_id"
            registration_count=$((registration_count + 1))
        done
    done
fi

# Create registrations for Courses
if [ ${#COURSE_IDS[@]} -gt 0 ]; then
    echo "📚 Creating Course Registrations..."
    
    for course_id in "${COURSE_IDS[@]}"; do
        # Create 6-12 registrations per course
        num_registrations=$((6 + RANDOM % 7))
        
        for i in $(seq 1 $num_registrations); do
            user_data=$(get_user_data)
            IFS=':' read -r user_id email name phone notes <<< "$user_data"
                
                # Course-specific notes
                course_notes="Eager to deepen Islamic knowledge and understanding. $notes"
                
                # Random registration fee for courses (typically higher: 100-1000)
                if [ $((RANDOM % 2)) -eq 0 ]; then
                    reg_fee=$((100 + RANDOM % 901))  # 100-1000 range
                    payment_status_options=("pending" "paid")
                    payment_status="${payment_status_options[$((RANDOM % 2))]}"
                    if [ "$payment_status" = "paid" ]; then
                        payment_id="pay_$(date +%s)_${RANDOM}"
                    else
                        payment_id=""
                    fi
                else
                    reg_fee="0"
                    payment_status="paid"
                    payment_id=""
                fi
                
                create_registration "$user_id" "$course_id" "course" "$email" "$name" "$phone" "$course_notes" "$reg_fee" "$payment_status" "$payment_id"
            registration_count=$((registration_count + 1))
        done
    done
fi

# Create registrations for Competitions
if [ ${#COMPETITION_IDS[@]} -gt 0 ]; then
    echo "🏆 Creating Competition Registrations..."
    
    for competition_id in "${COMPETITION_IDS[@]}"; do
        # Create 8-15 registrations per competition
        num_registrations=$((8 + RANDOM % 8))
        
        for i in $(seq 1 $num_registrations); do
            user_data=$(get_user_data)
            IFS=':' read -r user_id email name phone notes <<< "$user_data"
                
                # Competition-specific notes
                comp_notes="Ready to compete and showcase skills! $notes"
                
                # Random registration fee for competitions (25-300)
                if [ $((RANDOM % 4)) -eq 0 ]; then
                    reg_fee=$((25 + RANDOM % 276))  # 25-300 range
                    payment_status_options=("pending" "paid" "failed")
                    payment_status="${payment_status_options[$((RANDOM % 3))]}"
                    if [ "$payment_status" = "paid" ]; then
                        payment_id="pay_$(date +%s)_${RANDOM}"
                    else
                        payment_id=""
                    fi
                else
                    reg_fee="0"
                    payment_status="paid"
                    payment_id=""
                fi
                
                create_registration "$user_id" "$competition_id" "competition" "$email" "$name" "$phone" "$comp_notes" "$reg_fee" "$payment_status" "$payment_id"
            registration_count=$((registration_count + 1))
        done
    done
fi

echo ""
echo "🎯 Registration population completed!"
echo ""
echo "📊 Summary:"
echo "• Total registrations created: $registration_count"
echo "• Events with registrations: ${#EVENT_IDS[@]}"
echo "• Courses with registrations: ${#COURSE_IDS[@]}"
echo "• Competitions with registrations: ${#COMPETITION_IDS[@]}"
echo ""
echo "🔗 Test the registration endpoints:"
echo "• GET $API_BASE_URL/registrations"
echo "• GET $API_BASE_URL/registrations?itemType=event"
echo "• GET $API_BASE_URL/registrations?itemType=course"
echo "• GET $API_BASE_URL/registrations?itemType=competition"
echo ""
echo "✨ Registration table is now populated with realistic mock data!"