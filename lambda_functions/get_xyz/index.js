// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Sample business logic
        const data = {
            message: 'GET XYZ function executed successfully!',
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };
        
        return successResponse(data);
        
    } catch (error) {
        console.error('Error in get_xyz function:', error);
        return errorResponse(error, 500);
    }
};
