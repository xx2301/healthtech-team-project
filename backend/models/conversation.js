const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  conversationType: {
    type: String,
    required: true,
    enum: ['patient_doctor', 'group', 'support']
  },
  
  title: {
    type: String,
    trim: true
  },
  
  createdDate: {
    type: Date,
    default: Date.now
  },
  
  lastMessageDate: {
    type: Date,
    default: Date.now
  },
  
  participantCount: {
    type: Number,
    default: 0,
    min: 2
  },
  
  isArchived: {
    type: Boolean,
    default: false
  },
  
  participants: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    role: { type: String, enum: ['doctor', 'patient', 'admin'] },
    joinedAt: { type: Date, default: Date.now },
    lastReadAt: Date
  }],
  
  metadata: {
    appointmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment' },
    patientCondition: String,
    urgencyLevel: { type: String, enum: ['low', 'medium', 'high', 'emergency'] }
  },
  
  settings: {
    allowAttachments: { type: Boolean, default: true },
    allowVoiceMessages: { type: Boolean, default: false },
    autoArchiveAfter: { type: Number, default: 30 } //days
  }
}, {
  timestamps: true
});

conversationSchema.index({ lastMessageDate: -1 });
conversationSchema.index({ 'participants.userId': 1 });
conversationSchema.index({ conversationType: 1, isArchived: 1 });

conversationSchema.pre('save', function(next) {
  if (this.participants && Array.isArray(this.participants)) {
    this.participantCount = this.participants.length;
  }
  next();
});

conversationSchema.methods.addParticipant = function(userId, role = 'patient') {
  if (!this.participants.some(p => p.userId.toString() === userId.toString())) {
    this.participants.push({
      userId,
      role,
      joinedAt: new Date()
    });
  }
  return this.save();
};

conversationSchema.methods.updateLastMessageTime = function() {
  this.lastMessageDate = new Date();
  return this.save();
};

const Conversation = mongoose.model('Conversation', conversationSchema);

module.exports = Conversation;
