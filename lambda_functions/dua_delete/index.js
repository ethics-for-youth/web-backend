const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
    try {
        const { id } = event.pathParameters;
        if (!id) throw new Error("id is required");

        const tableName = process.env.DUA_TABLE_NAME;

        await docClient.send(new DeleteCommand({
            TableName: tableName,
            Key: { id }
        }));

        return successResponse({ id }, "Dua deleted successfully");
    } catch (err) {
        console.error("Error:", err);
        return errorResponse(err, 400);
    }
};
