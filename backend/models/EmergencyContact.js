const mongoose = require('mongoose');

const emergencyContactSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  
  fullName: {
    type: String,
    required: true,
    trim: true
  },
  
  relationship: {
    type: String,
    required: true,
    enum: [
      'spouse', 'parent', 'child', 'sibling',
      'friend', 'relative', 'caregiver', 'other'
    ]
  },
  
  phoneNum: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return /^[\+]?[1-9][\d]{0,15}$/.test(v);
      },
      message: props => `${props.value} is not a valid phone number!`
    }
  },
  
  email: {
    type: String,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email']
  },
  
  address: {
    street: String,
    city: String,
    state: String,
    postalCode: String,
    country: String
  },
  
  isPrimary: {
    type: Boolean,
    default: false
  },
  
  notiEnabled: {
    type: Boolean,
    default: true
  },
  
  preferredContactMethod: {
    type: String,
    enum: ['phone', 'sms', 'email', 'whatsapp'],
    default: 'phone'
  },
  
  canViewMedicalInfo: {
    type: Boolean,
    default: false
  },
  
  canMakeDecisions: {
    type: Boolean,
    default: false
  },
  
  addedDate: {
    type: Date,
    default: Date.now
  },
  
  lastContacted: Date,
  
  notes: String
}, {
  timestamps: true
});

emergencyContactSchema.index({ patientId: 1 });
emergencyContactSchema.index({ isPrimary: 1 });
emergencyContactSchema.index({ phoneNum: 1 });

emergencyContactSchema.pre('save', async function(next) {
  if (this.isPrimary && this.isModified('isPrimary')) {
    await this.constructor.updateMany(
      { 
        patientId: this.patientId, 
        _id: { $ne: this._id } 
      },
      { $set: { isPrimary: false } }
    );
  }
  next();
});

emergencyContactSchema.statics.getPrimaryContact = function(patientId) {
  return this.findOne({ patientId, isPrimary: true });
};

emergencyContactSchema.methods.getContactInfo = function() {
  return {
    name: this.fullName,
    relationship: this.relationship,
    phone: this.phoneNum,
    email: this.email,
    isPrimary: this.isPrimary
  };
};

const EmergencyContact = mongoose.model('EmergencyContact', emergencyContactSchema);

module.exports = EmergencyContact;