// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient, UpdateItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const competitionId = event.pathParameters?.id;
        if (!competitionId) {
            return errorResponse('Competition ID is required', 400);
        }
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        // Validate required fields
        validateRequired(body, ['participantName', 'email']);
        
        const tableName = process.env.COMPETITIONS_TABLE_NAME;
        
        // First check if competition exists and is open for registration
        const getCommand = new GetItemCommand({
            TableName: tableName,
            Key: {
                id: { S: competitionId }
            }
        });
        
        const competition = await docClient.send(getCommand);
        if (!competition.Item) {
            return errorResponse('Competition not found', 404);
        }
        
        if (competition.Item.status !== 'open') {
            return errorResponse('Competition is not open for registration', 400);
        }
        
        // Check registration deadline
        const registrationDeadline = new Date(competition.Item.registrationDeadline);
        if (registrationDeadline < new Date()) {
            return errorResponse('Registration deadline has passed', 400);
        }
        
        // Check max participants limit
        const currentParticipants = competition.Item.participants || [];
        const maxParticipants = competition.Item.maxParticipants;
        
        if (maxParticipants && currentParticipants.length >= maxParticipants) {
            return errorResponse('Competition has reached maximum participants', 400);
        }
        
        // Check if participant already registered
        const existingParticipant = currentParticipants.find(p => p.email === body.email);
        if (existingParticipant) {
            return errorResponse('Participant already registered for this competition', 400);
        }
        
        // Create participant object
        const participant = {
            id: `participant_${Date.now()}_${Math.random().toString(36).substring(7)}`,
            name: body.participantName,
            email: body.email,
            phone: body.phone || null,
            registeredAt: new Date().toISOString()
        };
        
        // Add participant to competition
        const command = new UpdateItemCommand({
            TableName: tableName,
            Key: {
                id: { S: competitionId }
            },
            UpdateExpression: 'SET participants = list_append(if_not_exists(participants, :empty_list), :participant), updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':participant': [participant],
                ':empty_list': [],
                ':updatedAt': new Date().toISOString()
            },
            ReturnValues: 'ALL_NEW'
        });
        
        const result = await docClient.send(command);
        
        const data = {
            participant: participant,
            competition: {
                id: competitionId,
                title: result.Attributes.title,
                totalParticipants: result.Attributes.participants.length
            },
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Successfully registered for competition');
        
    } catch (error) {
        console.error('Error in competitions_register function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};