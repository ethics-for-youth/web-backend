// server.js
const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json()); // Parses incoming JSON requests

// Routes
app.get("/", (req, res) => {
  res.send("API is running...");
});



// Start server
app.listen(PORT, () => {
  console.log(` Server running on http://localhost:${PORT}`);
});
