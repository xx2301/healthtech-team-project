const express = require('express');
const router = express.Router();
const Threshold = require('../models/Threshold');
const authenticateToken = require('../middleware/auth');

router.get('/', authenticateToken, async (req, res) => {
  try {
    const thresholds = await Threshold.find({ userId: req.user.userId });
    res.json({ success: true, data: thresholds });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch thresholds' });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  try {
    const { metricType, minThreshold, maxThreshold, enabled } = req.body;
    if (!metricType) {
      return res.status(400).json({ success: false, error: 'metricType is required' });
    }

    const threshold = await Threshold.findOneAndUpdate(
      { userId: req.user.userId, metricType },
      {
        userId: req.user.userId,
        metricType,
        minThreshold: minThreshold || null,
        maxThreshold: maxThreshold || null,
        enabled: enabled !== undefined ? enabled : true,
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );

    res.json({ success: true, data: threshold });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to save threshold' });
  }
});

router.delete('/:metricType', authenticateToken, async (req, res) => {
  try {
    await Threshold.findOneAndDelete({
      userId: req.user.userId,
      metricType: req.params.metricType
    });
    res.json({ success: true, message: 'Threshold deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to delete threshold' });
  }
});

module.exports = router;