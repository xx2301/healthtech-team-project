const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Patient = require('../models/patient');
const Doctor = require('../models/doctor');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const HealthMetric = require('../models/HealthMetric');
const authenticateToken = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { body, validationResult } = require('express-validator');

router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    if (!user.doctorProfileId) {
      return res.status(400).json({ 
        success: false, 
        error: 'No doctor profile found for this user' 
      });
    }
    
    const doctor = await Doctor.findById(user.doctorProfileId);
    if (!doctor) {
      return res.status(404).json({ success: false, error: 'Doctor profile not found' });
    }

    const updates = req.body;
    const allowedUpdates = [
      'hospitalAffiliation', 'department', 'yearsOfExperience', 'consultationFee',
      'availabilitySchedule', 'status', 'maxPatients', 'qualifications',
      'bio', 'languagesSpoken'
    ];

    Object.keys(updates).forEach(key => {
      if (allowedUpdates.includes(key)) {
        doctor[key] = updates[key];
      }
      
      if (key === 'medicalLicenseNumber' && updates[key] !== doctor.medicalLicenseNumber) {
        return res.status(400).json({
          success: false,
          error: 'Medical license number cannot be changed directly. Please contact admin.'
        });
      }
      
      if (key === 'specialization' && updates[key] !== doctor.specialization) {
        return res.status(400).json({
          success: false,
          error: 'Specialization change requires admin approval.'
        });
      }
    });

    await doctor.save();

    const doctorResponse = doctor.toObject();

    res.json({
      success: true,
      message: 'Doctor profile updated successfully',
      doctor: doctorResponse
    });

  } catch (error) {
    console.error('Update doctor profile error:', error);
    res.status(500).json({ success: false, error: 'Failed to update doctor profile' });
  }
});

router.get('/patients', authenticateToken, async (req, res) => {
  try {
    const doctorUser = await User.findById(req.user.userId);
    if (!doctorUser || doctorUser.role !== 'doctor') {
      return res.status(403).json({ success: false, error: 'Access denied. Doctor only.' });
    }

    const doctorId = doctorUser.doctorProfileId;
    if (!doctorId) {
      return res.status(400).json({ success: false, error: 'Doctor profile not found' });
    }

    const relations = await DoctorPatientRelation.find({ 
      doctorId, 
      status: 'active' 
    });

    if (!relations.length) {
      return res.json({ success: true, data: [] });
    }

    const patientIds = relations.map(r => r.patientId);

    const patients = await Patient.find({ _id: { $in: patientIds } })
      .populate('userId', 'fullName email');

    const result = patients.map(p => ({
      _id: p.userId._id,
      fullName: p.userId.fullName,
      email: p.userId.email,
      patientCode: p.patientCode,
    }));

    res.json({ success: true, data: result });
  } catch (err) {
    console.error('Error fetching doctor patients:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch patients' });
  }
});

router.get('/patients/:patientId/summary', authenticateToken, async (req, res) => {
  // not implemented yet
  res.json({ success: true, message: 'Summary endpoint' });
});

router.get('/patient-metrics/:userId', authenticateToken, requireRole('doctor'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate, limit = 500 } = req.query;

    const doctorUser = await User.findById(req.user.userId);
    if (!doctorUser || !doctorUser.doctorProfileId) {
      return res.status(400).json({ success: false, error: 'Doctor profile not found' });
    }
    const doctorId = doctorUser.doctorProfileId;

    const patientUser = await User.findById(userId);
    if (!patientUser || patientUser.role !== 'patient') {
      return res.status(404).json({ success: false, error: 'Patient not found' });
    }
    const patient = await Patient.findOne({ userId: patientUser._id });
    if (!patient) {
      return res.status(404).json({ success: false, error: 'Patient profile not found' });
    }
    const relation = await DoctorPatientRelation.findOne({
      doctorId,
      patientId: patient._id,
      status: 'active'
    });
    if (!relation) {
      return res.status(403).json({ success: false, error: 'You are not authorized to view this patient\'s data' });
    }

    let query = { userId };
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const metrics = await HealthMetric.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json({ success: true, data: metrics });
  } catch (error) {
    console.error('Fetch patient metrics error details:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({ success: false, error: 'Failed to fetch patient health data', message: error.message });
  }
});

router.post('/create-patient', authenticateToken, requireRole('doctor'), [
  body('userId').isMongoId(),
  body('weight').optional().isFloat({ min: 0, max: 500 }),
  body('height').optional().isFloat({ min: 0, max: 300 }),
  body('bloodType').optional().isIn(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'unknown'])
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const doctor = await Doctor.findOne({ 
      userId: req.user.userId,
      approvalStatus: 'approved'
    });
    
    if (!doctor) {
      return res.status(403).json({ 
        success: false, 
        error: 'Only approved doctors can create patient profiles' 
      });
    }
    
    const user = await User.findById(req.body.userId);
    
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    if (user.patientProfileId) {
      return res.status(400).json({ 
        success: false, 
        error: 'User already has a patient profile' 
      });
    }
    
    const patientData = {
      userId: user._id,
      bloodType: req.body.bloodType || 'unknown',
      careModeEnabled: false,
      preferredUnitSystem: 'metric',
      age: user.age ? parseInt(user.age) : null,
    };
    if (req.body.weight !== undefined && req.body.weight !== null) {
      patientData.weight = req.body.weight;
    }
    if (req.body.height !== undefined && req.body.height !== null) {
      patientData.height = req.body.height;
    }
    
    const patient = new Patient(patientData);
    await patient.save();
    
    user.patientProfileId = patient._id;
    user.role = 'patient';
    await user.save();
    
    const relation = new DoctorPatientRelation({
      doctorId: doctor._id,
      patientId: patient._id,
      relationType: 'primary',
      status: 'active',
      permissions: {
        viewMedicalRecords: true,
        viewHealthMetrics: true,
        addMedicalNotes: true,
        writePrescriptions: true
      }
    });
    
    await relation.save();
    
    await Patient.findByIdAndUpdate(patient._id, { primaryDoctor: doctor._id });

    res.status(201).json({
      success: true,
      message: 'Patient profile created successfully',
      patient: patient,
      relation: relation
    });
    
  } catch (error) {
    console.error('Doctor create patient error:', error);
    res.status(500).json({ success: false, error: 'Failed to create patient profile' });
  }
});

router.post('/add-patient', authenticateToken, requireRole('doctor'), async (req, res) => {
  try {
    const { patientEmail } = req.body;
    if (!patientEmail) {
      return res.status(400).json({ success: false, error: 'Patient email is required' });
    }

    const doctorUser = await User.findById(req.user.userId);
    if (!doctorUser || !doctorUser.doctorProfileId) {
      return res.status(400).json({ success: false, error: 'Doctor profile not found' });
    }
    const doctorId = doctorUser.doctorProfileId;

    const patientUser = await User.findOne({ email: patientEmail, role: 'patient' });
    if (!patientUser) {
      return res.status(404).json({ success: false, error: 'Patient not found' });
    }

    const patient = await Patient.findOne({ userId: patientUser._id });
    if (!patient) {
      return res.status(404).json({ success: false, error: 'Patient profile not found' });
    }

    const existingRelation = await DoctorPatientRelation.findOne({
      doctorId,
      patientId: patient._id,
      status: 'active'
    });
    if (existingRelation) {
      return res.status(400).json({ success: false, error: 'Patient already in your list' });
    }

    const relation = new DoctorPatientRelation({
      doctorId,
      patientId: patient._id,
      relationType: 'primary',
      status: 'active',
      startDate: new Date(),
      permissions: {
        viewHealthMetrics: true,
        viewMedicalRecords: true,
        writePrescriptions: false,
        addMedicalNotes: false
      },
      accessLevel: 'full'
    });
    await relation.save();
    await Patient.findByIdAndUpdate(patient._id, { primaryDoctor: doctorId });

    res.json({ success: true, message: 'Patient added successfully' });
  } catch (error) {
    console.error('Add patient error:', error);
    res.status(500).json({ success: false, error: 'Failed to add patient' });
  }
});

router.get('/patient-doctors', authenticateToken, requireRole('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ userId: req.user.userId });
    if (!patient) return res.status(404).json({ success: false, error: 'Patient not found' });
    const relations = await DoctorPatientRelation.find({ patientId: patient._id, status: 'active' })
      .populate('doctorId');
    const doctors = relations.map(r => ({
      _id: r.doctorId._id,
      fullName: r.doctorId.userId?.fullName || 'Unknown',
    }));
    res.json({ success: true, data: doctors });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch doctors' });
  }
});

router.get('/patients-with-summary', authenticateToken, requireRole('doctor'), async (req, res) => {
  try {
    const doctorUser = await User.findById(req.user.userId).select('doctorProfileId');
    if (!doctorUser || !doctorUser.doctorProfileId) {
      return res.status(400).json({ success: false, error: 'Doctor profile not found' });
    }
    const doctorId = doctorUser.doctorProfileId;

    const relations = await DoctorPatientRelation.find({ 
      doctorId: doctorId,
      status: 'active'
    }).populate('patient');

    const patients = await Promise.all(relations.map(async (relation) => {
      const patient = relation.patient;
      const user = await User.findById(patient.userId).select('fullName email gender');
      
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const stepsMetrics = await HealthMetric.find({
        userId: patient.userId,
        metricType: 'steps',
        timestamp: { $gte: sevenDaysAgo }
      });
      const totalSteps = stepsMetrics.reduce((sum, m) => sum + (m.value || 0), 0);
      
      const latestHeartRate = await HealthMetric.findOne({
        userId: patient.userId,
        metricType: 'heart_rate'
      }).sort({ timestamp: -1 });
      
      const latestSleep = await HealthMetric.findOne({
        userId: patient.userId,
        metricType: 'sleep_duration'
      }).sort({ timestamp: -1 });

      return {
        _id: patient._id,
        patientCode: patient.patientCode,
        fullName: user?.fullName || 'Unknown',
        email: user?.email || '',
        gender: user?.gender || 'unknown',
        userId: patient.userId,
        relationType: relation.relationType,
        permissions: relation.permissions,
        healthSummary: {
          steps7Days: totalSteps,
          latestHeartRate: latestHeartRate ? latestHeartRate.value : null,
          latestSleep: latestSleep ? latestSleep.value : null,
        }
      };
    }));

    res.status(200).json({ success: true, data: patients, count: patients.length });
  } catch (error) {
    console.error('Fetch patients error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch patients list' });
  }
});

module.exports = router;