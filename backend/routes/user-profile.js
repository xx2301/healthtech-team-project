const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');
const HealthMetric = require('../models/HealthMetric');
const Device = require('../models/Device');
const Session = require('../models/Session');
const Notification = require('../models/Notification');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const HealthGoal = require('../models/HealthGoal');
const authenticateToken = require('../middleware/auth');

// user change password by themselves
router.put('/api/user/password', authenticateToken, [
  body('oldPassword').notEmpty(),
  body('newPassword').isLength({ min: 6 })
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const isMatch = await user.comparePassword(req.body.oldPassword);
    if (!isMatch) {
      return res.status(401).json({ success: false, error: 'Current password is incorrect' });
    }

    user.password = req.body.newPassword;
    await user.save();

    res.json({ success: true, message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ success: false, error: 'Failed to change password' });
  }
});

router.delete('/account', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    await HealthMetric.deleteMany({ userId });

    await Device.deleteMany({ userId });

    await Notification.deleteMany({ userId });

    await Session.deleteMany({ userId });

    const targetUser = await User.findById(userId);
    if (targetUser.patientProfileId) {
      await Patient.findByIdAndDelete(targetUser.patientProfileId);
    }
    if (targetUser.doctorProfileId) {
      await Doctor.findByIdAndDelete(targetUser.doctorProfileId);
    }

    await User.findByIdAndDelete(userId);

    res.json({ success: true, message: 'Account permanently deleted' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete account' });
  }
});

router.post('/apply-for-doctor', authenticateToken, [
  body('medicalLicenseNumber').notEmpty().trim(),
  body('specialization').notEmpty().isIn([
    'cardiology', 'dermatology', 'endocrinology', 'gastroenterology',
    'neurology', 'pediatrics', 'psychiatry', 'radiology',
    'surgery', 'general_practice', 'orthopedics', 'ophthalmology'
  ]),
  body('hospitalAffiliation').optional().trim(),
  body('department').optional().trim(),
  body('yearsOfExperience').optional().isInt({ min: 0 }),
  body('consultationFee').optional().isFloat({ min: 0 }),
  body('qualifications').optional().isArray(),
  body('bio').optional().trim(),
  body('languagesSpoken').optional().isArray()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const user = await User.findById(req.user.userId);
    
    if (user.doctorProfileId) {
      return res.status(400).json({
        success: false,
        error: 'You are already a doctor'
      });
    }

    let doctor = await Doctor.findOne({ userId: user._id });

    if (doctor) {
      if (doctor.approvalStatus === 'approved') {
        return res.status(400).json({
          success: false,
          error: 'You are already a doctor'
        });
      }
      if (doctor.approvalStatus === 'pending') {
        return res.status(400).json({
          success: false,
          error: 'You already have a pending doctor application'
        });
      }
      doctor.medicalLicenseNumber = req.body.medicalLicenseNumber;
      doctor.specialization = req.body.specialization;
      doctor.hospitalAffiliation = req.body.hospitalAffiliation;
      doctor.department = req.body.department;
      doctor.yearsOfExperience = req.body.yearsOfExperience;
      doctor.consultationFee = req.body.consultationFee;
      doctor.approvalStatus = 'pending';
      doctor.rejectionReason = null;
      await doctor.save();

      const admins = await User.find({ role: 'admin' }).select('_id');
      const notificationPromises = admins.map(admin => 
        Notification.create({
          userId: admin._id,
          type: 'doctor_application',
          title: 'Doctor Application Resubmitted',
          message: `${user.fullName || user.email} has resubmitted their doctor application.`,
          data: {
            doctorId: doctor._id,
            applicantId: user._id,
            applicantName: user.fullName || user.email,
          }
        })
      );
      await Promise.all(notificationPromises);

      return res.status(200).json({
        success: true,
        message: 'Application resubmitted successfully',
        data: doctor
      });
    }

    doctor = new Doctor({
      userId: user._id,
      medicalLicenseNumber: req.body.medicalLicenseNumber,
      specialization: req.body.specialization,
      hospitalAffiliation: req.body.hospitalAffiliation,
      department: req.body.department,
      yearsOfExperience: req.body.yearsOfExperience,
      consultationFee: req.body.consultationFee,
      approvalStatus: 'pending'
    });
    await doctor.save();

    const admins = await User.find({ role: 'admin' }).select('_id');
    const notificationPromises = admins.map(admin => 
      Notification.create({
        userId: admin._id,
        type: 'doctor_application',
        title: 'New Doctor Application',
        message: `${user.fullName || user.email} has applied to become a doctor.`,
        data: {
          doctorId: doctor._id,
          applicantId: user._id,
          applicantName: user.fullName || user.email,
        }
      })
    );
    await Promise.all(notificationPromises);

    res.status(201).json({
      success: true,
      message: 'Application submitted successfully',
      data: doctor
    });
  } catch (error) {
    console.error('Doctor application error:', error);
    res.status(500).json({ success: false, error: 'Failed to submit application' });
  }
});

router.get('/full-profile', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    let profileData = {
      user: user.toObject()
    };
    
    if (user.patientProfileId) {
      const patient = await Patient.findOne({ userId: user._id });
      profileData.patient = patient;
      
      const relations = await DoctorPatientRelation.find({ patientId: patient._id })
        .populate('doctorId', 'specialization hospitalAffiliation')
        .populate('doctorId.userId', 'fullName email phone');
      profileData.assignedDoctors = relations;
    }
    
    if (user.doctorProfileId) {
      const doctor = await Doctor.findOne({ userId: user._id });
      profileData.doctor = doctor;
      
      if (doctor && doctor.approvalStatus === 'approved') {
        const relations = await DoctorPatientRelation.find({ doctorId: doctor._id })
          .populate('patientId', 'patientCode bloodType')
          .populate('patientId.userId', 'fullName dateOfBirth gender');
        profileData.assignedPatients = relations;
      }
    }
    
    delete profileData.user.password;
    
    res.json({
      success: true,
      data: profileData
    });
    
  } catch (error) {
    console.error('Get full profile error:', error);
    res.status(500).json({ success: false, error: 'Failed to get profile' });
  }
});

router.put('/profile', authenticateToken, [
  body('fullName').optional().trim().escape(),
  body('dateOfBirth').optional().isISO8601(),
  body('gender').optional().isIn(['male', 'female', 'other', 'prefer_not_to_say']),
  body('phone').optional().trim(),
  body('age').optional().isInt({ min: 0, max: 150 }),
  body('height').optional().isFloat({ min: 0, max: 300 }),
  body('weight').optional().isFloat({ min: 0, max: 500 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    if (req.body.fullName) user.fullName = req.body.fullName;
    if (req.body.dateOfBirth) user.dateOfBirth = new Date(req.body.dateOfBirth);
    if (req.body.gender) user.gender = req.body.gender;
    if (req.body.phone !== undefined) user.phone = req.body.phone;
    
    if (req.body.age !== undefined) user.age = req.body.age.toString();
    if (req.body.height !== undefined) user.height = req.body.height.toString();
    if (req.body.weight !== undefined) user.weight = req.body.weight.toString();

    if (req.body.height !== undefined) user.heightUpdatedAt = new Date();
    if (req.body.weight !== undefined) user.weightUpdatedAt = new Date();

    if (req.body.avatarColor !== undefined) {
      user.avatarColor = req.body.avatarColor;
    }

    user.updatedAt = new Date();
    await user.save();

    const userResponse = user.toObject();
    delete userResponse.password;

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: userResponse
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ success: false, error: 'Failed to update profile' });
  }
});

router.get('/check-role', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    let hasPatientProfile = false;
    let hasDoctorProfile = false;
    let isApprovedDoctor = false;
    
    if (user.patientProfileId) {
      const patient = await Patient.findById(user.patientProfileId);
      hasPatientProfile = !!patient;
    }
    
    if (user.doctorProfileId) {
      const doctor = await Doctor.findById(user.doctorProfileId);
      hasDoctorProfile = !!doctor;
      isApprovedDoctor = doctor && doctor.approvalStatus === 'approved';
    }
    
    res.json({
      success: true,
      data: {
        userType: user.userType,
        hasPatientProfile,
        hasDoctorProfile,
        isApprovedDoctor,
        accountStatus: user.accountStatus
      }
    });
    
  } catch (error) {
    console.error('Check role error:', error);
    res.status(500).json({ success: false, error: 'Failed to check user role' });
  }
});

router.get('/basic-info', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId)
      .select('-password -__v');
    
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    res.json({
      success: true,
      data: user
    });
    
  } catch (error) {
    console.error('Get basic info error:', error);
    res.status(500).json({ success: false, error: 'Failed to get user info' });
  }
});

module.exports = router;