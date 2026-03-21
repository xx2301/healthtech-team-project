const express = require('express');
const router = express.Router();
const mongoose = require('mongoose'); // 添加这一行
const Conversation = require('../models/conversation');
const ChatMessage = require('../models/ChatMessage');
const User = require('../models/User');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const authenticateToken = require('../middleware/auth');

// 辅助函数：格式化时间显示
function formatTime(date) {
  const d = new Date(date);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

// 获取当前用户的所有会话列表（包括助手会话）
router.get('/conversations', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    // 获取所有普通会话（Conversation）
    const conversations = await Conversation.find({
      participants: { $elemMatch: { userId } },
      isArchived: false
    }).populate('participants.userId', 'fullName email role');

    const sessions = [];

    for (const conv of conversations) {
      // 找到对方用户
      const other = conv.participants.find(p => p.userId._id.toString() !== userId);
      const name = other?.userId.fullName || 'Unknown';
      const initials = name[0]?.toUpperCase() || '?';

      // 查询该会话的最后一条消息（按时间降序取第一条）
      const lastMessageDoc = await ChatMessage.findOne({ conversationId: conv._id })
        .sort({ timestamp: -1 })
        .select('messageContent timestamp');

      let lastMessage = '';
      let time = '';
      if (lastMessageDoc) {
        lastMessage = lastMessageDoc.messageContent;
        time = formatTime(lastMessageDoc.timestamp);
      }

      sessions.push({
        id: conv._id,
        name: name,
        lastMessage: lastMessage,
        time: time,
        initials: initials,
      });
    }

    // 固定助手会话
    sessions.unshift({
      id: 'assistant',
      name: 'Health Assistant',
      lastMessage: 'Ask me about your health',
      time: '',
      initials: 'HA',
    });

    res.json({ success: true, data: sessions });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch conversations' });
  }
});

// 获取某个会话的消息列表
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
        { userId: userIdObj, role: currentUser.role },
        { userId: targetUserIdObj, role: targetUser.role }
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