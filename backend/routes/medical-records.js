const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');
const MedicalRecord = require('../models/MedicalRecord');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const authenticateToken = require('../middleware/auth');
const { createActivityLog } = require('../utils/activity-logs'); // 直接使用 Phase 1 的版本

router.post('/', authenticateToken, [
  body('patientId').isMongoId(),
  body('visitType').isIn([
    'consultation', 'follow_up', 'emergency',
    'routine_checkup', 'vaccination', 'lab_test'
  ]),
  body('diagnosis.primary').optional().notEmpty(),
  body('prescriptions.*.medication').optional().notEmpty(),
  body('followUpDate').optional().isISO8601()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  if (req.user.userType !== 'doctor') {
    return res.status(403).json({ success: false, error: 'Only doctors can create medical records' });
  }

  try {
    const {
      patientId,
      visitType,
      symptoms,
      diagnosis,
      prescriptions,
      labResults,
      treatmentPlan,
      followUpDate,
      notes
    } = req.body;

    const relation = await DoctorPatientRelation.findOne({
      doctorId: req.user._id,
      patientId,
      status: 'active',
      'permissions.addMedicalNotes': true
    });

    if (!relation) {
      return res.status(403).json({
        success: false,
        error: 'No permission to create medical records for this patient'
      });
    }

    const medicalRecord = new MedicalRecord({
      patientId,
      doctorId: req.user._id,
      visitDate: new Date(),
      visitType,
      symptoms: symptoms || [],
      diagnosis: diagnosis || { primary: '', notes: '' },
      prescriptions: prescriptions || [],
      labResults: labResults || [],
      treatmentPlan: treatmentPlan || { description: '' },
      followUpDate: followUpDate ? new Date(followUpDate) : null,
      notes,
      recordStatus: 'draft',
      createdBy: req.user._id,
      lastUpdatedBy: req.user._id
    });

    await medicalRecord.save();

    // 调用正确的 createActivityLog（接收一个对象参数）
    await createActivityLog({
      userId: req.user._id,
      action: 'create_medical_record',
      details: { recordId: medicalRecord._id, visitType, patientId }
    });

    res.status(201).json({
      success: true,
      message: 'Medical record created successfully',
      data: medicalRecord
    });

  } catch (error) {
    console.error('Create medical record error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create medical record'
    });
  }
});

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { startDate, endDate, visitType, search, page = 1, limit = 20 } = req.query;
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    let query = {};
    const skip = (page - 1) * limit;

    if (user.userType === 'doctor' || user.role === 'doctor') {
      const relations = await DoctorPatientRelation.find({
        doctorId: user._id,
        status: 'active'
      }).select('patientId');
      const patientIds = relations.map(r => r.patientId);
      if (patientIds.length === 0) {
        return res.json({
          success: true,
          data: [],
          pagination: { total: 0, page: parseInt(page), limit: parseInt(limit), pages: 0 }
        });
      }
      query.patientId = { $in: patientIds };
    } else if (user.userType === 'admin' || user.role === 'super_admin') {
      if (search) {
        const users = await User.find({
          fullName: { $regex: search, $options: 'i' }
        }).select('_id');
        const userIds = users.map(u => u._id);
        const patients = await Patient.find({ userId: { $in: userIds } }).select('_id');
        const patientIds = patients.map(p => p._id);
        if (patientIds.length === 0) {
          return res.json({
            success: true,
            data: [],
            pagination: { total: 0, page: parseInt(page), limit: parseInt(limit), pages: 0 }
          });
        }
        query.patientId = { $in: patientIds };
      }
    } else {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    if (startDate || endDate) {
      query.visitDate = {};
      if (startDate) query.visitDate.$gte = new Date(startDate);
      if (endDate) query.visitDate.$lte = new Date(endDate);
    }
    if (visitType) query.visitType = visitType;

    const [records, total] = await Promise.all([
      MedicalRecord.find(query)
        .populate('patientId', 'userId')
        .populate('doctorId', 'specialization userId')
        .sort({ visitDate: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .exec(),
      MedicalRecord.countDocuments(query)
    ]);

    const enhancedRecords = await Promise.all(records.map(async record => {
      const recordObj = record.toObject();
      if (record.patientId && record.patientId.userId) {
        const patientUser = await User.findById(record.patientId.userId).select('fullName');
        recordObj.patientName = patientUser ? patientUser.fullName : 'Unknown';
      } else {
        recordObj.patientName = 'Unknown';
      }
      if (record.doctorId && record.doctorId.userId) {
        const doctorUser = await User.findById(record.doctorId.userId).select('fullName');
        recordObj.doctorName = doctorUser ? doctorUser.fullName : 'Unknown';
        recordObj.doctorSpecialization = record.doctorId.specialization;
      } else {
        recordObj.doctorName = 'Unknown';
      }
      return recordObj;
    }));

    res.json({
      success: true,
      data: enhancedRecords,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Fetch medical records error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch medical records' });
  }
});

router.get('/patients/:patientId/medical-records', authenticateToken, async (req, res) => {
  try {
    const { patientId } = req.params;
    const {
      startDate,
      endDate,
      visitType,
      limit = 20,
      page = 1
    } = req.query;

    let hasPermission = false;

    if (req.user.userType === 'patient' && req.user.userId.toString() === patientId) {
      hasPermission = true;
    } else if (req.user.userType === 'doctor') {
      const relation = await DoctorPatientRelation.findOne({
        doctorId: req.user._id,
        patientId,
        status: 'active',
        'permissions.viewMedicalRecords': true
      });
      hasPermission = !!relation;
    }

    if (!hasPermission) {
      return res.status(403).json({
        success: false,
        error: 'No permission to view medical records'
      });
    }

    let query = { patientId };

    if (startDate || endDate) {
      query.visitDate = {};
      if (startDate) query.visitDate.$gte = new Date(startDate);
      if (endDate) query.visitDate.$lte = new Date(endDate);
    }

    if (visitType) {
      query.visitType = visitType;
    }

    const skip = (page - 1) * limit;

    const [records, total] = await Promise.all([
      MedicalRecord.find(query)
        .sort({ visitDate: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .populate('doctorId', 'specialization')
        .populate({
          path: 'doctorId',
          populate: { path: 'userId', select: 'fullName' }
        })
        .populate('patientId', 'userId')
        .populate({
          path: 'patientId',
          populate: { path: 'userId', select: 'fullName' }
        })
        .exec(),
      MedicalRecord.countDocuments(query)
    ]);

    const formatted = records.map(record => {
      const obj = record.toObject();
      obj.doctorName = obj.doctorId?.userId?.fullName || 'Unknown';
      obj.patientName = obj.patientId?.userId?.fullName || 'Unknown';
      return obj;
    });

    res.status(200).json({
      success: true,
      data: formatted,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Fetch medical records error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch medical records'
    });
  }
});

module.exports = router;