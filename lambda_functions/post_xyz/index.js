// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Parse request body
        const body = parseJSON(event.body || '{}');
        
        // Validate required fields (example)
        validateRequired(body, ['name']);
        
        // Sample business logic
        const data = {
            message: 'POST XYZ function executed successfully!',
            receivedData: body,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data, 'Data created successfully');
        
    } catch (error) {
        console.error('Error in post_xyz function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};
