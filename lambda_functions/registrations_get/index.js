// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, BatchGetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));

        const registrationsTable = process.env.REGISTRATIONS_TABLE_NAME;
        const eventsTable = process.env.EVENTS_TABLE_NAME;
        const coursesTable = process.env.COURSES_TABLE_NAME;
        const competitionsTable = process.env.COMPETITIONS_TABLE_NAME;

        const queryParams = event.queryStringParameters || {};
        let command = new ScanCommand({ TableName: registrationsTable });

        // ---- Filter by itemType ----
        if (queryParams.itemType) {
            command.input.FilterExpression = 'itemType = :itemType';
            command.input.ExpressionAttributeValues = {
                ':itemType': queryParams.itemType
            };
        }

        // ---- Filter by itemId ----
        if (queryParams.itemId) {
            if (command.input.FilterExpression) {
                command.input.FilterExpression += ' AND itemId = :itemId';
                command.input.ExpressionAttributeValues[':itemId'] = queryParams.itemId;
            } else {
                command.input.FilterExpression = 'itemId = :itemId';
                command.input.ExpressionAttributeValues = {
                    ':itemId': queryParams.itemId
                };
            }
        }

        // ---- Execute initial scan ----
        const result = await docClient.send(command);
        let registrations = result.Items || [];

        // -------------------------------
        // STEP 1: Batch fetch item titles
        // -------------------------------
        let titlesList = [];
        if (queryParams.itemType) {
            // Get all unique itemIds from registrations
            const itemIds = [...new Set(registrations.map(r => r.itemId))];

            // Select correct table based on itemType
            let itemTable;
            if (queryParams.itemType === 'event') itemTable = eventsTable;
            else if (queryParams.itemType === 'course') itemTable = coursesTable;
            else itemTable = competitionsTable;

            if (itemIds.length > 0) {
                const batchCommand = new BatchGetCommand({
                    RequestItems: {
                        [itemTable]: {
                            Keys: itemIds.map(id => ({ id })),
                            ProjectionExpression: 'id, title'
                        }
                    }
                });

                const batchResult = await docClient.send(batchCommand);
                const fetchedItems = batchResult.Responses[itemTable] || [];

                // Create a map for faster lookup
                const titleMap = {};
                fetchedItems.forEach(item => {
                    titleMap[item.id] = item.title;
                });

                // Attach itemTitle to registrations
                registrations = registrations.map(reg => ({
                    ...reg,
                    itemTitle: titleMap[reg.itemId] || null
                }));

                // Prepare list of all available titles
                titlesList = fetchedItems.map(item => ({ id: item.id, title: item.title }));
            }
        }

        // -------------------------------
        // STEP 2: Filter by title if requested
        // -------------------------------
        if (queryParams.title) {
            const searchTitle = queryParams.title.toLowerCase();
            registrations = registrations.filter(
                reg => reg.itemTitle && reg.itemTitle.toLowerCase().includes(searchTitle)
            );
        }
        // ---- Stats by itemType ----
        const statsByType = registrations.reduce((acc, r) => {
            acc[r.itemType] = (acc[r.itemType] || 0) + 1;
            return acc;
        }, {});

        // ---- Stats by itemId ----
        const statsByItem = registrations.reduce((acc, r) => {
            const key = r.itemId;
            acc[key] = (acc[key] || 0) + 1;
            return acc;
        }, {});

        // ---- Stats by itemTitle (if attached) ----
        const statsByTitle = registrations.reduce((acc, r) => {
            if (r.itemTitle) {
                acc[r.itemTitle] = (acc[r.itemTitle] || 0) + 1;
            }
            return acc;
        }, {});

        const data = {
            registrations,
            count: registrations.length,
            availableTitles: titlesList,
            filters: queryParams,
            stats: {
                byType: statsByType,
                byItem: statsByItem,
                byTitle: statsByTitle
            },
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString()
        };

        return successResponse(data, 'Registrations retrieved successfully');

    } catch (error) {
        console.error('Error in registrations_get function:', error);
        return errorResponse(error, 500);
    }
};
