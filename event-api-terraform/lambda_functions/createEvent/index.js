const AWS = require("aws-sdk");
const { v4: uuidv4 } = require("uuid");
const db = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    try {
        const body = JSON.parse(event.body);
        const requiredFields = ["venue", "timestamp", "speaker", "topic"];
        for (const field of requiredFields) {
            if (!body[field]) {
                return { statusCode: 400, body: JSON.stringify({ error: `${field} is required` }) };
            }
        }

        const event_id = uuidv4();
        const item = {
            event_id,
            venue: body.venue,
            timestamp: body.timestamp,
            speaker: body.speaker,
            topic: body.topic,
            poster: body.poster || null,
            description: body.description || null,
        };

        await db.put({ TableName: "Events", Item: item }).promise();

        return { statusCode: 201, body: JSON.stringify({ message: "Event created", event_id }) };
    } catch (err) {
        return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
    }
};
