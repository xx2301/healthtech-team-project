const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');
const HealthMetric = require('../models/HealthMetric');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const authenticateToken = require('../middleware/auth');

router.get('/health-metrics', authenticateToken, async (req, res) => {
  try {
    const { startDate, endDate, metricType, patientId: requestedPatientId, userId: requestedUserId, search, limit = 100, page = 1 } = req.query;
    let query = {};

    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    if (user.userType === 'admin' || user.role === 'admin' || user.role === 'super_admin') {
      if (requestedUserId) {
        query.userId = requestedUserId;
      } else if (requestedPatientId) {
        query.patientId = requestedPatientId;
      } else if (search) {
        const users = await User.find({
          $or: [
            { fullName: { $regex: search, $options: 'i' } },
            { email: { $regex: search, $options: 'i' } }
          ]
        }).select('_id');
        const userIds = users.map(u => u._id);
        query.userId = { $in: userIds };
      }
    }
    else if (user.role === 'patient' || user.role === 'user') {
      query.userId = user._id;
    }
    else if (user.userType === 'doctor' || user.role === 'doctor') {
      if (requestedUserId) {
        if (requestedUserId.toString() === req.user.userId.toString()) {
          query.userId = requestedUserId;
        } else {
          const patientUser = await User.findById(requestedUserId);
          if (!patientUser || patientUser.role !== 'patient') {
            return res.status(404).json({ success: false, error: 'Patient user not found' });
          }
          const patient = await Patient.findOne({ userId: patientUser._id });
          if (!patient) {
            return res.status(404).json({ success: false, error: 'Patient profile not found' });
          }
          const relation = await DoctorPatientRelation.findOne({
            doctorId: user.doctorProfileId,
            patientId: patient._id,
            status: 'active'
          });
          if (!relation) {
            return res.status(403).json({ success: false, error: 'You are not authorized to view this patient\'s data' });
          }
          query.userId = requestedUserId;
        }
      } else {
        const relations = await DoctorPatientRelation.find({ doctorId: user.doctorProfileId, status: 'active' }).select('patientId');
        const patientIds = relations.map(r => r.patientId);
        if (patientIds.length === 0) {
          return res.json({ success: true, data: [], pagination: { total: 0, page: parseInt(page), limit: parseInt(limit), pages: 0 } });
        }
        const patients = await Patient.find({ _id: { $in: patientIds } }).select('userId');
        const userIds = patients.map(p => p.userId);
        query.userId = { $in: userIds };
      }
    }
    else {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }
    if (metricType) query.metricType = metricType;

    const skip = (page - 1) * limit;
    const [metrics, total] = await Promise.all([
      HealthMetric.find(query).sort({ timestamp: -1 }).skip(skip).limit(parseInt(limit)),
      HealthMetric.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: metrics,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Fetch health metrics error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch health metrics' });
  }
});

router.post('/health-metrics', authenticateToken, [
  body('metricType').isIn([
    'steps', 'heart_rate', 'blood_pressure', 'glucose',
    'weight', 'height', 'bmi', 'body_temperature',
    'oxygen_saturation', 'sleep_duration', 'calories_burned',
    'water_intake', 'respiratory_rate'
  ]),
  body('value').notEmpty(),
  body('unit').optional(),
  body('timestamp').optional().isISO8601(),
  body('source').optional().isIn(['device', 'manual', 'calculated', 'imported'])
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const { metricType, value, unit, timestamp, source = 'manual', deviceId, notes } = req.body;
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    let patientId = null;

    if (req.user.userType === 'patient' || (user.patientProfileId && req.user.userType === 'user')) {
      patientId = user.patientProfileId || null;
    } else if (req.user.userType === 'doctor') {
      if (!req.body.patientId) {
        return res.status(400).json({ success: false, error: 'Patient ID is required for doctors' });
      }
      const relation = await DoctorPatientRelation.findOne({
        doctorId: req.user._id,
        patientId: req.body.patientId,
        status: 'active',
        'permissions.viewHealthMetrics': true
      });
      if (!relation) {
        return res.status(403).json({ success: false, error: 'No permission to add health metrics for this patient' });
      }
      patientId = req.body.patientId;
    }

    const healthMetric = new HealthMetric({
      patientId,
      userId: user._id,
      metricType,
      value,
      unit,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      source,
      deviceId,
      notes,
      qualityScore: 100,
      isAbnormal: false
    });

    await healthMetric.save();
    res.status(201).json({ success: true, message: 'Health metric recorded successfully', data: healthMetric });
  } catch (error) {
    console.error('Save health metric error:', error);
    res.status(500).json({ success: false, error: 'Failed to save health metric' });
  }
});

module.exports = router;