const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const authenticateToken = require('../middleware/auth');

router.get('/unread-count', authenticateToken, async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      userId: req.user.userId,
      isRead: false
    });
    res.json({ success: true, data: { count } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to get count' });
  }
});

router.get('/', authenticateToken, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const notifications = await Notification.find({ userId: req.user.userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Notification.countDocuments({ userId: req.user.userId });

    res.json({
      success: true,
      data: notifications,
      pagination: { page, limit, total }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch notifications' });
  }
});

router.put('/:id/read', authenticateToken, async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.userId },
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({ success: false, error: 'Notification not found' });
    }
    res.json({ success: true, data: notification });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to mark as read' });
  }
});

router.put('/read-all', authenticateToken, async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user.userId, isRead: false },
      { isRead: true }
    );
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to mark all as read' });
  }
});

module.exports = router;