// Shared utility functions across Lambda functions

const response = (statusCode, body, headers = {}) => {
    return {
        statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
            ...headers
        },
        body: JSON.stringify(body)
    };
};

const successResponse = (data, message = 'Success') => {
    return response(200, { success: true, message, data });
};

const errorResponse = (error, statusCode = 400) => {
    return response(statusCode, { 
        success: false, 
        error: error.message || error 
    });
};

const validateRequired = (obj, fields) => {
    const missing = fields.filter(field => !obj[field]);
    if (missing.length > 0) {
        throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }
};

const parseJSON = (str) => {
    try {
        return JSON.parse(str);
    } catch (e) {
        throw new Error('Invalid JSON format');
    }
};

module.exports = {
    response,
    successResponse,
    errorResponse,
    validateRequired,
    parseJSON
};
