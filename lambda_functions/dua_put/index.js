const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
    try {
        const body = JSON.parse(event.body);
        const { id, ...updates } = body;
        if (!id) throw new Error("id is required");
        if (Object.keys(updates).length === 0) throw new Error("No fields to update");

        const tableName = process.env.DUA_TABLE_NAME;

        // Build UpdateExpression dynamically
        let updateExp = "SET ";
        const exprAttrNames = {};
        const exprAttrValues = {};

        Object.entries(updates).forEach(([key, value], idx) => {
            const attrName = `#field${idx}`;
            const attrValue = `:val${idx}`;
            updateExp += `${attrName} = ${attrValue}, `;
            exprAttrNames[attrName] = key;
            exprAttrValues[attrValue] = value;
        });

        // Always update updatedAt
        updateExp += "#updatedAt = :updatedAt";
        exprAttrNames["#updatedAt"] = "updatedAt";
        exprAttrValues[":updatedAt"] = new Date().toISOString();

        const command = new UpdateCommand({
            TableName: tableName,
            Key: { id },
            UpdateExpression: updateExp,
            ExpressionAttributeNames: exprAttrNames,
            ExpressionAttributeValues: exprAttrValues,
            ReturnValues: "ALL_NEW"
        });

        const result = await docClient.send(command);

        return successResponse(result.Attributes, "Dua updated successfully");
    } catch (err) {
        console.error("Error:", err);
        return errorResponse(err, 400);
    }
};
