const mongoose = require('mongoose');

const medicalRecordSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  
  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor',
    required: true
  },
  
  visitDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  
  visitType: {
    type: String,
    enum: [
      'consultation', 'follow_up', 'emergency', 
      'routine_checkup', 'vaccination', 'lab_test'
    ],
    required: true
  },
  
  symptoms: [{
    description: String,
    severity: { type: Number, min: 1, max: 10 },
    duration: String,
    onset: Date
  }],
  
  diagnosis: {
    primary: String,
    secondary: [String],
    icd10Code: String,
    notes: String
  },
  
  prescriptions: [{
    medication: String,
    dosage: String,
    frequency: String,
    duration: String,
    quantity: Number,
    instructions: String,
    refills: { type: Number, default: 0 },
    prescribedDate: { type: Date, default: Date.now }
  }],
  
  labResults: [{
    testName: String,
    testDate: Date,
    results: String,
    units: String,
    normalRange: String,
    isAbnormal: Boolean,
    labName: String,
    fileUrl: String
  }],
  
  treatmentPlan: {
    description: String,
    medications: [String],
    procedures: [String],
    lifestyleChanges: String,
    duration: String
  },
  
  followUpDate: Date,
  followUpInstructions: String,
  
  recordStatus: {
    type: String,
    enum: ['draft', 'finalized', 'reviewed', 'archived'],
    default: 'draft'
  },
  
  attachments: [{
    fileName: String,
    fileType: String,
    fileUrl: String,
    uploadedDate: { type: Date, default: Date.now }
  }],
  
  notes: String,
  recommendations: String,
  
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  
  lastUpdatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

medicalRecordSchema.index({ patientId: 1, visitDate: -1 });
medicalRecordSchema.index({ doctorId: 1 });
medicalRecordSchema.index({ visitType: 1 });
medicalRecordSchema.index({ 'diagnosis.icd10Code': 1 });
medicalRecordSchema.index({ followUpDate: 1 });

medicalRecordSchema.virtual('patient', {
  ref: 'Patient',
  localField: 'patientId',
  foreignField: '_id',
  justOne: true
});

medicalRecordSchema.virtual('doctor', {
  ref: 'Doctor',
  localField: 'doctorId',
  foreignField: '_id',
  justOne: true
});

medicalRecordSchema.methods.addPrescription = function(prescriptionData) {
  this.prescriptions.push({
    ...prescriptionData,
    prescribedDate: new Date()
  });
  return this.save();
};

medicalRecordSchema.methods.markAsFinalized = function(userId) {
  this.recordStatus = 'finalized';
  this.lastUpdatedBy = userId;
  return this.save();
};

medicalRecordSchema.statics.getPatientRecords = function(patientId, options = {}) {
  const query = { patientId };
  
  if (options.startDate || options.endDate) {
    query.visitDate = {};
    if (options.startDate) query.visitDate.$gte = options.startDate;
    if (options.endDate) query.visitDate.$lte = options.endDate;
  }
  
  if (options.visitType) query.visitType = options.visitType;
  
  return this.find(query)
    .sort({ visitDate: -1 })
    .populate('doctor', 'fullName specialization')
    .populate('patient', 'fullName dateOfBirth')
    .exec();
};

const MedicalRecord = mongoose.model('MedicalRecord', medicalRecordSchema);

module.exports = MedicalRecord;