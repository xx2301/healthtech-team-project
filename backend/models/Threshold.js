const mongoose = require('mongoose');

const thresholdSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  metricType: {
    type: String,
    required: true,
    enum: [
      'steps', 'heart_rate', 'blood_pressure_systolic', 'blood_pressure_diastolic',
      'glucose', 'weight', 'body_temperature', 'oxygen_saturation',
      'sleep_duration', 'calories_burned'
    ]
  },
  minThreshold: {
    type: Number,
    default: null,
  },
  maxThreshold: {
    type: Number,
    default: null,
  },
  enabled: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  }
});

thresholdSchema.index({ userId: 1, metricType: 1 }, { unique: true });

const Threshold = mongoose.model('Threshold', thresholdSchema);

module.exports = Threshold;