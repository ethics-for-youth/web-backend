// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const crypto = require('crypto');

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Allowed extensions & limits
const ALLOWED_AUDIO_EXT = ['mp3'];
const ALLOWED_IMAGE_EXT = ['jpg', 'jpeg', 'png'];
const MAX_AUDIO_SIZE = 5 * 1024 * 1024; // 5MB

async function uploadToS3(base64Data, fileType, bucketName) {
    if (!base64Data) return null;

    // Decode Base64
    const buffer = Buffer.from(base64Data, 'base64');

    // File size check (audio only)
    if (fileType === 'audio' && buffer.length > MAX_AUDIO_SIZE) {
        throw new Error('Audio file size exceeds 5MB limit');
    }

    // Validate extension based on file type
    let extension;
    if (fileType === 'audio') {
        extension = 'mp3';
        if (!ALLOWED_AUDIO_EXT.includes(extension)) {
            throw new Error('Invalid audio format. Only MP3 is allowed');
        }
    } else if (fileType === 'image') {
        // Default to JPG if not specified; otherwise validate
        extension = 'jpg';
        if (!ALLOWED_IMAGE_EXT.includes(extension)) {
            throw new Error('Invalid image format. Only JPG, JPEG, or PNG allowed');
        }
    }

    const key = `${crypto.randomBytes(16).toString('hex')}.${extension}`;

    const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: key,
        Body: buffer,
        ContentType: fileType === 'audio' ? 'audio/mpeg' : `image/${extension}`,
    });

    await s3Client.send(command);

    return `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
}

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        // Parse request body
        const body = parseJSON(event.body || '{}');

        // Validate required fields
        validateRequired(body, ['title', 'arabicText', 'week']);

        const tableName = process.env.DUA_TABLE_NAME;
        const bucketName = process.env.MEDIA_BUCKET_NAME;
        const duaId = `dua_${Date.now()}_${Math.random().toString(36).substring(7)}`;

        // Upload audio and image if provided
        const audioUrl = await uploadToS3(body.audioBase64, 'audio', bucketName);
        const imageUrl = await uploadToS3(body.imageBase64, 'image', bucketName);

        const duaItem = {
            id: duaId,
            title: body.title,
            arabic: body.arabicText,
            transcription: body.transcription || {
                english: body.transcription?.english || '',
                hindi: body.transcription?.hindi || '',
                urdu: body.transcription?.urdu || ''
            },
            translation: body.translation || {
                english: body.translation?.english || '',
                hindi: body.translation?.hindi || '',
                urdu: body.translation?.urdu || '',
                romanUrdu: body.translation?.romanUrdu || ''
            },
            audioUrl: audioUrl || null,
            imageUrl: imageUrl || null,
            status: 'active',
            week: body.week,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        const command = new PutCommand({
            TableName: tableName,
            Item: duaItem
        });

        await docClient.send(command);

        const data = {
            dua: duaItem,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Dua created successfully');

    } catch (error) {
        console.error('Error in dua_post function:', error);
        return errorResponse(error, error.message.includes('Missing required') ? 400 : 500);
    }
};
