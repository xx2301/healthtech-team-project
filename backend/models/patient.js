const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  
  patientCode: {
    type: String,
    unique: true,
    default: function() {
      const randomNum = Math.floor(Math.random() * 9000) + 1000;
      return `PAT${Date.now().toString().slice(-6)}${randomNum}`;
    }
  },
  
  weight: {
    type: Number,
    min: 0,
    max: 500,
    set: v => parseFloat(v.toFixed(1))
  },
  
  height: {
    type: Number,
    min: 0,
    max: 300,
    set: v => parseFloat(v.toFixed(1))
  },
  
  bloodType: {
    type: String,
    enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'unknown'],
    default: 'unknown'
  },
  
  allergies: [{
    allergen: { type: String, required: true },
    severity: { type: String, enum: ['mild', 'moderate', 'severe'] },
    reaction: String,
    firstObserved: Date,
    notes: String,
    isActive: { type: Boolean, default: true }
  }],
  
  chronicConditions: [{
    condition: { type: String, required: true },
    diagnosedDate: Date,
    status: { type: String, enum: ['active', 'controlled', 'in_remission'] },
    medications: [{
      name: String,
      dosage: String,
      frequency: String,
      startDate: Date,
      endDate: Date
    }],
    lastCheckup: Date,
    notes: String
  }],
  
  emergencyContacts: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'EmergencyContact'
  }],
  
  careModeEnabled: {
    type: Boolean,
    default: false
  },
  
  preferredUnitSystem: {
    type: String,
    enum: ['metric', 'imperial'],
    default: 'metric'
  },
  
  primaryDoctor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor'
  },
  
  smokingStatus: {
    type: String,
    enum: ['never', 'former', 'current'],
    default: 'never'
  },
  alcoholConsumption: {
    type: String,
    enum: ['none', 'light', 'moderate', 'heavy'],
    default: 'none'
  },
  exerciseFrequency: {
    type: String,
    enum: ['sedentary', 'light', 'moderate', 'active', 'very_active'],
    default: 'sedentary'
  },
  
  medicalHistorySummary: String,
  
  dataSharingConsent: {
    type: Boolean,
    default: false
  },
  shareWithDoctors: [{
    doctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor' },
    permissions: [String],
    grantedDate: Date,
    expiresDate: Date
  }]
}, {
  timestamps: true
});

patientSchema.virtual('age').get(function() {
  //get birthday by associated User
  return null; //populate userId is required for calculation.
});

patientSchema.virtual('bmi').get(function() {
  if (!this.weight || !this.height) return null;
  const heightInMeters = this.height / 100;
  return (this.weight / (heightInMeters * heightInMeters)).toFixed(2);
});

patientSchema.index({ userId: 1 }, { unique: true });
patientSchema.index({ patientCode: 1 }, { unique: true });
patientSchema.index({ primaryDoctor: 1 });

const Patient = mongoose.model('Patient', patientSchema);

module.exports = Patient;