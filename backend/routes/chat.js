const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Conversation = require('../models/conversation');
const ChatMessage = require('../models/ChatMessage');
const User = require('../models/User');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const authenticateToken = require('../middleware/auth');

function formatTime(date) {
  const d = new Date(date);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

router.get('/conversations', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    const conversations = await Conversation.find({
      participants: { $elemMatch: { userId } },
      isArchived: false
    }).populate('participants.userId', 'fullName email role');

    const sessions = [];

    for (const conv of conversations) {
      const other = conv.participants.find(
        p => p.userId?._id?.toString() !== userId
      );

      const name = other?.userId?.fullName || 'Unknown';
      const initials = name[0]?.toUpperCase() || '?';

      const lastMessageDoc = await ChatMessage.findOne({ conversationId: conv._id })
        .sort({ timestamp: -1 })
        .select('messageContent timestamp senderId');

      let lastMessage = '';
      let time = '';
      let lastMessageFromMe = false;

      if (lastMessageDoc) {
        lastMessage = lastMessageDoc.messageContent;
        time = formatTime(lastMessageDoc.timestamp);
        lastMessageFromMe = lastMessageDoc.senderId.toString() === userId;
      }

      const participant = conv.participants.find(
        p => p.userId?._id?.toString() === userId
      );

      const lastReadAt = participant?.lastReadAt || new Date(0);

      const unreadCount = await ChatMessage.countDocuments({
        conversationId: conv._id,
        senderId: { $ne: new mongoose.Types.ObjectId(userId) },
        timestamp: { $gt: lastReadAt }
      });

      sessions.push({
        id: conv._id,
        name,
        lastMessage,
        time,
        initials,
        lastMessageDate: conv.lastMessageDate,
        unreadCount,
        lastMessageFromMe,
      });
    }

    sessions.sort((a, b) => {
      const dateA = a.lastMessageDate ? new Date(a.lastMessageDate) : new Date(0);
      const dateB = b.lastMessageDate ? new Date(b.lastMessageDate) : new Date(0);
      return dateB - dateA;
    });

    sessions.unshift({
      id: 'assistant',
      name: 'Health Assistant',
      lastMessage: 'Ask me about your health',
      time: '',
      initials: 'HA',
      lastMessageDate: null,
      unreadCount: 0,
    });

    res.json({ success: true, data: sessions });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch conversations' });
  }
});

router.get('/conversations/:conversationId/messages', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.userId;

    if (conversationId === 'assistant') {
      return res.json({ success: true, data: [] });
    }

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({ success: false, error: 'Conversation not found' });
    }
    if (!conversation.participants.some(p => p.userId.toString() === userId)) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    const messages = await ChatMessage.find({ conversationId })
      .sort({ timestamp: 1 });
    
    const formatted = messages.map(msg => ({
      fromMe: msg.senderId.toString() === userId,
      text: msg.messageContent,
      time: formatTime(msg.timestamp),
      _id: msg._id,
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch messages' });
  }
});

router.post('/conversations/:conversationId/messages', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { text } = req.body;
    const userId = req.user.userId;

    if (!text) {
      return res.status(400).json({ success: false, error: 'Message text required' });
    }

    if (conversationId === 'assistant') {
      return res.json({ success: true, data: null });
    }

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({ success: false, error: 'Conversation not found' });
    }
    if (!conversation.participants.some(p => p.userId.toString() === userId)) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    const message = new ChatMessage({
      conversationId,
      senderId: userId,
      messageContent: text,
      timestamp: new Date(),
      messageType: 'text'
    });
    await message.save();

    conversation.lastMessageDate = new Date();
    await conversation.save();

    res.json({
      success: true,
      data: {
        fromMe: true,
        text: message.messageContent,
        time: formatTime(message.timestamp),
        _id: message._id
      }
    });
  } catch (err) {
    console.error('Error in send message route:', err.stack);
    res.status(500).json({ success: false, error: 'Failed to send message' });
  }
});

router.post('/conversations/:conversationId/read', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.userId;
    const now = new Date();

    const result = await Conversation.findOneAndUpdate(
      { _id: conversationId, 'participants.userId': userId },
      { $set: { 'participants.$.lastReadAt': now } },
      { new: true }
    );

    if (!result) {
      return res.status(404).json({
        success: false,
        error: 'Conversation or participant not found'
      });
    }

    res.json({ success: true, lastReadAt: now });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to mark as read' });
  }
});

router.post('/conversations/user/:targetUserId', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const targetUserId = req.params.targetUserId;

    if (userId === targetUserId) {
      return res.status(400).json({ success: false, error: 'Cannot chat with yourself' });
    }

    let conversation = await Conversation.findOne({
      participants: { $all: [
        { $elemMatch: { userId } },
        { $elemMatch: { userId: targetUserId } }
      ] }
    });

    if (conversation) {
      return res.json({ success: true, data: { id: conversation._id, name: 'Existing' } });
    }

    const currentUser = await User.findById(userId);
    const targetUser = await User.findById(targetUserId);
    if (!currentUser || !targetUser) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    let allowed = false;
    if (currentUser.role === 'doctor' && targetUser.role === 'patient') {
      const relation = await DoctorPatientRelation.findOne({ doctorId: currentUser.doctorProfileId, patientId: targetUser.patientProfileId });
      if (relation) allowed = true;
    } else if (currentUser.role === 'patient' && targetUser.role === 'doctor') {
      const relation = await DoctorPatientRelation.findOne({ doctorId: targetUser.doctorProfileId, patientId: currentUser.patientProfileId });
      if (relation) allowed = true;
    } else if (currentUser.role === 'admin' || targetUser.role === 'admin') {
      allowed = true;
    }

    if (!allowed) {
      return res.status(403).json({ success: false, error: 'You are not allowed to chat with this user' });
    }

    const userIdObj = new mongoose.Types.ObjectId(userId);
    const targetUserIdObj = new mongoose.Types.ObjectId(targetUserId);

    conversation = new Conversation({
      conversationType: 'patient_doctor',
      participants: [
        { userId: userIdObj, role: currentUser.role, lastReadAt: new Date() },
        { userId: targetUserIdObj, role: targetUser.role, lastReadAt: new Date() }
      ],
      createdDate: new Date(),
      lastMessageDate: new Date()
    });
    await conversation.save();

    res.json({ success: true, data: { id: conversation._id, name: targetUser.fullName } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to create conversation' });
  }
});

router.get('/users/search', authenticateToken, async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.length < 2) {
      return res.json({ success: true, data: [] });
    }
    const users = await User.find({
      $or: [
        { fullName: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } }
      ],
      _id: { $ne: req.user.userId }
    }).limit(10).select('fullName email role');
    res.json({ success: true, data: users });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Search failed' });
  }
});

module.exports = router;