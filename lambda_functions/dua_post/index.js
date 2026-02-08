const { successResponse, errorResponse, validateRequired, parseJSON } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const crypto = require('crypto');
const multipart = require('aws-lambda-multipart-parser');

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);
const s3Client = new S3Client({ region: process.env.AWS_REGION });

const ALLOWED_AUDIO_EXT = ['mp3','wav', 'm4a', 'ogg','mpeg'];
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
    Body: file.content,
    ContentType: type === 'audio' ? 'audio/mpeg' : `image/${ext}`,
  });

  await s3Client.send(command);
  return key; // Store only the object key
}

exports.handler = async (event) => {
  try {
    console.log('Event:', JSON.stringify(event));

    // Prepare event body
    let bodyString = event.isBase64Encoded
      ? Buffer.from(event.body, 'base64').toString('latin1')
      : event.body;

    // Parse multipart/form-data
    const parsed = multipart.parse(
      { ...event, body: bodyString },
      true
    );

    // Convert text fields to UTF-8 and fix encoding for Arabic, Hindi, Urdu
    const body = {
      title: parsed.title?.toString('utf8') || '',
      arabicText: parsed.arabicText
        ? Buffer.from(parsed.arabicText.toString('latin1'), 'latin1').toString('utf8')
        : '',
      week: parsed.week?.toString('utf8') || '',
      transcription: parsed.transcription
        ? parseJSON(parsed.transcription.toString('utf8'))
        : {},
      translation: parsed.translation
        ? parseJSON(parsed.translation.toString('utf8'))
        : {}
    };

    // Fix Hindi & Urdu encoding in transcription
    if (body.transcription.hindi)
      body.transcription.hindi = Buffer.from(body.transcription.hindi, 'latin1').toString('utf8');
    if (body.transcription.urdu)
      body.transcription.urdu = Buffer.from(body.transcription.urdu, 'latin1').toString('utf8');

    // Fix Hindi & Urdu encoding in translation
    if (body.translation.hindi)
      body.translation.hindi = Buffer.from(body.translation.hindi, 'latin1').toString('utf8');
    if (body.translation.urdu)
      body.translation.urdu = Buffer.from(body.translation.urdu, 'latin1').toString('utf8');

    validateRequired(body, ['title', 'arabicText', 'week']);

    const tableName = process.env.DUA_TABLE_NAME;
    const bucketName = process.env.S3_BUCKET_NAME;
    const duaId = crypto.randomUUID();

    // Upload files and store keys only
    const audioKey = parsed.audio ? await uploadToS3(parsed.audio, 'audio', bucketName) : null;
    const imageKey = parsed.image ? await uploadToS3(parsed.image, 'image', bucketName) : null;

    // Prepare DynamoDB item
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
      audioKey,
      imageKey,
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
