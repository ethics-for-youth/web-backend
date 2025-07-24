const AWS = require("aws-sdk");
const db = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    try {
        const event_id = event.pathParameters?.id;
        const updates = JSON.parse(event.body || "{}");

        if (!event_id || Object.keys(updates).length === 0) {
            return response(400, { error: "Invalid request" });
        }
        const updateExpr = "SET " + Object.keys(updates).map(k => `${k} = :${k}`).join(", ");
        const exprValues = {};
        for (const key of Object.keys(updates)) {
            exprValues[`:${key}`] = updates[key];
        }

        await db.update({
            TableName: "Events",
            Key: { event_id },
            UpdateExpression: updateExpr,
            ExpressionAttributeValues: exprValues
        }).promise();

        return response(200, { message: "Event updated successfully" });
    } catch (err) {
        console.error(err);
        return response(500, { error: "Internal Server Error" });
    }
};

const response = (statusCode, body) => ({
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
});
