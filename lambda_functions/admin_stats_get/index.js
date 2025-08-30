// Import from utility layer
const { successResponse, errorResponse } = require('/opt/nodejs/utils');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    try {
        console.log('Event: ', JSON.stringify(event, null, 2));
        
        // Aggregate data from all tables
        const stats = await gatherStats();
        
        const data = {
            stats,
            requestId: event.requestContext?.requestId,
            timestamp: new Date().toISOString(),
            lastUpdated: new Date().toISOString()
        };
        
        return successResponse(data, 'Admin statistics retrieved successfully');
        
    } catch (error) {
        console.error('Error in admin_stats_get function:', error);
        return errorResponse(error, 500);
    }
};

async function gatherStats() {
    try {
        // Gather counts from all tables in parallel
        const [eventsCount, competitionsCount, volunteersCount, participantsCount, coursesCount, registrationsCount, messagesCount] = await Promise.all([
            getTableCount(process.env.EVENTS_TABLE_NAME),
            getTableCount(process.env.COMPETITIONS_TABLE_NAME),
            getTableCount(process.env.VOLUNTEERS_TABLE_NAME),
            getRegistrationsCount('participant'), // Count unique participants
            getTableCount(process.env.COURSES_TABLE_NAME),
            getTableCount(process.env.REGISTRATIONS_TABLE_NAME),
            getTableCount(process.env.MESSAGES_TABLE_NAME)
        ]);
        
        // Get more detailed statistics
        const [activeEvents, upcomingCompetitions, pendingMessages, recentRegistrations] = await Promise.all([
            getActiveEvents(),
            getUpcomingCompetitions(),
            getPendingMessages(),
            getRecentRegistrations()
        ]);
        
        return {
            overview: {
                totalEvents: eventsCount,
                totalCompetitions: competitionsCount,
                totalVolunteers: volunteersCount,
                totalParticipants: participantsCount,
                totalCourses: coursesCount,
                totalRegistrations: registrationsCount,
                totalMessages: messagesCount
            },
            events: {
                total: eventsCount,
                active: activeEvents.length,
                upcoming: activeEvents.filter(event => new Date(event.date) > new Date()).length
            },
            competitions: {
                total: competitionsCount,
                upcoming: upcomingCompetitions.length
            },
            volunteers: {
                total: volunteersCount
            },
            courses: {
                total: coursesCount
            },
            registrations: {
                total: registrationsCount,
                recent: recentRegistrations.length
            },
            messages: {
                total: messagesCount,
                pending: pendingMessages.length,
                byType: await getMessagesByType()
            }
        };
    } catch (error) {
        console.error('Error gathering stats:', error);
        // Return mock data if there's an error accessing tables
        return {
            overview: {
                totalEvents: 0,
                totalCompetitions: 0,
                totalVolunteers: 0,
                totalParticipants: 0,
                totalCourses: 0,
                totalRegistrations: 0,
                totalMessages: 0
            },
            events: { total: 0, active: 0, upcoming: 0 },
            competitions: { total: 0, upcoming: 0 },
            volunteers: { total: 0 },
            courses: { total: 0 },
            registrations: { total: 0, recent: 0 },
            messages: { total: 0, pending: 0, byType: {} },
            error: 'Some statistics may be unavailable'
        };
    }
}

async function getTableCount(tableName) {
    if (!tableName) return 0;
    
    try {
        const command = new ScanCommand({
            TableName: tableName,
            Select: 'COUNT'
        });
        
        const result = await docClient.send(command);
        return result.Count || 0;
    } catch (error) {
        console.error(`Error getting count for table ${tableName}:`, error);
        return 0;
    }
}

async function getRegistrationsCount(itemType) {
    if (!process.env.REGISTRATIONS_TABLE_NAME) return 0;
    
    try {
        const command = new ScanCommand({
            TableName: process.env.REGISTRATIONS_TABLE_NAME,
            FilterExpression: 'itemType = :itemType',
            ExpressionAttributeValues: {
                ':itemType': itemType
            },
            Select: 'COUNT'
        });
        
        const result = await docClient.send(command);
        return result.Count || 0;
    } catch (error) {
        console.error('Error getting registrations count:', error);
        return 0;
    }
}

async function getActiveEvents() {
    if (!process.env.EVENTS_TABLE_NAME) return [];
    
    try {
        const command = new ScanCommand({
            TableName: process.env.EVENTS_TABLE_NAME,
            FilterExpression: '#status = :status',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':status': 'active'
            }
        });
        
        const result = await docClient.send(command);
        return result.Items || [];
    } catch (error) {
        console.error('Error getting active events:', error);
        return [];
    }
}

async function getUpcomingCompetitions() {
    if (!process.env.COMPETITIONS_TABLE_NAME) return [];
    
    try {
        const command = new ScanCommand({
            TableName: process.env.COMPETITIONS_TABLE_NAME,
            FilterExpression: '#status = :status',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':status': 'active'
            }
        });
        
        const result = await docClient.send(command);
        return result.Items || [];
    } catch (error) {
        console.error('Error getting upcoming competitions:', error);
        return [];
    }
}

async function getPendingMessages() {
    if (!process.env.MESSAGES_TABLE_NAME) return [];
    
    try {
        const command = new ScanCommand({
            TableName: process.env.MESSAGES_TABLE_NAME,
            FilterExpression: '#status = :status',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':status': 'new'
            }
        });
        
        const result = await docClient.send(command);
        return result.Items || [];
    } catch (error) {
        console.error('Error getting pending messages:', error);
        return [];
    }
}

async function getRecentRegistrations() {
    if (!process.env.REGISTRATIONS_TABLE_NAME) return [];
    
    try {
        const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
        
        const command = new ScanCommand({
            TableName: process.env.REGISTRATIONS_TABLE_NAME,
            FilterExpression: 'registeredAt > :oneWeekAgo',
            ExpressionAttributeValues: {
                ':oneWeekAgo': oneWeekAgo
            }
        });
        
        const result = await docClient.send(command);
        return result.Items || [];
    } catch (error) {
        console.error('Error getting recent registrations:', error);
        return [];
    }
}

async function getMessagesByType() {
    if (!process.env.MESSAGES_TABLE_NAME) return {};
    
    try {
        const command = new ScanCommand({
            TableName: process.env.MESSAGES_TABLE_NAME,
            ProjectionExpression: 'messageType'
        });
        
        const result = await docClient.send(command);
        const messages = result.Items || [];
        
        // Count messages by type
        const typeCount = {};
        messages.forEach(message => {
            const type = message.messageType || 'unknown';
            typeCount[type] = (typeCount[type] || 0) + 1;
        });
        
        return typeCount;
    } catch (error) {
        console.error('Error getting messages by type:', error);
        return {};
    }
}