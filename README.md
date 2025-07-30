# Ethics For Youth (EFY) Backend API

A youth-driven platform for organizing Islamic educational events, competitions, and volunteer activities. Built with AWS Lambda (serverless architecture) and managed with Terraform.

## 🏗️ Architecture Overview

- **Serverless**: AWS Lambda functions for all API endpoints
- **Database**: DynamoDB for data persistence
- **API Gateway**: REST API with public endpoints
- **Infrastructure**: Terraform for infrastructure as code
- **CI/CD**: GitHub Actions for automated deployment

## 📋 API Endpoints

### 📅 Events

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/events` | List all events |
| `GET` | `/events/{id}` | Get specific event details |
| `POST` | `/events` | Create a new event |
| `PUT` | `/events/{id}` | Update an existing event |
| `DELETE` | `/events/{id}` | Delete an event |

### 🏆 Competitions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/competitions` | List all competitions |
| `GET` | `/competitions/{id}` | Get competition details |
| `POST` | `/competitions` | Create a new competition |
| `POST` | `/competitions/{id}/register` | Register for a competition |
| `GET` | `/competitions/{id}/results` | View competition results |

### 👥 Volunteers

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/volunteers/join` | Submit volunteer application |
| `GET` | `/volunteers` | List volunteers (basic info) |
| `PUT` | `/volunteers/{id}` | Update volunteer status |

### 💡 Suggestions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/suggestions` | Submit idea or feedback |
| `GET` | `/suggestions` | View all suggestions |

### 📚 Courses

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/courses` | List all courses |
| `GET` | `/courses/{id}` | Get specific course details |
| `POST` | `/courses` | Create a new course |
| `PUT` | `/courses/{id}` | Update an existing course |
| `DELETE` | `/courses/{id}` | Delete a course |

### 📝 Registrations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/registrations` | Register for an event or competition |
| `GET` | `/registrations` | List all registrations |
| `PUT` | `/registrations/{id}` | Update registration status |

### 💬 Messages

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/messages` | Submit community message (feedback, thank-you, etc.) |
| `GET` | `/messages` | View all messages (public or admin view) |

### 🔧 Admin

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/admin/stats` | Get dashboard metrics and statistics |

## 🚀 Deployment

### Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Terraform** >= 1.0 ([Install Terraform](https://learn.hashicorp.com/terraform/getting-started/install))
- **Node.js** 18.x - 20.x ([Install Node.js](https://nodejs.org/))
- **npm** >= 8.0 (comes with Node.js)

> 💡 **Tip**: Use [nvm](https://github.com/nvm-sh/nvm) to manage Node.js versions:
> ```bash
> nvm use  # Uses the version specified in .nvmrc
> ```

### Environment Setup

```bash
# Using the build script (recommended)
./scripts/build.sh plan dev     # Plan for dev environment
./scripts/build.sh apply dev    # Deploy to dev environment

# Or manually with proper S3 backend configuration
cd terraform
terraform init -backend-config="backend-dev.tfbackend"  # Use appropriate backend config
terraform workspace new dev  # or select existing: terraform workspace select dev
terraform plan -out=terraform-plan-dev.tfplan
terraform apply terraform-plan-dev.tfplan
```

> 🔧 **Backend Configuration**: The project uses S3 backend for state management. Backend configurations are stored in `terraform/backend-*.tfbackend` files for each environment.

### Supported Environments

- `dev` - Development environment
- `qa` - Quality assurance environment  
- `prod` - Production environment

## 📁 Project Structure

```
.
├── lambda_functions/           # Lambda function source code
│   ├── events_get/            # GET /events
│   ├── events_get_by_id/      # GET /events/{id}
│   ├── events_post/           # POST /events
│   ├── events_put/            # PUT /events/{id}
│   ├── events_delete/         # DELETE /events/{id}
│   ├── competitions_get/      # GET /competitions
│   ├── competitions_get_by_id/ # GET /competitions/{id}
│   ├── competitions_post/     # POST /competitions
│   ├── competitions_register/ # POST /competitions/{id}/register
│   ├── competitions_results/  # GET /competitions/{id}/results
│   ├── volunteers_join/       # POST /volunteers/join
│   ├── volunteers_get/        # GET /volunteers
│   ├── volunteers_put/        # PUT /volunteers/{id}
│   ├── suggestions_post/      # POST /suggestions
│   ├── suggestions_get/       # GET /suggestions
│   ├── courses_get/           # GET /courses
│   ├── courses_get_by_id/     # GET /courses/{id}
│   ├── courses_post/          # POST /courses
│   ├── courses_put/           # PUT /courses/{id}
│   ├── courses_delete/        # DELETE /courses/{id}
│   ├── registrations_post/    # POST /registrations
│   ├── registrations_get/     # GET /registrations
│   ├── registrations_put/     # PUT /registrations/{id}
│   ├── messages_post/         # POST /messages
│   ├── messages_get/          # GET /messages
│   └── admin_stats_get/       # GET /admin/stats
├── terraform/                 # Infrastructure as code
│   ├── modules/              # Reusable Terraform modules
│   │   ├── lambda/           # Lambda function module
│   │   ├── lambda_layer/     # Lambda layer module
│   │   ├── dynamodb/         # DynamoDB tables module
│   │   └── efy_api_gateway/  # API Gateway module
│   ├── backend-dev.tfbackend  # Dev environment S3 backend config
│   ├── backend-qa.tfbackend   # QA environment S3 backend config
│   ├── backend-prod.tfbackend # Prod environment S3 backend config
│   ├── backend.tf            # Terraform backend configuration
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions (includes backend config)
│   └── outputs.tf           # Output definitions
├── layers/                   # Lambda layers
│   ├── dependencies/        # Shared dependencies
│   └── utility/            # Utility functions
├── docs/                    # Documentation
│   └── api_spec.yaml       # OpenAPI specification
└── .github/workflows/      # CI/CD pipelines
```

## 🎯 Data Models

### Event
```json
{
  "id": "event_1706123456_abc123",
  "title": "Islamic History Workshop",
  "description": "Learn about the golden age of Islamic civilization",
  "date": "2024-02-15T14:00:00Z",
  "location": "Community Center, Room 101",
  "category": "educational",
  "maxParticipants": 50,
  "registrationDeadline": "2024-02-10T23:59:59Z",
  "status": "active",
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

### Competition
```json
{
  "id": "comp_1706123456_xyz789",
  "title": "Quran Recitation Competition",
  "description": "Annual Quran recitation competition for youth",
  "category": "religious",
  "startDate": "2024-03-01T09:00:00Z",
  "endDate": "2024-03-01T17:00:00Z",
  "registrationDeadline": "2024-02-25T23:59:59Z",
  "rules": ["Participants must be between 13-25 years old", "Maximum 5 minutes recitation"],
  "prizes": ["First Place: $500", "Second Place: $300", "Third Place: $200"],
  "maxParticipants": 50,
  "status": "open",
  "participants": [],
  "createdAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

### Volunteer
```json
{
  "id": "volunteer_1706123456_vol123",
  "name": "Fatima Rahman",
  "email": "fatima.rahman@example.com",
  "phone": "+1234567890",
  "skills": ["Event Management", "Social Media", "Teaching"],
  "availability": "Weekends and evenings",
  "status": "pending",
  "appliedAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

### Suggestion
```json
{
  "id": "suggestion_1706123456_sug456",
  "title": "Mobile App Development",
  "description": "Develop a mobile app to better engage youth with Islamic content",
  "category": "technology",
  "submitterName": "Omar Hassan",
  "submitterEmail": "omar.hassan@example.com",
  "priority": "medium",
  "tags": ["mobile", "technology", "youth-engagement"],
  "status": "submitted",
  "votes": 0,
  "submittedAt": "2024-01-25T10:00:00Z",
  "updatedAt": "2024-01-25T10:00:00Z"
}
```

### Course
```json
{
  "id": "course_1706123456_abc123",
  "title": "Quran Memorization Fundamentals",
  "description": "Learn effective techniques for memorizing the Holy Quran",
  "instructor": "Sheikh Ahmed Al-Hafiz",
  "duration": "8 weeks",
  "category": "religious-studies",
  "level": "beginner",
  "maxParticipants": 30,
  "startDate": "2024-02-15T14:00:00Z",
  "endDate": "2024-04-15T16:00:00Z",
  "schedule": "Tuesdays & Thursdays 6-8 PM",
  "materials": "Mushaf, notebook, recording app",
  "status": "active",
  "createdAt": "2024-01-25T10:30:00Z",
  "updatedAt": "2024-01-25T10:30:00Z"
}
```

### Registration
```json
{
  "id": "reg_1706123456_ghi789",
  "userId": "user_1706123456_def456",
  "itemId": "event_1706123456_abc123",
  "itemType": "event",
  "userEmail": "participant@example.com",
  "userName": "Fatima Al-Zahra",
  "userPhone": "+1234567890",
  "status": "registered",
  "notes": "First time participant, excited to join!",
  "registeredAt": "2024-01-25T10:30:00Z",
  "updatedAt": "2024-01-25T10:30:00Z"
}
```

### Message
```json
{
  "id": "msg_1706123456_jkl012",
  "senderName": "Omar Hassan",
  "senderEmail": "omar.hassan@example.com",
  "senderPhone": "+1234567890",
  "messageType": "thank-you",
  "subject": "Excellent Islamic History Workshop",
  "content": "JazakAllahu khairan for organizing such an enlightening workshop. I learned so much about our Islamic heritage!",
  "isPublic": true,
  "status": "new",
  "priority": "normal",
  "tags": ["workshop", "history", "positive-feedback"],
  "createdAt": "2024-01-25T10:30:00Z",
  "updatedAt": "2024-01-25T10:30:00Z"
}
```

## 🔧 Configuration

### Environment Variables

Each Lambda function receives environment-specific variables:

- `EVENTS_TABLE_NAME` - DynamoDB table for events
- `COMPETITIONS_TABLE_NAME` - DynamoDB table for competitions  
- `VOLUNTEERS_TABLE_NAME` - DynamoDB table for volunteers
- `SUGGESTIONS_TABLE_NAME` - DynamoDB table for suggestions
- `COURSES_TABLE_NAME` - DynamoDB table for courses
- `REGISTRATIONS_TABLE_NAME` - DynamoDB table for registrations
- `MESSAGES_TABLE_NAME` - DynamoDB table for messages
- `AWS_REGION` - AWS region for deployment

### Terraform Variables

Key variables in `terraform/variables.tf`:

- `project_name` - Project identifier (default: "efy-web-backend")
- `aws_region` - AWS region (default: "ap-south-1")
- `environment_configs` - Environment-specific settings

## 📖 API Documentation

Full API documentation is available in the OpenAPI specification at `docs/api_spec.yaml`. You can view it using:

- [Swagger UI](https://editor.swagger.io/) - Paste the YAML content
- [Redoc](https://redocly.github.io/redoc/) - Online documentation viewer

## 🛡️ Security

- **Public API**: All endpoints are publicly accessible (no authentication required)
- **CORS Enabled**: Cross-origin requests are supported
- **Input Validation**: All requests are validated for required fields
- **Error Handling**: Consistent error responses across all endpoints

## 🔍 Monitoring

- **CloudWatch Logs**: All Lambda functions log to CloudWatch
- **Request Tracing**: Each request includes a unique `requestId`
- **Error Tracking**: Errors are logged with full context

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Update tests and documentation
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For questions or support, please contact:
- Email: tech@ethicsforyouth.org
- GitHub Issues: [Create an issue](https://github.com/your-org/efy-backend/issues) 
