const AWS = require("aws-sdk");
const db = new AWS.DynamoDB.DocumentClient();

exports.handler = async () => {
    const result = await db.scan({ TableName: "Events" }).promise();
    return { statusCode: 200, body: JSON.stringify(result.Items) };
};
