const express = require('express');
const router = express.Router();
const Device = require('../models/Device');
const User = require('../models/User');
const authenticateToken = require('../middleware/auth');

router.get('/', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    const devices = await Device.find({ userId: user._id }).sort({ createdAt: -1 });
    res.json({ success: true, data: devices });
  } catch (error) {
    console.error('Fetch devices error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch devices' });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    const { name, type, model, manufacturer, serialNumber } = req.body;
    if (!name || !type) {
      return res.status(400).json({ success: false, error: 'Name and type are required' });
    }

    const device = new Device({
      userId: user._id,
      name,
      type,
      model,
      manufacturer,
      serialNumber,
      isActive: true,
      status: 'online', // default online when added device
    });
    await device.save();
    res.status(201).json({ success: true, data: device });
  } catch (error) {
    console.error('Add device error:', error);
    res.status(500).json({ success: false, error: 'Failed to add device' });
  }
});

router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findById(req.params.id);
    if (!device) return res.status(404).json({ success: false, error: 'Device not found' });

    if (device.userId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    const { name, model, manufacturer, isActive, status } = req.body;
    if (name) device.name = name;
    if (model) device.model = model;
    if (manufacturer) device.manufacturer = manufacturer;
    if (isActive !== undefined) device.isActive = isActive;
    if (status) device.status = status;

    await device.save();
    res.json({ success: true, data: device });
  } catch (error) {
    console.error('Update device error:', error);
    res.status(500).json({ success: false, error: 'Failed to update device' });
  }
});

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findById(req.params.id);
    if (!device) return res.status(404).json({ success: false, error: 'Device not found' });

    if (device.userId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    await device.deleteOne();
    res.json({ success: true, message: 'Device deleted' });
  } catch (error) {
    console.error('Delete device error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete device' });
  }
});

module.exports = router;