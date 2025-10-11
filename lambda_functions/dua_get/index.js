// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);
const s3Client = new S3Client({ region: process.env.AWS_REGION });

const bucketName = process.env.S3_BUCKET_NAME;

const generatePresignedUrl = async (key) => {
    if (!key) return null;
    return await getSignedUrl(s3Client, new GetObjectCommand({
        Bucket: bucketName,
        Key: key
    }), { expiresIn: 3600 }); // URL valid for 1 hour
};

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        let filterExpression, expressionAttributeValues;
        const tableName = process.env.DUA_TABLE_NAME;

        if (event.queryStringParameters?.status) {
            filterExpression = '#st = :status';
            expressionAttributeValues = { ':status': event.queryStringParameters.status };
        }

        const command = new ScanCommand({
            TableName: tableName,
            FilterExpression: filterExpression,              // undefined if no status
            ExpressionAttributeNames: filterExpression ? { '#st': 'status' } : undefined,
            ExpressionAttributeValues: expressionAttributeValues
        });

        const response = await docClient.send(command);

        const duas = await Promise.all((response.Items || []).map(async item => {
            item.audioUrl = await generatePresignedUrl(item.audioKey);
            item.imageUrl = await generatePresignedUrl(item.imageKey);
            return item;
        }));

        return successResponse({
            duas,
            count: duas.length,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        }, 'Duas retrieved successfully');

    } catch (error) {
        console.error('Error in dua_get function:', error);
        return errorResponse(error, 500);
    }
};