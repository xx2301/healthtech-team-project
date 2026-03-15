const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    required: true,
    trim: true
  },
  model: {
    type: String,
    default: ''
  },
  manufacturer: {
    type: String,
    default: ''
  },
  serialNumber: {
    type: String,
    default: ''
  },
  isActive: {
    type: Boolean,
    default: true
  },
  status: {
    type: String,
    enum: ['online', 'offline', 'error'],
    default: 'online'
  },
  externalSource: {
    type: String,
    enum: ['apple_health', 'google_fit', 'garmin', 'fitbit', 'other', null],
    default: null
  },
  lastSyncAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

deviceSchema.index({ userId: 1, type: 1 });

const Device = mongoose.model('Device', deviceSchema);

module.exports = Device;