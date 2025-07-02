const { createEvent, getEvents } = require('../models/eventModel');

const addEvent = async (req, res) => {
  const { title, description, date, type } = req.body;

  if (!title || !date || !type) {
    return res.status(400).json({ message: 'Missing fields' });
  }

  const event = await createEvent({ title, description, date, type });
  res.status(201).json({ message: 'Event added', event });
};

const fetchEvents = async (req, res) => {
  const { type } = req.query;
  const events = await getEvents(type);
  res.status(200).json(events);
};

module.exports = { addEvent, fetchEvents };
