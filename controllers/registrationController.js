const { registerUser } = require('../models/RegistrationModel');

const handleRegistration = async (req, res) => {
  const {
    fullName, age, email, phone, gender, communication, additionalInfo,
  } = req.body;

  if (!fullName || !age || !email || !phone || !gender) {
    return res.status(400).json({ error: 'Please fill all required fields.' });
  }

  try {
    const savedUser = await registerUser({
      fullName,
      age,
      email,
      phone,
      gender,
      communication,
      additionalInfo,
    });

    res.status(201).json({
      message: 'Registration successful',
      data: savedUser,
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Failed to register user.' });
  }
};

module.exports = { handleRegistration };
