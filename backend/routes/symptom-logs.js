const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const SymptomLog = require('../models/SymptomLog');
const authenticateToken = require('../middleware/auth');
const requireRole = require('../middleware/role');

router.post('/', authenticateToken, requireRole('patient'), [
  body('symptomType').notEmpty(),
  body('severity').isInt({ min: 1, max: 10 }),
  body('startTime').isISO8601(),
  body('location').optional()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const { symptomType, severity, startTime, endTime, location, triggers, reliefMethods, notes } = req.body;
    
    const symptomLog = new SymptomLog({
      patientId: req.user.userId,
      symptomType,
      severity: parseInt(severity),
      startTime: new Date(startTime),
      endTime: endTime ? new Date(endTime) : null,
      location,
      triggers: triggers || [],
      reliefMethods: reliefMethods || [],
      notes
    });
    
    await symptomLog.save();
    
    res.status(201).json({
      success: true,
      message: 'Symptom log created successfully',
      data: symptomLog
    });
  } catch (error) {
    console.error('Create symptom log error:', error);
    res.status(500).json({ success: false, error: 'Failed to create symptom log' });
  }
});

router.get('/', authenticateToken, requireRole('patient'), async (req, res) => {
  try {
    const { limit = 50, page = 1, symptomType, startDate, endDate } = req.query;
    const skip = (page - 1) * limit;
    
    let query = { patientId: req.user.userId };
    
    if (symptomType) query.symptomType = symptomType;
    
    if (startDate || endDate) {
      query.startTime = {};
      if (startDate) query.startTime.$gte = new Date(startDate);
      if (endDate) query.startTime.$lte = new Date(endDate);
    }
    
    const [logs, total] = await Promise.all([
      SymptomLog.find(query)
        .sort({ startTime: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .exec(),
      SymptomLog.countDocuments(query)
    ]);
    
    res.status(200).json({
      success: true,
      data: logs,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Fetch symptom logs error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch symptom logs' });
  }
});

module.exports = router;