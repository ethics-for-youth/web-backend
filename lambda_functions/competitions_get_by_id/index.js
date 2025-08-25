// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

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

        const command = new GetCommand({
            TableName: tableName,
            Key: { id: competitionId }
        });

        const result = await docClient.send(command);

        if (!result.Item) {
            return errorResponse('Competition not found', 404);
        }

        const data = {
            competition: result.Item,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Competition retrieved successfully');

    } catch (error) {
        console.error('Error in competitions_get_by_id function:', error);
        return errorResponse(error, 500);
    }
};
