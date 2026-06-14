const express = require('express');
const router = express.Router();
const Patient = require('../models/patient');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const EmergencyContact = require('../models/EmergencyContact');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const authenticateToken = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const mongoose = require('mongoose');

router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    if (!user.patientProfileId) {
      return res.status(400).json({ 
        success: false, 
        error: 'No patient profile found for this user' 
      });
    }
    
    const patient = await Patient.findById(user.patientProfileId);
    if (!patient) {
      return res.status(404).json({ success: false, error: 'Patient profile not found' });
    }

    const updates = req.body;
    Object.keys(updates).forEach(key => {
      if (['weight', 'height', 'bloodType', 'allergies', 'chronicConditions', 'emergencyContacts', 
           'careModeEnabled', 'preferredUnitSystem', 'primaryDoctor', 'smokingStatus', 
           'alcoholConsumption', 'exerciseFrequency', 'medicalHistorySummary', 
           'dataSharingConsent', 'shareWithDoctors'].includes(key)) {
        patient[key] = updates[key];
      }
    });

    await patient.save();

    const patientResponse = patient.toObject();

    res.json({
      success: true,
      message: 'Patient information updated successfully',
      patient: patientResponse
    });

  } catch (error) {
    console.error('Update patient information error:', error);
    res.status(500).json({ success: false, error: 'Failed to update patient information' });
  }
});

router.get('/profile', authenticateToken, requireRole('patient'), async (req, res) => {
  try {
    const patient = await Patient.findById(req.user._id)
      .populate('emergencyContacts')
      .populate('primaryDoctor', 'fullName specialization')
      .populate('shareWithDoctors.doctorId', 'fullName specialization');
    
    res.status(200).json({
      success: true,
      data: patient
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/my-doctors', authenticateToken, requireRole('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ userId: req.user.userId });
    if (!patient) {
      return res.status(404).json({ success: false, error: 'Patient not found' });
    }

    const relations = await DoctorPatientRelation.find({
      patientId: patient._id,
      status: 'active'
    }).populate({
      path: 'doctorId',
      populate: { path: 'userId', select: 'fullName' }
    });

    const doctors = relations.map(rel => ({
      id: rel.doctorId._id,
      name: rel.doctorId.userId?.fullName || 'Unknown',
    }));

    console.log('Fetching doctors for patient:', patient._id);
    console.log('Relations found:', relations);
    console.log('Doctors to return:', doctors);
    
    res.json({ success: true, data: doctors });
  } catch (err) {
    console.error('Error fetching patient doctors:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.delete('/:id', authenticateToken, requireRole('admin', 'super_admin'), async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const patientIdRaw = req.params.id;
    const patientId = patientIdRaw.trim();

    let objectId;
    try {
      objectId = new mongoose.Types.ObjectId(patientId);
    } catch (err) {
      await session.abortTransaction();
      return res.status(400).json({ message: 'Invalid patient ID format' });
    }

    let patient = await Patient.findById(objectId).session(session);

    if (!patient) {
      patient = await Patient.findOne({ _id: objectId, deletedAt: { $ne: null } }).session(session);
    }

    if (!patient) {
      await session.abortTransaction();
      return res.status(404).json({ message: 'Patient not found' });
    }

    if (patient.deletedAt) {
      await session.commitTransaction();
      return res.json({ message: 'Patient already deleted', patientId: patient._id });
    }

    patient.deletedAt = new Date();
    await patient.save({ session });

    await User.findByIdAndUpdate(patient.userId, { patientProfileId: null }, { session });

    await Doctor.updateMany(
      { assignedPatients: patientId },
      { $pull: { assignedPatients: patientId } },
      { session }
    );

    if (patient.emergencyContacts && patient.emergencyContacts.length > 0) {
      await EmergencyContact.updateMany(
        { _id: { $in: patient.emergencyContacts } },
        { deletedAt: new Date() },
        { session }
      );
    }

    await session.commitTransaction();
    res.json({ message: 'Patient deleted successfully', patientId: patient._id });
  } catch (err) {
    await session.abortTransaction();
    console.error('Delete patient error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  } finally {
    session.endSession();
  }
});

module.exports = router;