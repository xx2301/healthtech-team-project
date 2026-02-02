const mongoose = require('mongoose');

const symptomLogSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  
  symptomType: {
    type: String,
    required: true,
    trim: true
  },
  
  severity: {
    type: Number,
    min: 1,
    max: 10,
    required: true
  },
  
  startTime: {
    type: Date,
    required: true,
    default: Date.now
  },
  
  endTime: Date,
  
  duration: {
    type: String,
    set: function() {
      if (this.startTime && this.endTime) {
        const diffMs = this.endTime - this.startTime;
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
        return `${diffHours}h ${diffMinutes}m`;
      }
      return null;
    }
  },
  
  location: String,
  
  triggers: [{
    type: String,
    trim: true
  }],
  
  reliefMethods: [{
    method: String,
    effectiveness: { type: Number, min: 1, max: 5 }
  }],
  
  notes: String,
  
  recordId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MedicalRecord'
  },
  
  impactOnDailyLife: {
    type: String,
    enum: ['none', 'mild', 'moderate', 'severe']
  },
  
  pattern: {
    type: String,
    enum: ['constant', 'intermittent', 'worsening', 'improving']
  },
  
  emotionalState: {
    type: String,
    enum: ['calm', 'anxious', 'stressed', 'depressed', 'neutral']
  }
}, {
  timestamps: true,
  toJSON: { getters: true }
});

symptomLogSchema.index({ patientId: 1, startTime: -1 });
symptomLogSchema.index({ symptomType: 1 });
symptomLogSchema.index({ severity: 1 });

symptomLogSchema.pre('save', function(next) {
  if (this.startTime && this.endTime && !this.duration) {
    const diffMs = this.endTime - this.startTime;
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
    this.duration = `${diffHours}h ${diffMinutes}m`;
  }
  next();
});

const SymptomLog = mongoose.model('SymptomLog', symptomLogSchema);

module.exports = SymptomLog;
