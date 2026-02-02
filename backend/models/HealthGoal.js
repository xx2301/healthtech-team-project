const mongoose = require('mongoose');

const healthGoalSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  goalType: {
    type: String,
    required: true,
    enum: ['weight_loss', 'fitness', 'nutrition', 'medication', 'sleep', 'other']
  },
  
  title: {
    type: String,
    required: true,
    trim: true
  },
  
  description: String,
  
  targetValue: {
    type: Number,
    required: true
  },
  
  currentValue: {
    type: Number,
    default: 0
  },
  
  startDate: {
    type: Date,
    default: Date.now
  },
  
  targetDate: {
    type: Date,
    required: true
  },
  
  frequency: {
    type: String,
    enum: ['daily', 'weekly', 'monthly'],
    default: 'daily'
  },
  
  priority: {
    type: String,
    enum: ['low', 'medium', 'high'],
    default: 'medium'
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  progressPercentage: {
    type: Number,
    min: 0,
    max: 100,
    default: 0
  },
  
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  
  notes: String,
  
  category: String,
  
  reminders: [{
    time: String,
    enabled: { type: Boolean, default: true }
  }]
}, {
  timestamps: true
});

healthGoalSchema.index({ patientId: 1, isActive: 1 });
healthGoalSchema.index({ targetDate: 1 });
healthGoalSchema.index({ priority: 1 });

healthGoalSchema.virtual('daysRemaining').get(function() {
  const today = new Date();
  const target = new Date(this.targetDate);
  const diffTime = target - today;
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
});

healthGoalSchema.methods.updateProgress = function(newValue) {
  this.currentValue = newValue;
  this.progressPercentage = (newValue / this.targetValue) * 100;
  this.lastUpdated = new Date();
  return this.save();
};

healthGoalSchema.methods.isCompleted = function() {
  return this.progressPercentage >= 100;
};

const HealthGoal = mongoose.model('HealthGoal', healthGoalSchema);

module.exports = HealthGoal;
