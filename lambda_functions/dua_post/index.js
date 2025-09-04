// Import from utility layer
const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const crypto = require('crypto');
const multer = require('multer');
const parseMultipart = require('aws-lambda-multipart-parser');

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Allowed extensions & limits
const ALLOWED_AUDIO_EXT = ['mp3'];
const ALLOWED_IMAGE_EXT = ['jpg', 'jpeg', 'png'];
const MAX_AUDIO_SIZE = 5 * 1024 * 1024; // 5MB

// Configure multer for in-memory file storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_AUDIO_SIZE },
  fileFilter: (req, file, cb) => {
    const ext = file.originalname.split('.').pop().toLowerCase();
    if (file.fieldname === 'audio' && !ALLOWED_AUDIO_EXT.includes(ext)) {
      return cb(new Error('Invalid audio format. Only MP3 is allowed'));
    }
    if (file.fieldname === 'image' && !ALLOWED_IMAGE_EXT.includes(ext)) {
      return cb(new Error('Invalid image format. Only JPG, JPEG, or PNG allowed'));
    }
    cb(null, true);
  }
}).fields([
  { name: 'audio', maxCount: 1 },
  { name: 'image', maxCount: 1 }
]);

async function uploadToS3(file, fileType, bucketName) {
  if (!file || !file.buffer) return null;

  const buffer = file.buffer;
  const ext = file.originalname.split('.').pop().toLowerCase();
  const key = `${crypto.randomBytes(16).toString('hex')}.${ext}`;

  const command = new PutObjectCommand({
    Bucket: bucketName,
    Key: key,
    Body: buffer,
    ContentType: fileType === 'audio' ? 'audio/mpeg' : `image/${ext}`,
  });

  await s3Client.send(command);

  return `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
}

exports.handler = async (event, context, callback) => {
  try {
    console.log('Event: ', JSON.stringify(event, null, 2));

    // Parse multipart/form-data using aws-lambda-multipart-parser
    const parsed = await parseMultipart(event);

    // Extract form fields
    const body = {
      title: parsed.title,
      arabicText: parsed.arabicText,
      week: parsed.week,
      transcription: parsed.transcription ? parseJSON(parsed.transcription) : {},
      translation: parsed.translation ? parseJSON(parsed.translation) : {}
    };

    // Validate required fields
    validateRequired(body, ['title', 'arabicText', 'week']);

    const tableName = process.env.DUA_TABLE_NAME;
    const bucketName = process.env.MEDIA_BUCKET_NAME;
    const duaId = crypto.randomUUID();

    // Upload audio and image if provided
    const audioFile = parsed.files.find(f => f.fieldName === 'audio');
    const imageFile = parsed.files.find(f => f.fieldName === 'image');
    const audioUrl = await uploadToS3(audioFile, 'audio', bucketName);
    const imageUrl = await uploadToS3(imageFile, 'image', bucketName);

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
    return errorResponse(error, error.message.includes('Missing required') || error.message.includes('Invalid') ? 400 : 500);
  }
};