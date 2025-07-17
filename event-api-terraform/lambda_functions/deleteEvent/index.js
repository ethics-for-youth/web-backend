const AWS = require("aws-sdk");
const db = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const event_id = event.pathParameters?.id;
    if (!event_id) {
        return { statusCode: 400, body: JSON.stringify({ error: "Missing ID" }) };
    }

    await db.delete({ TableName: "Events", Key: { event_id } }).promise();

    return { statusCode: 200, body: JSON.stringify({ message: "Event deleted" }) };
};
