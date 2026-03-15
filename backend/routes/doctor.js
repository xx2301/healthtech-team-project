const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Patient = require('../models/patient');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const authenticateToken = require('../middleware/auth');
const { requireRole } = require('../middleware/role');

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

    res.json({ success: true, message: 'Patient added successfully' });
  } catch (error) {
    console.error('Add patient error:', error);
    res.status(500).json({ success: false, error: 'Failed to add patient' });
  }
});

module.exports = router;