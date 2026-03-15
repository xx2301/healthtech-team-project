const express = require('express');
const router = express.Router();
const Session = require('../models/Session');
const authenticateToken = require('../middleware/auth');

router.get('/', authenticateToken, async (req, res) => {
  try {
    const sessions = await Session.find({ userId: req.user.userId }).sort({ lastActiveAt: -1 });
    const result = sessions.map(s => ({
      ...s.toObject(),
      isCurrent: s._id.toString() === req.user.sessionId
    }));
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('Fetch sessions error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch sessions' });
  }
});

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id);
    if (!session) return res.status(404).json({ success: false, error: 'Session not found' });
    if (session.userId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }
    if (session._id.toString() === req.user.sessionId) {
      return res.status(400).json({ success: false, error: 'Cannot terminate current session' });
    }
    await session.deleteOne();
    res.json({ success: true, message: 'Session terminated' });
  } catch (err) {
    console.error('Delete session error:', err);
    res.status(500).json({ success: false, error: 'Failed to terminate session' });
  }
});

module.exports = router;