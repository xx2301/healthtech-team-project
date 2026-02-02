const mongoose = require('mongoose');

const healthMetricSchema = new mongoose.Schema({
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
  
  deviceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Device'
  },
  
  metricType: {
    type: String,
    required: true,
    enum: [
      'steps', 'heart_rate', 'blood_pressure', 'blood_glucose',
      'weight', 'height', 'bmi', 'body_temperature',
      'oxygen_saturation', 'sleep_duration', 'calories_burned',
      'water_intake', 'respiratory_rate'
    ]
  },
  
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  
  unit: {
    type: String,
    required: true
  },
  
  timestamp: {
    type: Date,
    required: true,
    default: Date.now
  },
  
  source: {
    type: String,
    enum: ['device', 'manual', 'calculated', 'imported'],
    default: 'manual'
  },
  
  deviceName: String,
  
  qualityScore: {
    type: Number,
    min: 0,
    max: 100,
    default: 100
  },
  
  isAbnormal: {
    type: Boolean,
    default: false
  },
  
  accuracy: {
    type: Number,
    min: 0,
    max: 100
  },
  
  notes: String,
  tags: [String],
  
  isVerified: {
    type: Boolean,
    default: false
  },
  
  verifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor'
  },
  
  verificationDate: Date
}, {
  timestamps: true
});

healthMetricSchema.index({ patientId: 1, metricType: 1, timestamp: -1 });
healthMetricSchema.index({ userId: 1 });
healthMetricSchema.index({ deviceId: 1 });
healthMetricSchema.index({ timestamp: 1 });
healthMetricSchema.index({ metricType: 1, isAbnormal: 1 });

healthMetricSchema.index({ patientId: 1, timestamp: -1, metricType: 1 });

healthMetricSchema.pre('save', function(next) {
  if (!this.unit) {
    const unitMap = {
      steps: 'steps',
      heart_rate: 'bpm',
      blood_pressure: 'mmHg',
      blood_glucose: 'mg/dL',
      weight: 'kg',
      height: 'cm',
      body_temperature: '°C',
      oxygen_saturation: '%',
      sleep_duration: 'hours',
      calories_burned: 'kcal',
      water_intake: 'ml',
      respiratory_rate: 'breaths/min'
    };
    
    this.unit = unitMap[this.metricType] || 'unknown';
  }
  
  if (this.value && !this.isAbnormal) {
    this.detectAbnormal();
  }
  
  next();
});

healthMetricSchema.methods.detectAbnormal = function() {
  const normalRanges = {
    heart_rate: { min: 60, max: 100 },
    blood_pressure_systolic: { min: 90, max: 120 },
    blood_pressure_diastolic: { min: 60, max: 80 },
    blood_glucose: { min: 70, max: 140 },
    body_temperature: { min: 36.1, max: 37.2 },
    oxygen_saturation: { min: 95, max: 100 },
    respiratory_rate: { min: 12, max: 20 }
  };
  
  if (this.metricType === 'blood_pressure' && typeof this.value === 'object') {
    const systolic = this.value.systolic;
    const diastolic = this.value.diastolic;
    
    this.isAbnormal = systolic < 90 || systolic > 140 || 
                      diastolic < 60 || diastolic > 90;
  } else if (normalRanges[this.metricType]) {
    const range = normalRanges[this.metricType];
    this.isAbnormal = this.value < range.min || this.value > range.max;
  }
};

healthMetricSchema.statics.getLatestMetrics = function(patientId, metricTypes) {
  const query = { patientId };
  
  if (metricTypes && metricTypes.length > 0) {
    query.metricType = { $in: metricTypes };
  }
  
  return this.find(query)
    .sort({ timestamp: -1 })
    .limit(50)
    .exec();
};

healthMetricSchema.statics.getMetricTrend = function(patientId, metricType, startDate, endDate) {
  return this.find({
    patientId,
    metricType,
    timestamp: { $gte: startDate, $lte: endDate }
  })
  .sort({ timestamp: 1 })
  .select('value timestamp')
  .exec();
};

const HealthMetric = mongoose.model('HealthMetric', healthMetricSchema);

module.exports = HealthMetric;