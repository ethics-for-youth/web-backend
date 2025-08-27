// Shared utility functions across Lambda functions

const response = (statusCode, body, headers = {}) => {
    return {
        statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
            'Access-Control-Allow-Methods': 'OPTIONS,GET,POST,PUT,DELETE',
            'Access-Control-Max-Age': '86400',
            ...headers
        },
        body: JSON.stringify(body)
    };
};

const successResponse = (data, message = 'Success', statusCode = 200) => {
    return response(statusCode, { success: true, message, data });
};

const errorResponse = (error, statusCode = 400) => {
    return response(statusCode, {
        success: false,
        error: error.message || error
    });
};

const validateRequired = (obj, fields) => {
    if (!obj || typeof obj !== 'object') {
        throw new Error('Invalid object provided for validation');
    }
    if (!fields || !Array.isArray(fields)) {
        throw new Error('Invalid fields array provided for validation');
    }
    const missing = fields.filter(field => !obj[field]);
    if (missing.length > 0) {
        throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }
};

const parseJSON = (str) => {
    try {
        if (!str || str.trim() === '') {
            return {};
        }
        return JSON.parse(str);
    } catch (e) {
        throw new Error('Invalid JSON format');
    }
};

// Utility to check empty/whitespace string
const isEmptyString = (value) => typeof value === 'string' && value.trim() === '';


const { AuthMiddleware, createAuthMiddleware, extractUserIdFromPath, extractResourceId } = require('./auth');
const { PermissionsManager } = require('./permissions');

module.exports = {
    response,
    successResponse,
    errorResponse,
    validateRequired,
    parseJSON,
    isEmptyString,
    AuthMiddleware,
    createAuthMiddleware,
    extractUserIdFromPath,
    extractResourceId,
    PermissionsManager
};
