const { v4: uuidv4 } = require('uuid');
const db = require('../config/dynamoClient');
const tableName = process.env.REGISTRATION_TABLE;

const createRegistration = async (data) => {
  const item = {
    id: uuidv4(),
    name: data.name,
    email: data.email,
    gender: data.gender,
    registeredAt: new Date().toISOString(),
  };

  const params = {
    TableName: tableName,
    Item: item,
  };

  await db.put(params).promise();
  return item;
};

const getGenderCount = async (gender) => {
  const params = {
    TableName: tableName,
    FilterExpression: 'gender = :g',
    ExpressionAttributeValues: { ':g': gender },
  };

  const result = await db.scan(params).promise();
  return result.Items.length;
};

module.exports = { createRegistration, getGenderCount };
