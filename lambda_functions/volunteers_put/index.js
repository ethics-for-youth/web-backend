// Import from utility layer
const { successResponse, errorResponse, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient, UpdateItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        const volunteerId = event.pathParameters?.id;
        if (!volunteerId) {
            return errorResponse('Volunteer ID is required', 400);
        }
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        const tableName = process.env.VOLUNTEERS_TABLE_NAME;
        
        // First check if volunteer exists
        const getCommand = new GetItemCommand({
            TableName: tableName,
            Key: {
                id: { S: volunteerId }
            }
        });
        
        const existingVolunteer = await docClient.send(getCommand);
        if (!existingVolunteer.Item) {
            return errorResponse('Volunteer not found', 404);
        }
        
        // Build update expression dynamically
        const updateExpression = [];
        const expressionAttributeValues = {};
        const expressionAttributeNames = {};
        
        const updatableFields = ['status', 'assignedRole', 'team', 'notes', 'approvedBy'];
        
        updatableFields.forEach(field => {
            if (body[field] !== undefined) {
                updateExpression.push(`#${field} = :${field}`);
                expressionAttributeNames[`#${field}`] = field;
                expressionAttributeValues[`:${field}`] = body[field];
            }
        });
        
        if (updateExpression.length === 0) {
            return errorResponse('No valid fields to update', 400);
        }
        
        // Always update the updatedAt field
        updateExpression.push('#updatedAt = :updatedAt');
        expressionAttributeNames['#updatedAt'] = 'updatedAt';
        expressionAttributeValues[':updatedAt'] = new Date().toISOString();
        
        // If status is being changed to approved, add approval timestamp
        if (body.status === 'approved') {
            updateExpression.push('#approvedAt = :approvedAt');
            expressionAttributeNames['#approvedAt'] = 'approvedAt';
            expressionAttributeValues[':approvedAt'] = new Date().toISOString();
        }
        
        const command = new UpdateItemCommand({
            TableName: tableName,
            Key: {
                id: { S: volunteerId }
            },
            UpdateExpression: `SET ${updateExpression.join(', ')}`,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        });
        
        const result = await docClient.send(command);
        
        // Filter out sensitive information
        const updatedVolunteer = {
            id: result.Attributes.id,
            name: result.Attributes.name,
            email: result.Attributes.email,
            status: result.Attributes.status,
            assignedRole: result.Attributes.assignedRole || null,
            team: result.Attributes.team || null,
            approvedAt: result.Attributes.approvedAt || null,
            updatedAt: result.Attributes.updatedAt
        };
        
        const data = {
            volunteer: updatedVolunteer,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Volunteer updated successfully');
        
    } catch (error) {
        console.error('Error in volunteers_put function:', error);
        return errorResponse(error, 500);
    }
};