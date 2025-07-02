const express = require('express');
const { handleRegistration } = require('../controllers/registrationController.js');

const router = express.Router();

router.post('/register', handleRegistration);

module.exports = router;
