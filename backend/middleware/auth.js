const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, error: 'Access token missing' });
  }

  jwt.verify(token, JWT_SECRET, async (err, decoded) => {
    if (err) {
      return res.status(403).json({ success: false, error: 'Invalid access token' });
    }

    try {
      const user = await User.findById(decoded.userId);

      if (!user) {
        return res.status(404).json({ success: false, error: 'User not found' });
      }
      
      let detailedUser = user;
      if (user.userType === 'doctor') {
        detailedUser = await Doctor.findById(user._id);
      } else if (user.userType === 'patient') {
        detailedUser = await Patient.findById(user._id);
      }
      
      req.user = {
        userId: detailedUser._id,
        email: detailedUser.email,
        userType: detailedUser.userType,
        ...detailedUser.toObject()
      };
      
      next();
    } catch (error) {
      return res.status(500).json({ success: false, error: 'Failed to authenticate user' });
    }
  });
};

module.exports = authenticateToken;