const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const Appointment = require('../models/Appointment');
const authenticateToken = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { createNotification } = require('../utils/notifications');

router.post('/doctor-patient-relations', authenticateToken, requireRole('doctor'), [
  body('patientId').isMongoId(),
  body('relationType').isIn(['primary', 'specialist', 'consultant', 'temporary']),
  body('permissions').optional().isObject(),
  body('reasonForRelation').optional().notEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const {
      patientId,
      relationType,
      permissions = {
        viewMedicalRecords: true,
        viewHealthMetrics: true,
        addMedicalNotes: false,
        writePrescriptions: false
      },
      reasonForRelation,
      accessLevel = 'limited'
    } = req.body;
    
    const patient = await Patient.findById(patientId);
    if (!patient) {
      return res.status(404).json({
        success: false,
        error: 'Patient not found'
      });
    }
    
    const existingRelation = await DoctorPatientRelation.findOne({
      doctorId: req.user._id,
      patientId,
      status: 'active'
    });
    
    if (existingRelation) {
      return res.status(400).json({
        success: false,
        error: 'Active relation already exists with this patient'
      });
    }
    
    const relation = new DoctorPatientRelation({
      doctorId: req.user._id,
      patientId,
      relationType,
      permissions,
      reasonForRelation,
      accessLevel,
      status: 'pending', //need permission from patient
      createdBy: req.user._id,
      lastUpdatedBy: req.user._id
    });
    
    await relation.save();

    if (relationType === 'primary') {
      await Patient.findByIdAndUpdate(patientId, { primaryDoctor: req.user._id });
    }

    await createNotification(
      patient.userId,
      'relation_request',
        'New Doctor-Patient Relation Request',
        `Dr. ${req.user.fullName} has requested a ${relationType} relation with you. Reason: ${reasonForRelation || 'N/A'}`,
        { relationId: relation._id }
    );
    
    res.status(201).json({
      success: true,
      message: 'Doctor-patient relation request sent successfully',
      data: relation
    });
    
  } catch (error) {
    console.error('Create doctor-patient relation error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create doctor-patient relation'
    });
  }
});

// get all patients (for doctors and admins)
router.get('/patients/all', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const isDoctor = user.role === 'doctor' || (user.doctorProfileId && (await Doctor.findById(user.doctorProfileId))?.approvalStatus === 'approved');
    const isAdmin = user.userType === 'admin' || user.role === 'admin' || user.role === 'super_admin';

    if (!isDoctor && !isAdmin) {
      return res.status(403).json({ success: false, error: 'Forbidden: Only doctors and admins can access this resource' });
    }

    const patients = await Patient.find()
      .populate('userId', 'fullName email age height weight gender dateOfBirth')
      .populate({
        path: 'primaryDoctor',
        populate: { path: 'userId', select: 'fullName' }
      })
      .lean();

    const patientsWithLastAppt = await Promise.all(patients.map(async (patient) => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const lastAppointment = await Appointment.findOne({
        patientId: patient._id,
        date: { $lt: today },
        status: 'completed'
      }).sort({ date: -1 }).select('date');
      const lastAppointmentDate = lastAppointment ? lastAppointment.date : null;

      return {
        ...patient,
        lastAppointmentDate
      };
    }));

    res.json({ success: true, data: patientsWithLastAppt, count: patientsWithLastAppt.length });
  } catch (error) {
    console.error('Get patients list error:', error);
    res.status(500).json({ success: false, error: 'Failed to get patients list' });
  }
});

router.get('/patients/doctors', authenticateToken, requireRole('patient'), async (req, res) => {
  try {
    const relations = await DoctorPatientRelation.find({ 
      patientId: req.user.userId,
      status: 'active'
    }).populate('doctor', 'fullName specialization hospitalAffiliation rating');
    
    const doctors = relations.map(relation => ({
      ...relation.doctor.toObject(),
      relationType: relation.relationType,
      permissions: relation.permissions
    }));
    
    res.status(200).json({
      success: true,
      data: doctors,
      count: doctors.length
    });
  } catch (error) {
    console.error('Fetch doctors error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch doctors list' });
  }
});

module.exports = router;