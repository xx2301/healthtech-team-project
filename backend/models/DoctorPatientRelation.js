const mongoose = require('mongoose');

const doctorPatientRelationSchema = new mongoose.Schema({
  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor',
    required: true
  },
  
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  
  relationType: {
    type: String,
    enum: ['primary', 'specialist', 'consultant', 'temporary'],
    default: 'primary'
  },
  
  status: {
    type: String,
    enum: ['active', 'pending', 'inactive', 'terminated'],
    default: 'pending'
  },
  
  startDate: {
    type: Date,
    default: Date.now
  },
  
  endDate: Date,
  
  permissions: {
    viewMedicalRecords: { type: Boolean, default: false },
    writePrescriptions: { type: Boolean, default: false },
    viewHealthMetrics: { type: Boolean, default: false },
    addMedicalNotes: { type: Boolean, default: false },
    scheduleAppointments: { type: Boolean, default: false }
  },
  
  accessLevel: {
    type: String,
    enum: ['full', 'limited', 'emergency_only'],
    default: 'limited'
  },
  
  reasonForRelation: String,
  
  specialtyFocus: String,
  
  communicationPreferences: {
    allowDirectMessages: { type: Boolean, default: true },
    appointmentNotifications: { type: Boolean, default: true },
    healthAlertNotifications: { type: Boolean, default: true },
    summaryReports: { type: Boolean, default: false }
  },
  
  notes: String,
  
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  
  lastUpdatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

doctorPatientRelationSchema.index(
  { doctorId: 1, patientId: 1, status: 1 },
  { 
    unique: true,
    partialFilterExpression: { status: 'active' }
  }
);

doctorPatientRelationSchema.index({ doctorId: 1 });
doctorPatientRelationSchema.index({ patientId: 1 });
doctorPatientRelationSchema.index({ status: 1 });
doctorPatientRelationSchema.index({ relationType: 1 });

doctorPatientRelationSchema.virtual('doctor', {
  ref: 'Doctor',
  localField: 'doctorId',
  foreignField: '_id',
  justOne: true
});

doctorPatientRelationSchema.virtual('patient', {
  ref: 'Patient',
  localField: 'patientId',
  foreignField: '_id',
  justOne: true
});

doctorPatientRelationSchema.pre('save', function(next) {
  if (this.isModified('status') && this.status === 'terminated') {
    this.endDate = new Date();
  }
  next();
});

doctorPatientRelationSchema.statics.getDoctorPatients = function(doctorId, options = {}) {
  const query = { doctorId, status: 'active' };
  
  if (options.relationType) query.relationType = options.relationType;
  
  return this.find(query)
    .populate('patient', 'fullName dateOfBirth gender patientCode')
    .exec();
};

doctorPatientRelationSchema.statics.getPatientDoctors = function(patientId, options = {}) {
  const query = { patientId, status: 'active' };
  
  if (options.relationType) query.relationType = options.relationType;
  
  return this.find(query)
    .populate('doctor', 'fullName specialization hospitalAffiliation')
    .exec();
};

doctorPatientRelationSchema.methods.grantPermission = function(permission) {
  if (this.permissions[permission] !== undefined) {
    this.permissions[permission] = true;
  }
  return this.save();
};

doctorPatientRelationSchema.methods.revokePermission = function(permission) {
  if (this.permissions[permission] !== undefined) {
    this.permissions[permission] = false;
  }
  return this.save();
};

const DoctorPatientRelation = mongoose.model('DoctorPatientRelation', doctorPatientRelationSchema);

module.exports = DoctorPatientRelation;