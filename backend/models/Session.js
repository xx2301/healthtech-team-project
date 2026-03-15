const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  deviceName: {
    type: String,
    required: true
  },
  deviceType: {
    type: String,
    enum: ['mobile', 'tablet', 'desktop', 'unknown'],
    default: 'unknown'
  },
  ipAddress: String,
  userAgent: String,
  refreshToken: String,
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 30 * 24 * 60 * 60 // 30 days later auto-delete
  },
  lastActiveAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Session', sessionSchema);