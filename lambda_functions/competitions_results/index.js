// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient, GetItemCommand } = require('@aws-sdk/client-dynamodb');
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
        
        const tableName = process.env.COMPETITIONS_TABLE_NAME;
        
        // First check if competition exists
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
        
        // Generate mock results data
        const mockResults = {
            competitionId: competitionId,
            competitionTitle: competition.Item.title || 'Sample Competition',
            status: 'completed',
            totalParticipants: 15,
            results: [
                {
                    position: 1,
                    participant: {
                        name: 'Ahmed Ali',
                        email: 'ahmed.ali@example.com',
                        score: 95
                    },
                    prize: 'First Place - $500'
                },
                {
                    position: 2,
                    participant: {
                        name: 'Fatima Khan',
                        email: 'fatima.khan@example.com',
                        score: 92
                    },
                    prize: 'Second Place - $300'
                },
                {
                    position: 3,
                    participant: {
                        name: 'Omar Hassan',
                        email: 'omar.hassan@example.com',
                        score: 88
                    },
                    prize: 'Third Place - $200'
                },
                {
                    position: 4,
                    participant: {
                        name: 'Aisha Rahman',
                        email: 'aisha.rahman@example.com',
                        score: 85
                    },
                    prize: 'Participation Certificate'
                },
                {
                    position: 5,
                    participant: {
                        name: 'Yusuf Ahmed',
                        email: 'yusuf.ahmed@example.com',
                        score: 82
                    },
                    prize: 'Participation Certificate'
                }
            ],
            announcedAt: '2024-01-15T10:00:00.000Z',
            note: 'These are sample results for demonstration purposes'
        };
        
        const data = {
            results: mockResults,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Competition results retrieved successfully');
        
    } catch (error) {
        console.error('Error in competitions_results function:', error);
        return errorResponse(error, 500);
    }
};