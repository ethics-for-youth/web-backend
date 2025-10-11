const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async () => {
    try {
        const tableName = process.env.DUA_TABLE_NAME;

        const command = new ScanCommand({
            TableName: tableName,
            FilterExpression: "#s = :active",
            ExpressionAttributeNames: { "#s": "status" },
            ExpressionAttributeValues: { ":active": "active" }
        });

        const result = await docClient.send(command);

        return successResponse(result.Items, "Active duas fetched successfully");
    } catch (err) {
        console.error("Error:", err);
        return errorResponse(err, 400);
    }
};
