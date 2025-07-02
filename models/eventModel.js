const { v4: uuidv4 } = require('uuid');
const db = require('../config/dynamoClient');
const tableName = process.env.EVENT_TABLE;

const createEvent = async (event) => {
  const item = {
    id: uuidv4(),
    title: event.title,
    description: event.description,
    date: event.date,
    type: event.type, // "today", "week", "month"
    createdAt: new Date().toISOString(),
  };

  await db.put({ TableName: tableName, Item: item }).promise();
  return item;
};

const getEvents = async (type = null) => {
  const params = {
    TableName: tableName,
  };

  if (type) {
    params.FilterExpression = 'type = :t';
    params.ExpressionAttributeValues = { ':t': type };
  }

  const result = await db.scan(params).promise();
  return result.Items;
};

module.exports = { createEvent, getEvents };
