const express = require('express');
const { addEvent, fetchEvents } = require('../controllers/eventController');
const router = express.Router();

router.post('/event', addEvent);
router.get('/events', fetchEvents);

module.exports = router;
