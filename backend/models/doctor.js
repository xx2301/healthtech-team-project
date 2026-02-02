const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },

  approvalStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },

  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },

  approvalDate: Date,

  rejectionReason: String,

  medicalLicenseNumber: {
    type: String,
    required: [true, 'Medical license number is required'],
    unique: true,
    uppercase: true,
    trim: true
  },
  
  specialization: {
    type: String,
    required: [true, 'Specialization is required'],
    enum: [
      'cardiology', 'dermatology', 'endocrinology', 'gastroenterology',
      'neurology', 'pediatrics', 'psychiatry', 'radiology',
      'surgery', 'general_practice', 'orthopedics', 'ophthalmology'
    ]
  },
  
  doctorCode: {
    type: String,
    unique: true,
    default: function() {
      const randomNum = Math.floor(Math.random() * 9000) + 1000;
      return `DOC${Date.now().toString().slice(-6)}${randomNum}`;
    }
  },
  
  hospitalAffiliation: String,
  department: String,
  yearsOfExperience: Number,
  
  consultationFee: {
    type: Number,
    min: 0,
    default: 0
  },
  
  availabilitySchedule: {
    type: Map,
    of: {
      available: { type: Boolean, default: false },
      slots: [{
        startTime: String,
        endTime: String,
        appointmentType: String,
        maxPatients: { type: Number, default: 1 }
      }]
    },
    default: () => ({
      monday: { available: false, slots: [] },
      tuesday: { available: false, slots: [] },
      wednesday: { available: false, slots: [] },
      thursday: { available: false, slots: [] },
      friday: { available: false, slots: [] },
      saturday: { available: false, slots: [] },
      sunday: { available: false, slots: [] }
    })
  },
  
  status: {
    type: String,
    enum: ['active', 'on_leave', 'inactive'],
    default: 'active'
  },
  
  rating: {
    type: Number,
    min: 0,
    max: 5,
    default: 0
  },
  
  totalReviews: {
    type: Number,
    default: 0
  },
  
  maxPatients: {
    type: Number,
    default: 50
  },
  
  qualifications: [{
    degree: String,
    institution: String,
    year: Number,
    certificateUrl: String
  }],
  
  bio: String,
  languagesSpoken: [String],
  
  assignedPatients: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient'
  }]
}, {
  timestamps: true
});

doctorSchema.index({ userId: 1 }, { unique: true });
doctorSchema.index({ medicalLicenseNumber: 1 }, { unique: true });
doctorSchema.index({ specialization: 1 });
doctorSchema.index({ hospitalAffiliation: 1 });

doctorSchema.virtual('availableDays').get(function() {
  return Object.entries(this.availabilitySchedule)
    .filter(([day, data]) => data.available)
    .map(([day]) => day);
});

doctorSchema.virtual('averageRating').get(function() {
  return this.totalReviews > 0 ? (this.rating / this.totalReviews).toFixed(1) : 0;
});

const Doctor = mongoose.model('Doctor', doctorSchema);

module.exports = Doctor;