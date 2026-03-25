const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Session = require('../models/Session');
const emailService = require('../services/emailService');
const HealthGoal = require('../models/HealthGoal');
const { authenticateToken } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('fullName').notEmpty().trim().escape(),
  body('age').optional().isString(),
  body('height').optional().isString(),
  body('weight').optional().isString(),
  body('dateOfBirth').optional().isISO8601().toDate(),
  body('gender').optional().isIn(['male', 'female', 'other', 'prefer_not_to_say'])
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      success: false, 
      errors: errors.array(),
      message: 'Validation failed' 
    });
  }

  try {
    const { email, password, fullName, age, height, weight, dateOfBirth, gender } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email has already been registered' 
      });
    }

    const user = new User({
      email,
      password,
      fullName,
      age: age || '',
      height: height || '',
      weight: weight || '',
      userType: 'user',
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
      gender: gender || 'other',
      isActive: true,
    });

    await user.save();

    try {
      const defaultGoals = [
        {
          goalType: 'steps',
          title: 'Daily Steps Goal',
          targetValue: 6000,
          frequency: 'daily',
          targetDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          priority: 'medium',
          description: 'Aim to walk 6000 steps per day',
        },
        {
          goalType: 'calories_burned',
          title: 'Daily Calories Goal',
          targetValue: 12700,
          frequency: 'daily',
          targetDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          priority: 'medium',
          description: 'Burn 12700 active calories per day',
        },
        {
          goalType: 'sleep_duration',
          title: 'Daily Sleep Goal',
          targetValue: 8,
          frequency: 'daily',
          targetDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          priority: 'medium',
          description: 'Get 8 hours of sleep per night',
        },
        {
          goalType: 'water_intake',
          title: 'Daily Water Intake Goal',
          targetValue: 2000,
          frequency: 'daily',
          targetDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          priority: 'medium',
          description: 'Drink 2000 ml of water per day',
        },
      ];

      await HealthGoal.insertMany(
        defaultGoals.map(g => ({ ...g, userId: user._id }))
      );
    } catch (goalError) {
      console.error('Failed to create default goals for user', user.email, goalError);
    }

    const userAgent = req.headers['user-agent'] || 'Unknown';
    const ip = req.ip || req.connection.remoteAddress;

    let deviceType = 'unknown';
    if (userAgent.includes('Mobile')) deviceType = 'mobile';
    else if (userAgent.includes('Tablet')) deviceType = 'tablet';
    else deviceType = 'desktop';

    const sessionCount = await Session.countDocuments({ userId: user._id });
    if (sessionCount >= 3) {
      const oldest = await Session.findOne({ userId: user._id }).sort('createdAt');
      if (oldest) await oldest.deleteOne();
    }

    const session = new Session({
      userId: user._id,
      deviceName: userAgent,
      deviceType,
      ipAddress: ip,
      userAgent,
      lastActiveAt: new Date()
    });
    await session.save();

    const token = jwt.sign(
      { userId: user._id, email: user.email, userType: user.userType, sessionId: session._id },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Registration failed',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Please try again later'
    });
  }
});

router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { email, password } = req.body;
    console.log('Login attempt - email:', email);
    console.log('Login attempt - password (raw):', password);

    const user = await User.findOne({ email });
    if (!user) {
      console.log('User not found');
      return res.status(401).json({ 
        success: false, 
        error: 'Email or password incorrect' 
      });
    }

    console.log('Stored hash:', user.password);
    const isValidPassword = await user.comparePassword(password);
    console.log('Password valid?', isValidPassword);

    if (!isValidPassword) {
      return res.status(401).json({ 
        success: false, 
        error: 'Email or password incorrect' 
      });
    }

    user.updatedAt = new Date();
    await user.save();

    const userAgent = req.headers['user-agent'] || 'Unknown';
    const ip = req.ip || req.connection.remoteAddress;

    let deviceType = 'unknown';
    if (userAgent.includes('Mobile')) deviceType = 'mobile';
    else if (userAgent.includes('Tablet')) deviceType = 'tablet';
    else deviceType = 'desktop';

    const sessionCount = await Session.countDocuments({ userId: user._id });
    if (sessionCount >= 3) {
      const oldest = await Session.findOne({ userId: user._id }).sort('createdAt');
      if (oldest) await oldest.deleteOne();
    }

    const session = new Session({
      userId: user._id,
      deviceName: userAgent,
      deviceType,
      ipAddress: ip,
      userAgent,
      lastActiveAt: new Date()
    });
    await session.save();

    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email,
        userType: user.userType,
        role: user.role,
        sessionId: session._id,
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Login failed' 
    });
  }
});

router.get('/me', requireRole('user'), async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    const userResponse = user.toObject();
    delete userResponse.password;
    res.status(200).json({ success: true, user: userResponse });
  } catch (error) {
    console.error('Fetch user info error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch user information' });
  }
});

router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(200).json({ message: 'If that email is registered, a reset link has been sent.' });
    }
    const token = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = token;
    user.resetPasswordExpires = Date.now() + 3600000;
    await user.save();
    await emailService.sendPasswordResetEmail(email, token);
    res.status(200).json({ message: 'Password reset email sent! Check your inbox.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  console.log('Received reset request with token:', token);
  try {
    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() },
    });
    console.log('Found user:', user ? user.email : 'none');
    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired token' });
    }
    user.password = newPassword;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();
    console.log('Password updated for:', user.email);
    const updatedUser = await User.findById(user._id);
    console.log('After reset, stored hash in DB:', updatedUser.password);
    res.status(200).json({ message: 'Password reset successful' });
  } catch (error) {
    console.error('Reset error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;