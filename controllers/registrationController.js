const { createRegistration, getGenderCount } = require('../models/registrationModel');

const MAX_BOYS = 50;
const MAX_GIRLS = 50;

const register = async (req, res) => {
  const { name, email, gender } = req.body;

  if (!name || !email || !gender) {
    return res.status(400).json({ message: "All fields required" });
  }

  const count = await getGenderCount(gender);
  if ((gender === 'boy' && count >= MAX_BOYS) || (gender === 'girl' && count >= MAX_GIRLS)) {
    return res.status(400).json({ message: `${gender}s quota full.` });
  }

  const user = await createRegistration({ name, email, gender });
  res.status(201).json({ message: 'Registered', user });
};

module.exports = { register };
