// Lambda: dua_post.js text working
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const crypto = require('crypto');
const multipart = require('aws-lambda-multipart-parser');

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);
const s3Client = new S3Client({ region: process.env.AWS_REGION });

const ALLOWED_AUDIO_EXT = ['mp3'];
const ALLOWED_IMAGE_EXT = ['jpg', 'jpeg', 'png'];
const MAX_AUDIO_SIZE = 5 * 1024 * 1024; // 5MB

async function uploadToS3(file, type, bucketName) {
  if (!file || !file.content) return null;

  const ext = file.filename.split('.').pop().toLowerCase();
  if (type === 'audio' && !ALLOWED_AUDIO_EXT.includes(ext))
    throw new Error('Invalid audio format. Only MP3 allowed');
  if (type === 'image' && !ALLOWED_IMAGE_EXT.includes(ext))
    throw new Error('Invalid image format. Only JPG, JPEG, PNG allowed');

  if (type === 'audio' && file.content.length > MAX_AUDIO_SIZE)
    throw new Error('Audio file exceeds 5MB');

  const key = `${crypto.randomBytes(16).toString('hex')}.${ext}`;
  const command = new PutObjectCommand({
    Bucket: bucketName,
    Key: key,
    Body: file.content, // content is a Buffer
    ContentType: type === 'audio' ? 'audio/mpeg' : `image/${ext}`,
  });

  await s3Client.send(command);
  return `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
}

exports.handler = async (event) => {
  try {
    console.log('Event:', JSON.stringify(event));

    // Parse multipart/form-data
    let parsed;
if (event.isBase64Encoded) {
    // Convert base64 to buffer
    const buffer = Buffer.from(event.body, 'base64');

    // Convert buffer to UTF-8 string for parser (text fields)
    parsed = multipart.parse({ ...event, body: buffer.toString('utf8') }, true);
} else {
    parsed = multipart.parse(event, true);
}

    // Extract fields
    const body = {
      title: parsed.title,
      arabicText: parsed.arabicText,
      week: parsed.week,
      transcription: parsed.transcription ? parseJSON(parsed.transcription) : {},
      translation: parsed.translation ? parseJSON(parsed.translation) : {}
    };

    validateRequired(body, ['title', 'arabicText', 'week']);

    const tableName = process.env.DUA_TABLE_NAME;
    const bucketName = process.env.MEDIA_BUCKET_NAME;
    const duaId = crypto.randomUUID();

    // Upload files
    const audioUrl = parsed.audio ? await uploadToS3(parsed.audio, 'audio', bucketName) : null;
    const imageUrl = parsed.image ? await uploadToS3(parsed.image, 'image', bucketName) : null;

    const duaItem = {
      id: duaId,
      title: body.title,
      arabic: body.arabicText,
      transcription: {
        english: body.transcription.english || '',
        hindi: body.transcription.hindi || '',
        urdu: body.transcription.urdu || ''
      },
      translation: {
        english: body.translation.english || '',
        hindi: body.translation.hindi || '',
        urdu: body.translation.urdu || '',
        romanUrdu: body.translation.romanUrdu || ''
      },
      audioUrl,
      imageUrl,
      status: 'active',
      week: body.week,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await docClient.send(new PutCommand({ TableName: tableName, Item: duaItem }));

    return successResponse({
      dua: duaItem,
      requestId: event.requestContext?.requestId,
      timestamp: new Date().toISOString()
    }, 'Dua created successfully');

  } catch (err) {
    console.error('Error:', err);
    return errorResponse(err, 400);
  }
};
