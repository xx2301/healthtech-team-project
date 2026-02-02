const mongoose = require('mongoose');

const healthReportSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  
  reportPeriodStart: {
    type: Date,
    required: true
  },
  
  reportPeriodEnd: {
    type: Date,
    required: true
  },
  
  generatedDate: {
    type: Date,
    default: Date.now
  },
  
  reportType: {
    type: String,
    required: true,
    enum: ['weekly', 'monthly', 'quarterly', 'annual', 'custom']
  },
  
  summaryText: String,
  
  goalsAchievedCount: {
    type: Number,
    default: 0
  },
  
  totalGoalsCount: {
    type: Number,
    default: 0
  },
  
  overallHealthScore: {
    type: Number,
    min: 0,
    max: 100
  },
  
  trendAnalysis: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  
  recommendations: [{
    category: String,
    description: String,
    priority: { type: String, enum: ['low', 'medium', 'high'] }
  }],
  
  metricsSummary: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  
  exportFormat: {
    type: String,
    enum: ['pdf', 'html', 'json'],
    default: 'json'
  },
  
  isShared: {
    type: Boolean,
    default: false
  },
  
  sharedWith: [{
    doctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor' },
    sharedDate: { type: Date, default: Date.now },
    permissions: [String]
  }],
  
  generatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  
  notes: String
}, {
  timestamps: true
});

healthReportSchema.index({ patientId: 1, generatedDate: -1 });
healthReportSchema.index({ reportPeriodStart: 1, reportPeriodEnd: 1 });
healthReportSchema.index({ isShared: 1 });

healthReportSchema.virtual('goalsAchievementRate').get(function() {
  if (this.totalGoalsCount === 0) return 0;
  return (this.goalsAchievedCount / this.totalGoalsCount) * 100;
});

healthReportSchema.statics.generateReport = async function(patientId, startDate, endDate, reportType) {
  //add logic to aggregate data and generate report
  //example get data from HealthMetrics and HealthGoals models
  
  const report = new this({
    patientId,
    reportPeriodStart: startDate,
    reportPeriodEnd: endDate,
    reportType,
    generatedDate: new Date()
  });
  
  return await report.save();
};

const HealthReport = mongoose.model('HealthReport', healthReportSchema);

module.exports = HealthReport;
