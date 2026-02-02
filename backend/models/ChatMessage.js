const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true
  },
  
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  messageContent: {
    type: String,
    required: true,
    trim: true
  },
  
  timestamp: {
    type: Date,
    default: Date.now
  },
  
  messageType: {
    type: String,
    enum: ['text', 'image', 'file', 'voice', 'prescription', 'appointment'],
    default: 'text'
  },
  
  isRead: {
    type: Boolean,
    default: false
  },
  
  readTimestamp: Date,
  
  isEdited: {
    type: Boolean,
    default: false
  },
  
  editTimestamp: Date,
  
  attachment: {
    fileName: String,
    fileType: String,
    fileUrl: String,
    fileSize: Number,
    thumbnailUrl: String
  },
  
  metadata: {
    prescriptionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Prescription' },
    appointmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment' },
    labResultId: { type: mongoose.Schema.Types.ObjectId, ref: 'LabResult' }
  },
  
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read', 'failed'],
    default: 'sent'
  },
  
  replyTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ChatMessage'
  },
  
  //like emojies
  reactions: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    emoji: String,
    timestamp: { type: Date, default: Date.now }
  }],
  
  deleted: {
    type: Boolean,
    default: false
  },
  
  deletedAt: Date,
  
  deletedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

chatMessageSchema.index({ conversationId: 1, timestamp: -1 });
chatMessageSchema.index({ senderId: 1 });
chatMessageSchema.index({ timestamp: 1 });

chatMessageSchema.post('save', async function() {
  const Conversation = require('models\conversation.js');
  await Conversation.findByIdAndUpdate(
    this.conversationId,
    { lastMessageDate: this.timestamp }
  );
});

chatMessageSchema.methods.markAsRead = function(userId) {
  if (!this.isRead) {
    this.isRead = true;
    this.readTimestamp = new Date();
  }
  
  //if other participants in the conversation are reading, logic can be added here.
  
  return this.save();
};

chatMessageSchema.methods.addReaction = function(userId, emoji) {
  this.reactions = this.reactions.filter(r => r.userId.toString() !== userId.toString());
  
  this.reactions.push({
    userId,
    emoji,
    timestamp: new Date()
  });
  
  return this.save();
};

const ChatMessage = mongoose.model('ChatMessage', chatMessageSchema);

module.exports = ChatMessage;
