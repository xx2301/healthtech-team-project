const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');
const Session = require('../models/Session');
const Notification = require('../models/Notification');
const authenticateToken = require('../middleware/auth');
const admin = require('../middleware/admin');
const { requireRole } = require('../middleware/role');
const { createNotification } = require('../utils/notifications');

router.post('/login', [
  body('email').isEmail(),
  body('password').notEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid credentials' 
      });
    }

    const isValidPassword = await user.comparePassword(password);
    if (!isValidPassword) {
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid credentials' 
      });
    }

    if (user.userType !== 'admin' && user.role === 'user') {
      return res.status(403).json({ 
        success: false, 
        error: 'Admin access required' 
      });
    }

    user.lastLogin = new Date();
    await user.save();

    const userAgent = req.headers['user-agent'] || 'Unknown';
    const ip = req.ip || req.connection.remoteAddress;

    let deviceType = 'unknown';
    if (userAgent.includes('Mobile')) deviceType = 'mobile';
    else if (userAgent.includes('Tablet')) deviceType = 'tablet';
    else deviceType = 'desktop';

    const sessionCount = await Session.countDocuments({ userId: user._id });
    if (sessionCount >= 3) {
      const oldest = await Session.findOne({ userId: user._id }).sort('createdAt');
      if (oldest) await oldest.deleteOne();
    }

    const session = new Session({
      userId: user._id,
      deviceName: userAgent,
      deviceType,
      ipAddress: ip,
      userAgent,
      lastActiveAt: new Date()
    });
    await session.save();

    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email,
        userType: user.userType,
        role: user.role,
        permissions: user.permissions,
        sessionId: session._id,
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(200).json({
      success: true,
      message: 'Admin login successful',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Login failed' 
    });
  }
});

// admin add patient
router.post('/create-patient', authenticateToken, requireRole('admin'), [
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
      age: req.body.age !== undefined ? req.body.age : null,
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
    
    res.status(201).json({
      success: true,
      message: 'Patient profile created successfully',
      patient: patient
    });
    
  } catch (error) {
    console.error('Create patient error:', error);
    res.status(500).json({ success: false, error: 'Failed to create patient profile' });
  }
});

router.get('/pending-doctor-applications', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const applications = await Doctor.find({ approvalStatus: 'pending' })
      .populate('userId', 'email fullName dateOfBirth gender phone createdAt')
      .sort({ createdAt: 1 });
    
    res.json({
      success: true,
      data: applications,
      count: applications.length
    });
    
  } catch (error) {
    console.error('Get pending doctor applications error:', error);
    res.status(500).json({ success: false, error: 'Failed to get applications' });
  }
});

router.get('/doctor-applications', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;
    
    let query = {};
    if (status) {
      query.approvalStatus = status;
    } else {
      query.approvalStatus = 'pending';
    }
    
    const [applications, total] = await Promise.all([
      Doctor.find(query)
        .populate('userId', 'email fullName dateOfBirth gender phone createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .exec(),
      Doctor.countDocuments(query)
    ]);
    
    res.json({
      success: true,
      data: applications,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
    
  } catch (error) {
    console.error('Get doctor applications error:', error);
    res.status(500).json({ success: false, error: 'Failed to get applications' });
  }
});

router.get('/doctor-applications/:applicationId', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const application = await Doctor.findById(req.params.applicationId)
      .populate('userId', 'email fullName dateOfBirth gender phone createdAt')
      .populate('approvedBy', 'fullName email');
    
    if (!application) {
      return res.status(404).json({ success: false, error: 'Application not found' });
    }
    
    res.json({
      success: true,
      data: application
    });
    
  } catch (error) {
    console.error('Get application detail error:', error);
    res.status(500).json({ success: false, error: 'Failed to get application detail' });
  }
});

router.post('/doctor-applications/bulk-action', authenticateToken, requireRole('admin'), [
  body('applicationIds').isArray(),
  body('action').isIn(['approve', 'reject']),
  body('rejectionReason').optional().trim()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const { applicationIds, action, rejectionReason } = req.body;
    
    const updateData = {
      approvalStatus: action === 'approve' ? 'approved' : 'rejected',
      approvedBy: req.user.userId,
      approvedAt: new Date()
    };
    
    if (action === 'reject' && rejectionReason) {
      updateData.rejectionReason = rejectionReason;
    }
    
    const result = await Doctor.updateMany(
      { _id: { $in: applicationIds }, approvalStatus: 'pending' },
      updateData
    );
    
    if (action === 'approve') {
      const approvedDoctors = await Doctor.find({ 
        _id: { $in: applicationIds }, 
        approvalStatus: 'approved' 
      });
      
      for (const doctor of approvedDoctors) {
        await User.findByIdAndUpdate(doctor.userId, {
          doctorProfileId: doctor._id,
          accountStatus: 'active'
        });
      }
    }
    
    res.json({
      success: true,
      message: `Successfully ${action}d ${result.modifiedCount} applications`,
      modifiedCount: result.modifiedCount
    });
    
  } catch (error) {
    console.error('Bulk action error:', error);
    res.status(500).json({ success: false, error: 'Failed to process bulk action' });
  }
});

router.post('/approve-doctor/:doctorId', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const doctor = await Doctor.findById(req.params.doctorId);
    
    if (!doctor) {
      return res.status(404).json({ success: false, error: 'Doctor application not found' });
    }
    
    if (doctor.approvalStatus !== 'pending') {
      return res.status(400).json({ 
        success: false, 
        error: `Application is already ${doctor.approvalStatus}` 
      });
    }
    
    doctor.approvalStatus = 'approved';
    doctor.approvedBy = req.user.userId;
    doctor.approvalDate = new Date();
    
    await doctor.save();
    
    await User.findByIdAndUpdate(doctor.userId, {
      accountStatus: 'active',
      doctorProfileId: doctor._id,
      role: 'doctor'
    });

    await Notification.create({
      userId: doctor.userId,
      type: 'system',
      title: 'Doctor Application Approved',
      message: 'Your application to become a doctor has been approved. You can now access doctor features.',
      data: { doctorId: doctor._id }
    });
    
    res.json({
      success: true,
      message: 'Doctor application approved successfully',
      doctor: doctor
    });
    
  } catch (error) {
    console.error('Approve doctor error:', error);
    res.status(500).json({ success: false, error: 'Failed to approve doctor application' });
  }
});

router.post('/reject-doctor/:doctorId', authenticateToken, requireRole('admin'), [
  body('rejectionReason').optional().trim()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const doctor = await Doctor.findById(req.params.doctorId);
    
    if (!doctor) {
      return res.status(404).json({ success: false, error: 'Doctor application not found' });
    }
    
    if (doctor.approvalStatus !== 'pending') {
      return res.status(400).json({ 
        success: false, 
        error: `Application is already ${doctor.approvalStatus}` 
      });
    }
    
    doctor.approvalStatus = 'rejected';
    doctor.rejectionReason = req.body.rejectionReason;
    doctor.rejectedBy = req.user.userId;
    doctor.rejectedAt = new Date();
    
    await doctor.save();
    
    await User.findByIdAndUpdate(doctor.userId, {
      accountStatus: 'active'
    });

    const reasonMessage = req.body.rejectionReason 
        ? ` Reason: ${req.body.rejectionReason}` 
        : '';
    await Notification.create({
      userId: doctor.userId,
      type: 'system',
      title: 'Doctor Application Rejected',
      message: `Your application to become a doctor has been rejected.${reasonMessage}`,
      data: { doctorId: doctor._id, rejectionReason: req.body.rejectionReason }
    });
    
    res.json({
      success: true,
      message: 'Doctor application rejected',
      doctor: doctor
    });
    
  } catch (error) {
    console.error('Reject doctor error:', error);
    res.status(500).json({ success: false, error: 'Failed to reject doctor application' });
  }
});

router.get('/users', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { 
      search, 
      userType, 
      accountStatus,
      page = 1, 
      limit = 20 
    } = req.query;
    const skip = (page - 1) * limit;
    
    let query = {};
    
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (userType) {
      query.userType = userType;
    }
    
    if (accountStatus) {
      query.accountStatus = accountStatus;
    }
    
    const [users, total] = await Promise.all([
      User.find(query)
        .select('-password -__v')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .exec(),
      User.countDocuments(query)
    ]);
    
    const usersWithDetails = await Promise.all(users.map(async (user) => {
      const userObj = user.toObject();
      
      if (user.patientProfileId) {
        const patient = await Patient.findById(user.patientProfileId)
          .select('patientCode bloodType')
          .populate({
            path: 'primaryDoctor',
            populate: { path: 'userId', select: 'fullName' }
          });
        userObj.patientDetails = patient;
      }
      
      if (user.doctorProfileId) {
        const doctor = await Doctor.findById(user.doctorProfileId)
          .select('specialization approvalStatus hospitalAffiliation');
        userObj.doctorDetails = doctor;
      }
      
      return userObj;
    }));
    
    res.json({
      success: true,
      data: usersWithDetails,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
    
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ success: false, error: 'Failed to get users' });
  }
});

router.put('/users/:userId/status', authenticateToken, requireRole('admin'), [
  body('accountStatus').isIn(['active', 'suspended', 'pending_doctor_approval'])
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { accountStatus: req.body.accountStatus },
      { new: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    res.json({
      success: true,
      message: 'User status updated successfully',
      data: user
    });
    
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({ success: false, error: 'Failed to update user status' });
  }
});

router.get('/patients', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { search, page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;
    
    let query = {};
    
    if (search) {
      const users = await User.find({
        $or: [
          { fullName: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } }
        ]
      }).select('_id');
      
      const userIds = users.map(user => user._id);
      query.userId = { $in: userIds };
    }
    
    const [patients, total] = await Promise.all([
      Patient.find(query)
        .populate('userId', 'email fullName dateOfBirth gender phone')
        .populate('primaryDoctor', 'specialization hospitalAffiliation')
        .populate('primaryDoctor.userId', 'fullName')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .exec(),
      Patient.countDocuments(query)
    ]);
    
    res.json({
      success: true,
      data: patients,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
    
  } catch (error) {
    console.error('Get patients error:', error);
    res.status(500).json({ success: false, error: 'Failed to get patients' });
  }
});

router.put('/patients/:patientId', authenticateToken, requireRole('admin'), [
  body('age').optional().isInt({ min: 0, max: 150 }),
  body('weight').optional().isFloat({ min: 0, max: 500 }),
  body('height').optional().isFloat({ min: 0, max: 300 }),
  body('bloodType').optional().isIn(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'unknown']),
  body('careModeEnabled').optional().isBoolean(),
  body('preferredUnitSystem').optional().isIn(['metric', 'imperial']),
  body('primaryDoctor').optional().isMongoId(),
  body('allergies').optional().isArray(),
  body('chronicConditions').optional().isArray(),
  body('smokingStatus').optional().isIn(['never', 'former', 'current']),
  body('alcoholConsumption').optional().isIn(['none', 'light', 'moderate', 'heavy']),
  body('exerciseFrequency').optional().isIn(['sedentary', 'light', 'moderate', 'active', 'very_active']),
  body('medicalHistorySummary').optional().isString(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const patient = await Patient.findById(req.params.patientId);
    if (!patient) {
      return res.status(404).json({ success: false, error: 'Patient not found' });
    }
  
    const allowedUpdates = [
      'age', 'weight', 'height', 'bloodType', 'careModeEnabled',
      'preferredUnitSystem', 'primaryDoctor',
      'smokingStatus', 'alcoholConsumption', 'exerciseFrequency',
      'medicalHistorySummary'
    ];

    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        patient[field] = req.body[field];
      }
    });

    if (req.body.allergies !== undefined) {
      patient.allergies = req.body.allergies.map(allergen => ({
        allergen: allergen,
        severity: 'unknown',
        isActive: true
      }));
    }

    if (req.body.chronicConditions !== undefined) {
      patient.chronicConditions = req.body.chronicConditions.map(condition => ({
        condition: condition,
        status: 'active',
        medications: []
      }));
    }

    await patient.save();

    const userUpdates = {};
    if (req.body.age !== undefined) userUpdates.age = req.body.age.toString();
    if (req.body.height !== undefined) userUpdates.height = req.body.height.toString();
    if (req.body.weight !== undefined) userUpdates.weight = req.body.weight.toString();


    if (Object.keys(userUpdates).length > 0) {
      await User.findByIdAndUpdate(patient.userId, userUpdates);
    }

    const updatedPatient = await Patient.findById(patient._id)
      .populate('userId', 'fullName email age height weight')
      .populate('primaryDoctor', 'specialization');

    res.json({
      success: true,
      message: 'Patient updated successfully',
      data: updatedPatient
    });

  } catch (error) {
    console.error('Update patient error:', error);
    res.status(500).json({ success: false, error: 'Failed to update patient' });
  }
});

router.delete('/patients/:patientId', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const patient = await Patient.findById(req.params.patientId);
    
    if (!patient) {
      return res.status(404).json({ success: false, error: 'Patient not found' });
    }

    await Doctor.updateMany(
      { assignedPatients: req.params.patientId },
      { $pull: { assignedPatients: req.params.patientId } }
    );

    const user = await User.findById(patient.userId);
    if (user) {
      user.patientProfileId = null;
      if (!user.doctorProfileId && user.role === 'patient') {
        user.role = 'user';
      }
      await user.save();
    }

    await Patient.findByIdAndDelete(req.params.patientId);

    res.json({
      success: true,
      message: 'Patient profile deleted successfully, user role updated if needed'
    });

  } catch (error) {
    console.error('Delete patient error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete patient' });
  }
});

module.exports = router;