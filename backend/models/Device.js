const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema({
  deviceUUID: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  
  deviceName: {
    type: String,
    required: true,
    trim: true
  },
  
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient'
  },
  
  platform: {
    type: String,
    enum: ['ios', 'android', 'web', 'wearable', 'medical_device']
  },
  
  manufacturer: String,
  
  model: String,
  
  batteryLevel: {
    type: Number,
    min: 0,
    max: 100
  },
  
  connectionType: {
    type: String,
    enum: ['bluetooth', 'wifi', 'cellular', 'usb']
  },
  
  lastKnownLocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],  //[longitude, latitude]
      default: [0, 0]
    }
  },
  
  lastSyncTime: {
    type: Date,
    default: Date.now
  },
  
  appVersion: String,
  
  osVersion: String,
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  capabilities: [{
    type: String,
    enum: ['heart_rate', 'steps', 'sleep', 'blood_pressure', 'glucose', 'oxygen']
  }],
  
  settings: {
    syncFrequency: { type: Number, default: 300 }, //default is 5mins
    dataSharing: { type: Boolean, default: true },
    notifications: { type: Boolean, default: true }
  },
  
  metadata: mongoose.Schema.Types.Mixed
}, {
  timestamps: true
});

deviceSchema.index({ lastKnownLocation: '2dsphere' });

deviceSchema.index({ deviceUUID: 1 }, { unique: true });
deviceSchema.index({ patientId: 1 });
deviceSchema.index({ isActive: 1 });

deviceSchema.methods.updateSyncTime = function() {
  this.lastSyncTime = new Date();
  return this.save();
};

deviceSchema.methods.needsSync = function() {
  const now = new Date();
  const lastSync = this.lastSyncTime;
  const syncFrequency = this.settings?.syncFrequency || 300; //default is 5mins
  
  return (now - lastSync) > (syncFrequency * 1000);
};

const Device = mongoose.model('Device', deviceSchema);

module.exports = Device;
