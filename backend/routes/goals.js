const express = require('express');
const router = express.Router();
const HealthGoal = require('../models/HealthGoal');
const authenticateToken = require('../middleware/auth');

router.get('/', authenticateToken, async (req, res) => {
  try {
    const goals = await HealthGoal.find({ userId: req.user.userId }).sort({ createdAt: -1 });
    res.json({ success: true, data: goals });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch goals' });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  try {
    const { goalType, title, description, targetValue, targetDate, frequency, priority, notes, category } = req.body;
    
    if (!goalType || !title || !targetValue || !targetDate) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const goal = new HealthGoal({
      userId: req.user.userId,
      goalType,
      title,
      description,
      targetValue,
      targetDate: new Date(targetDate),
      frequency: frequency || 'daily',
      priority: priority || 'medium',
      notes,
      category
    });

    await goal.save();
    res.status(201).json({ success: true, data: goal });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to create goal' });
  }
});

router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const goal = await HealthGoal.findOne({ _id: req.params.id, userId: req.user.userId });
    if (!goal) {
      return res.status(404).json({ success: false, error: 'Goal not found' });
    }

    const { title, description, targetValue, targetDate, frequency, priority, currentValue, isActive, notes, category } = req.body;

    if (title !== undefined) goal.title = title;
    if (description !== undefined) goal.description = description;
    if (targetValue !== undefined) goal.targetValue = targetValue;
    if (targetDate !== undefined) goal.targetDate = new Date(targetDate);
    if (frequency !== undefined) goal.frequency = frequency;
    if (priority !== undefined) goal.priority = priority;
    if (isActive !== undefined) goal.isActive = isActive;
    if (notes !== undefined) goal.notes = notes;
    if (category !== undefined) goal.category = category;

    if (currentValue !== undefined) {
      goal.currentValue = currentValue;
      goal.progressPercentage = (currentValue / goal.targetValue) * 100;
      if (goal.progressPercentage > 100) goal.progressPercentage = 100;
    }

    goal.lastUpdated = new Date();
    await goal.save();

    res.json({ success: true, data: goal });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to update goal' });
  }
});

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const goal = await HealthGoal.findOneAndDelete({ _id: req.params.id, userId: req.user.userId });
    if (!goal) {
      return res.status(404).json({ success: false, error: 'Goal not found' });
    }
    res.json({ success: true, message: 'Goal deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to delete goal' });
  }
});

module.exports = router;