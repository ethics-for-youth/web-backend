// server.js
const express = require('express');
const dotenv = require('dotenv');
const registrationRoutes = require('./routes/registrationRoutes');
const eventRoutes = require('./routes/eventRoutes');

// Load environment variables from .env file
dotenv.config();

// Initialize Express app
const app = express();

// Middleware to parse JSON bodies
app.use(express.json());

// Route middlewares
app.use('/api/registrations', registrationRoutes);
app.use('/api/events', eventRoutes);

// Test route
app.get('/home', (req, res) => {
  res.send('API is running...');
});

// Start the server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
