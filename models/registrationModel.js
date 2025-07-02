const dynamoDB = require('../config/dynamoClient.js');
const { v4: uuidv4 } = require('uuid');

const TABLE_NAME =  process.env.REGISTRATION_TABLE;

const registerUser = async (data) => {
  const Item = {
    id: uuidv4(),
    fullName: data.fullName,
    age: data.age,
    email: data.email,
    phone: data.phone,
    gender: data.gender,
    communication: data.communication || [],
    additionalInfo: data.additionalInfo || '',
    createdAt: new Date().toISOString(),
  };

  const params = {
    TableName: TABLE_NAME,
    Item,
  };

  await dynamoDB.put(params).promise();
  return Item;
};

module.exports = { registerUser };
