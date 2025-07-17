const AWS = require("aws-sdk");
const db = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const event_id = event.pathParameters?.id;
    const updates = JSON.parse(event.body);

    if (!event_id || !updates || Object.keys(updates).length === 0) {
        return { statusCode: 400, body: JSON.stringify({ error: "Invalid request" }) };
    }

    let updateExp = "set ";
    const expAttrValues = {};
    const expAttrNames = {};
    let prefix = "";

    for (const key in updates) {
        updateExp += `${prefix}#${key} = :${key}`;
        expAttrValues[`:${key}`] = updates[key];
        expAttrNames[`#${key}`] = key;
        prefix = ", ";
    }

    await db.update({
        TableName: "Events",
        Key: { event_id },
        UpdateExpression: updateExp,
        ExpressionAttributeValues: expAttrValues,
        ExpressionAttributeNames: expAttrNames,
    }).promise();

    return { statusCode: 200, body: JSON.stringify({ message: "Event updated" }) };
};
