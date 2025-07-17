const AWS = require("aws-sdk");
const db = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const event_id = event.pathParameters?.id;
    if (!event_id) {
        return { statusCode: 400, body: JSON.stringify({ error: "Missing ID" }) };
    }

    const result = await db.get({ TableName: "Events", Key: { event_id } }).promise();
    if (!result.Item) {
        return { statusCode: 404, body: JSON.stringify({ error: "Event not found" }) };
    }

    return { statusCode: 200, body: JSON.stringify(result.Item) };
};
