const bcrypt = require('bcryptjs');
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');
require('dotenv').config();
const nodemailer = require('nodemailer');
const { startAutoSimulate } = require('./services/autoSimulateService');
const deviceRoutes = require('./routes/devices');

const { User, Doctor, Patient, HealthMetric, MedicalRecord, EmergencyContact, DoctorPatientRelation, HealthGoal, SymptomLog, Device, HealthReport, Conversation, ChatMessage} = require('./models/index');

const app = express();
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  console.log('=== REQUEST LOG ===');
  console.log('Method:', req.method);
  console.log('URL:', req.url);
  console.log('Content-Type:', req.headers['content-type']);
  console.log('Body:', req.body);
  console.log('=== END REQUEST LOG ===');
  next();
});


const mongoURI = process.env.MONGODB_URI || 'mongodb://admin:simplepassword@localhost:27017/healthtech?authSource=admin';

mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('✅ Connected to MongoDB');
  
  User.createIndexes();
  Patient.createIndexes();
  Doctor.createIndexes();
  HealthMetric.createIndexes();
  MedicalRecord.createIndexes();
  EmergencyContact.createIndexes();
  DoctorPatientRelation.createIndexes();
})
.catch(err => {
  console.error('❌ MongoDB Connect error:', err);
  process.exit(1);
});

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, error: 'Access token missing' });
  }

  jwt.verify(token, JWT_SECRET, async (err, decoded) => {
    if (err) {
      return res.status(403).json({ success: false, error: 'Invalid access token' });
    }

    try {
      const user = await User.findById(decoded.userId);

      if (!user) {
        return res.status(404).json({ success: false, error: 'User not found' });
      }
      
      let detailedUser = user;
      if (user.userType === 'doctor') {
        detailedUser = await Doctor.findById(user._id);
      } else if (user.userType === 'patient') {
        detailedUser = await Patient.findById(user._id);
      }
      
      req.user = {
        userId: detailedUser._id,
        email: detailedUser.email,
        userType: detailedUser.userType,
        ...detailedUser.toObject()
      };
      
      next();
    } catch (error) {
      return res.status(500).json({ success: false, error: 'Failed to authenticate user' });
    }
  });
};

const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.userType)) {
      return res.status(403).json({ 
        success: false, 
        error: `Required role: ${roles.join(' or ')}` 
      });
    }
    next();
  };
};

app.use('/api/devices', deviceRoutes);

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>HealthTech - 简化版</title>
      <style>
        body { font-family: Arial; padding: 40px; max-width: 800px; margin: 0 auto; }
        h1 { color: #4CAF50; }
        .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-left: 4px solid #4CAF50; }
        code { background: #eee; padding: 2px 5px; }
      </style>
    </head>
    <body>
      <h1>🏥 HealthTech </h1>
      <p>Portal: ${PORT}</p>
      <p>This is a simplified healthcare system with only one unified user model.</p>
      
      <h3>📡 API Port</h3>
      <div class="endpoint">
        <strong>GET /health</strong> - System health check
      </div>
      <div class="endpoint">
        <strong>POST /auth/register</strong> - Registered users (patients or doctors) <br>
        <code>{ "email": "...", "password": "...", "fullName": "...", "userType": "patient|doctor" }</code>
      </div>
      <div class="endpoint">
        <strong>POST /auth/login</strong> - Login <br>
        <code>{ "email": "...", "password": "..." }</code>
      </div>
      <div class="endpoint">
        <strong>GET /auth/me</strong> - Get current user information (token required)
      </div>
      
      <h3>🔗 Quick Test</h3>
      <button onclick="testAPI()">Test API</button>
      <div id="result"></div>
      
      <script>
        async function testAPI() {
          const result = document.getElementById('result');
          result.innerHTML = 'Testing API...';
          
          try {
            // Health check
            const healthRes = await fetch('/health');
            const healthData = await healthRes.json();
            
            result.innerHTML = \`
              ✅ System is running normally<br>
              Status: \${healthData.status}<br>
              User count: \${healthData.stats.users}
            \`;
          } catch (error) {
            result.innerHTML = '❌ Test failed: ' + error.message;
          }
        }
      </script>
    </body>
    </html>
  `);
});

app.get('/api/health', async (req, res) => {
  try {
    const dbState = mongoose.connection.readyState;
    const dbStatus = dbState === 1 ? 'connected' : 'disconnected';
    
    const [
      userCount,
      doctorCount,
      patientCount,
      healthMetricCount,
      medicalRecordCount,
      emergencyContactCount
    ] = await Promise.all([
      User.countDocuments(),
      Doctor.countDocuments(),
      Patient.countDocuments(),
      HealthMetric.countDocuments(),
      MedicalRecord.countDocuments(),
      EmergencyContact.countDocuments()
    ]);
    
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const recentUsers = await User.countDocuments({
      registrationDate: { $gte: sevenDaysAgo }
    });
    
    const twentyFourHoursAgo = new Date();
    twentyFourHoursAgo.setHours(twentyFourHoursAgo.getHours() - 24);
    
    const recentHealthMetrics = await HealthMetric.countDocuments({
      timestamp: { $gte: twentyFourHoursAgo }
    });
    
    res.status(200).json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'HealthTech API v2.0',
      version: '2.0.0',
      database: {
        connected: dbState === 1,
        message: dbState === 1 ? '✅ Connected to MongoDB successfully!' : '❌ MongoDB connection issue',
        stats: {
          users: userCount,
          doctors: doctorCount,
          patients: patientCount,
          healthMetrics: healthMetricCount,
          medicalRecords: medicalRecordCount,
          emergencyContacts: emergencyContactCount,
          recentUsers24h: recentUsers,
          recentHealthMetrics24h: recentHealthMetrics
        }
      },
      endpoints: {
        auth: [
          'POST /api/auth/register',
          'POST /api/auth/login',
          'GET  /api/auth/verify',
          'POST /api/auth/logout'
        ],
        patient: [
          'GET  /api/patients/profile',
          'POST /api/patients/update-profile',
          'GET  /api/patients/doctors',
          'POST /api/patients/emergency-contacts'
        ],
        doctor: [
          'GET  /api/doctors/profile',
          'POST /api/doctors/update-profile',
          'GET  /api/doctors/patients',
          'POST /api/doctors/medical-records'
        ],
        health: [
          'GET  /api/health-metrics',
          'POST /api/health-metrics',
          'GET  /api/medical-records',
          'POST /api/symptom-logs'
        ],
        relations: [
          'POST /api/doctor-patient-relations',
          'GET  /api/relations/pending',
          'POST /api/relations/:id/approve'
        ]
      },
      system: {
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        nodeVersion: process.version,
        platform: process.platform
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

app.post('/api/auth/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('fullName').notEmpty().trim().escape(),
  body('age').optional().isString(),
  body('height').optional().isString(),
  body('weight').optional().isString(),
  body('dateOfBirth').optional().isISO8601().toDate(),
  body('gender').optional().isIn(['male', 'female', 'other', 'prefer_not_to_say'])
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ 
      success: false, 
      errors: errors.array(),
      message: 'Validation failed' 
    });
  }

  try {
    const { email, password, fullName, age, height, weight, dateOfBirth, gender } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email has already been registered' 
      });
    }

    const user = new User({
      email,
      password,
      fullName,
      age: age || '',
      height: height || '',
      weight: weight || '',
      userType: 'user',
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
      gender: gender || 'other',
      isActive: true,
    });

    await user.save();

    const token = jwt.sign(
      { userId: user._id, email: user.email, userType: user.userType },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Registration failed',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Please try again later'
    });
  }
});

app.post('/auth/register', (req, res) => {
  req.url = '/api/auth/register';
  app._router.handle(req, res);
});

app.post('/api/auth/login', [
  body('email').isEmail().normalizeEmail(),
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
        error: 'Email or password incorrect' 
      });
    }

    const isValidPassword = await user.comparePassword(password);
    if (!isValidPassword) {
      return res.status(401).json({ 
        success: false, 
        error: 'Email or password incorrect' 
      });
    }

    user.updatedAt = new Date();
    await user.save();

    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email,
        userType: user.userType 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Login failed' 
    });
  }
});

app.post('/auth/login', (req, res) => {
  req.url = '/api/auth/login';
  app._router.handle(req, res);
});

app.post('/api/admin/login', [
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

    const token = jwt.sign(
      { 
        userId: user._id, 
        email: user.email,
        userType: user.userType,
        role: user.role,
        permissions: user.permissions
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

// user change password by themselves
app.put('/api/user/password', authenticateToken, [
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

// send email to reset password
app.post('/api/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, error: 'Email not found' });
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    user.passwordResetToken = resetToken;
    user.passwordResetExpires = Date.now() + 3600000; // 1 hour
    await user.save();

    // send email using nodemailer
    const transporter = nodemailer.createTransport({
      serviice: 'Gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const resetLink = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
    const mailOptions = {
      to: email,
      from: process.env.EMAIL_USER,
      subject: 'HealthTech Password Reset',
      text: `You are receiving this email because you (or someone else) have requested a password reset for your account.\n\n ${resetLink}`,
    };

    await transporter.sendMail(mailOptions);

    res.json({ success: true, message: 'Password reset email sent' });
  } catch (error) {
    console.error('Error sending password reset email:', error);
    res.status(500).json({ success: false, error: 'Failed to send password reset email' });
  }
});

app.post('/api/auth/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  try {
    const user = await User.findOne({
      passwordResetToken: token,
      passwordResetExpires: { $gt: Date.now() }
    });
    if (!user) {
      return res.status(400).json({ success: false, error: 'Invalid or expired token' });
    }
    user.password = newPassword;
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save();
    res.json({ success: true, message: 'Password updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

app.post('/api/user/apply-for-doctor', authenticateToken, [
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
    
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    const existingDoctor = await Doctor.findOne({ userId: user._id });
    if (existingDoctor) {
      return res.status(400).json({ 
        success: false, 
        error: existingDoctor.approvalStatus === 'approved' 
          ? 'You are already a doctor' 
          : 'You already have a pending doctor application'
      });
    }
    
    const existingLicense = await Doctor.findOne({ 
      medicalLicenseNumber: req.body.medicalLicenseNumber.toUpperCase() 
    });
    
    if (existingLicense) {
      return res.status(400).json({ 
        success: false, 
        error: 'Medical license number already registered' 
      });
    }
    
    const doctor = new Doctor({
      userId: user._id,
      medicalLicenseNumber: req.body.medicalLicenseNumber.toUpperCase(),
      specialization: req.body.specialization,
      hospitalAffiliation: req.body.hospitalAffiliation,
      department: req.body.department,
      yearsOfExperience: req.body.yearsOfExperience,
      consultationFee: req.body.consultationFee || 0,
      qualifications: req.body.qualifications || [],
      bio: req.body.bio,
      languagesSpoken: req.body.languagesSpoken || [],
      approvalStatus: 'pending'
    });
    
    await doctor.save();
    
    user.accountStatus = 'pending_doctor_approval';
    await user.save();
    
    res.status(201).json({
      success: true,
      message: 'Doctor application submitted successfully. Waiting for admin approval.',
      applicationId: doctor._id
    });
    
  } catch (error) {
    console.error('Submit doctor application error:', error);
    res.status(500).json({ success: false, error: 'Failed to submit doctor application' });
  }
});

const requireAdmin = (req, res, next) => {
  if (!req.user || (req.user.userType !== 'admin' && !['super_admin', 'admin', 'moderator'].includes(req.user.role))) {
    return res.status(403).json({ 
      success: false, 
      error: 'Admin access required' 
    });
  }
  next();
};

app.post('/api/admin/create-patient', authenticateToken, requireAdmin, [
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

app.post('/api/doctor/create-patient', authenticateToken, [
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

app.get('/api/admin/pending-doctor-applications', authenticateToken, requireAdmin, async (req, res) => {
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

app.get('/api/admin/doctor-applications', authenticateToken, requireAdmin, async (req, res) => {
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

app.get('/api/admin/doctor-applications/:applicationId', authenticateToken, requireAdmin, async (req, res) => {
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

app.post('/api/admin/doctor-applications/bulk-action', authenticateToken, requireAdmin, [
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

app.post('/api/admin/approve-doctor/:doctorId', authenticateToken, requireAdmin, async (req, res) => {
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
    doctor.approvedAt = new Date();
    
    await doctor.save();
    
    await User.findByIdAndUpdate(doctor.userId, {
      accountStatus: 'active',
      doctorProfileId: doctor._id,
      role: 'doctor'
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

app.post('/api/admin/reject-doctor/:doctorId', authenticateToken, requireAdmin, [
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
    
    await doctor.save();
    
    await User.findByIdAndUpdate(doctor.userId, {
      accountStatus: 'active'
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

app.get('/auth/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        error: 'User not found' 
      });
    }

    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(200).json({
      success: true,
      user: userResponse
    });
  } catch (error) {
    console.error('Fetch user info error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch user information' 
    });
  }
});

app.get('/api/user/full-profile', authenticateToken, async (req, res) => {
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

app.put('/api/user/profile', authenticateToken, [
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

    console.log('Received avatarColor:', req.body.avatarColor);
    if (req.body.avatarColor !== undefined) {
      user.avatarColor = req.body.avatarColor;
      console.log('Saved avatarColor to user');
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

app.get('/api/admin/users', authenticateToken, requireAdmin, async (req, res) => {
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

app.put('/api/admin/users/:userId/status', authenticateToken, requireAdmin, [
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

// get all patients (for doctors and admins)
app.get('/api/patients/all', authenticateToken, async (req, res) => {
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
      .select('-__v');

    res.json({
      success: true,
      data: patients,
      count: patients.length
    });
  } catch (error) {
    console.error('Get patients list error:', error);
    res.status(500).json({ success: false, error: 'Failed to get patients list' });
  }
});

app.get('/api/admin/patients', authenticateToken, requireAdmin, async (req, res) => {
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

app.put('/api/admin/patients/:patientId', authenticateToken, requireAdmin, [
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

app.delete('/api/admin/patients/:patientId', authenticateToken, requireAdmin, async (req, res) => {
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

app.put('/api/patient/profile', authenticateToken, async (req, res) => {
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

app.put('/api/doctor/profile', authenticateToken, async (req, res) => {
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
    Object.keys(updates).forEach(key => {
      if (['hospitalAffiliation', 'department', 'yearsOfExperience', 'consultationFee', 
           'availabilitySchedule', 'status', 'maxPatients', 'qualifications', 
           'bio', 'languagesSpoken'].includes(key)) {
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

app.get('/api/user/check-role', authenticateToken, async (req, res) => {
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

app.get('/api/user/basic-info', authenticateToken, async (req, res) => {
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

app.get('/api/health-metrics', authenticateToken, async (req, res) => {
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
        console.log('Admin search for:', search);
        const users = await User.find({
          $or: [
            { fullName: { $regex: search, $options: 'i' } },
            { email: { $regex: search, $options: 'i' } }
          ]
        }).select('_id');
        console.log('Found users:', users.map(u => ({ id: u._id, fullName: u.fullName, email: u.email })));
        const userIds = users.map(u => u._id);
        console.log('User IDs:', userIds);
        query.userId = { $in: userIds };
      }
    } else if (user.userType === 'patient' || user.userType === 'user') {
      query.userId = user._id;
    } else if (user.userType === 'doctor') {
      const relations = await DoctorPatientRelation.find({ doctorId: user._id, status: 'active' }).select('patientId');
      const patientIds = relations.map(r => r.patientId);
      if (patientIds.length === 0) {
        return res.json({ success: true, data: [], pagination: { total: 0, page: parseInt(page), limit: parseInt(limit), pages: 0 } });
      }
      query.patientId = { $in: patientIds };
    } else {
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

    res.json({ success: true, data: metrics, pagination: { total, page: parseInt(page), limit: parseInt(limit), pages: Math.ceil(total / limit) } });
  } catch (error) {
    console.error('Fetch health metrics error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch health metrics' });
  }
});

app.post('/api/health-metrics', authenticateToken, [
  body('metricType').isIn([
    'steps', 'heart_rate', 'blood_pressure', 'blood_glucose',
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

app.post('/api/medical-records', authenticateToken, requireRole('doctor'), [
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
    
    await createActivityLog({
      userId: req.user._id,
      patientId,
      action: 'create_medical_record',
      details: { recordId: medicalRecord._id, visitType },
      timestamp: new Date()
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

// Get medical records (available to doctors and admin)
app.get('/api/medical-records', authenticateToken, async (req, res) => {
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
        .populate('doctorId', 'specialization')
        .populate('doctorId.userId', 'fullName')
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
        recordObj.doctorName = record.doctorId.userId.fullName || 'Unknown';
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

app.get('/api/patients/medical-records', authenticateToken, async (req, res) => {
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
    
    if (req.user.userType === 'patient' && req.user._id.toString() === patientId) {
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
        .populate('doctor', 'fullName specialization hospitalAffiliation')
        .populate('patient', 'fullName dateOfBirth gender')
        .exec(),
      MedicalRecord.countDocuments(query)
    ]);
    
    res.status(200).json({
      success: true,
      data: records,
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

app.post('/api/emergency-contacts', authenticateToken, requireRole('patient'), [
  body('fullName').notEmpty().trim(),
  body('relationship').isIn([
    'spouse', 'parent', 'child', 'sibling',
    'friend', 'relative', 'caregiver', 'other'
  ]),
  body('phoneNum').isMobilePhone(),
  body('email').optional().isEmail(),
  body('isPrimary').optional().isBoolean()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const {
      fullName,
      relationship,
      phoneNum,
      email,
      address,
      isPrimary = false,
      notiEnabled = true,
      preferredContactMethod = 'phone'
    } = req.body;
    
    const emergencyContact = new EmergencyContact({
      patientId: req.user._id,
      fullName,
      relationship,
      phoneNum,
      email,
      address,
      isPrimary,
      notiEnabled,
      preferredContactMethod
    });
    
    await emergencyContact.save();
    
    await Patient.findByIdAndUpdate(
      req.user._id,
      { $push: { emergencyContacts: emergencyContact._id } }
    );
    
    res.status(201).json({
      success: true,
      message: 'Emergency contact added successfully',
      data: emergencyContact
    });
    
  } catch (error) {
    console.error('Add emergency contact error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add emergency contact'
    });
  }
});

app.post('/api/doctor-patient-relations', authenticateToken, requireRole('doctor'), [
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
    
    await sendNotification({
      userId: patientId,
      type: 'doctor_request',
      title: 'New Doctor Connection Request',
      message: `Dr. ${req.user.fullName} wants to connect with you`,
      data: { relationId: relation._id, doctorId: req.user._id }
    });
    
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

app.get('/api/doctors/patients', authenticateToken, requireRole('doctor'), async (req, res) => {
  try {
    const relations = await DoctorPatientRelation.find({ 
      doctorId: req.user.userId,
      status: 'active'
    }).populate('patient', 'fullName patientCode dateOfBirth gender');
    
    const patients = relations.map(relation => ({
      ...relation.patient.toObject(),
      relationType: relation.relationType,
      permissions: relation.permissions
    }));
    
    res.status(200).json({
      success: true,
      data: patients,
      count: patients.length
    });
  } catch (error) {
    console.error('Fetch patients error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch patients list' });
  }
});

app.get('/api/patients/doctors', authenticateToken, requireRole('patient'), async (req, res) => {
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

app.post('/api/symptom-logs', authenticateToken, requireRole('patient'), [
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

app.get('/api/symptom-logs', authenticateToken, requireRole('patient'), async (req, res) => {
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

app.post('/api/health-goals', authenticateToken, [
  body('goalType').notEmpty(),
  body('targetValue').isNumeric(),
  body('targetDate').isISO8601()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const { goalType, targetValue, targetDate, startDate, frequency, priority, description, title } = req.body;
    
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const healthGoal = new HealthGoal({
      patientId: user.patientProfileId || null,
      userId: user._id,
      goalType,
      title: title || `${goalType} goal`,
      targetValue: parseFloat(targetValue),
      currentValue: 0,
      startDate: startDate ? new Date(startDate) : new Date(),
      targetDate: new Date(targetDate),
      frequency: frequency || 'daily',
      priority: priority || 'medium',
      isActive: true,
      progressPercentage: 0,
      description
    });
    
    await healthGoal.save();
    
    res.status(201).json({
      success: true,
      message: 'Health goal set successfully',
      data: healthGoal
    });
  } catch (error) {
    console.error('Set health goal error:', error);
    res.status(500).json({ success: false, error: 'Failed to set health goal' });
  }
});

app.get('/api/health-goals', authenticateToken, async (req, res) => {
  try {
    const { isActive } = req.query;
    const query = { userId: req.user.userId };
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    const goals = await HealthGoal.find(query).sort({ priority: 1, targetDate: 1 });
    res.json({ success: true, data: goals, count: goals.length });
  } catch (error) {
    console.error('Fetch health goals error:', error);
    res.status(500).json({ success: false, error: 'Failed to retrieve health goals' });
  }
});

app.put('/api/health-goals/:goalId', authenticateToken, async (req, res) => {
  try {
    const goalId = req.params.goalId;
    const userId = req.user.userId;

    const goal = await HealthGoal.findOne({ _id: goalId, userId });
    if (!goal) {
      return res.status(404).json({ success: false, error: 'Goal not found or not owned by you' });
    }

    const allowedUpdates = [
      'targetValue',
      'title',
      'description',
      'targetDate',
      'priority',
      'isActive',
      'frequency',
      'notes',
      'category',
      'reminders'
    ];

    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        goal[field] = req.body[field];
      }
    });

    if (req.body.targetValue !== undefined) {
      goal.progressPercentage = (goal.currentValue / goal.targetValue) * 100;
    }

    goal.lastUpdated = new Date();
    await goal.save();

    res.json({
      success: true,
      message: 'Health goal updated successfully',
      data: goal
    });
  } catch (error) {
    console.error('Update health goal error:', error);
    res.status(500).json({ success: false, error: 'Failed to update health goal' });
  }
});

//new router for v2 APIs
const router = express.Router();

//patient routes
router.get('/patients/profile', authenticateToken, requireRole('patient'), async (req, res) => {
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

//doctor routes
router.get('/doctors/profile', authenticateToken, requireRole('doctor'), async (req, res) => {
  try {
    const doctor = await Doctor.findById(req.user._id)
      .populate('assignedPatients', 'fullName patientCode dateOfBirth');
    
    res.status(200).json({
      success: true,
      data: doctor
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.use('/api/v2', router);

function getDefaultUnit(type) {
  const units = {
    'steps': 'steps',
    'heart_rate': 'bpm',
    'blood_pressure': 'mmHg',
    'weight': 'kg',
    'height': 'cm',
    'temperature': '°C',
    'sleep': 'hours',
    'calories': 'kcal'
  };
  return units[type] || 'unit';
}

app.post('/api/debug/check-request', (req, res) => {
  console.log('Debug request body:', req.body);
  console.log('Body type:', typeof req.body);
  
  res.json({
    success: true,
    received: req.body,
    type: typeof req.body,
    headers: req.headers
  });
});

// simulate health data
app.post('/api/dev/simulate-health-data', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const now = new Date();
    const metrics = [];

    const heartRate = 60 + Math.floor(Math.random() * 40); // 60-100 bpm
    metrics.push({
      userId: user._id,
      patientId: null,
      metricType: 'heart_rate',
      value: heartRate,
      unit: 'bpm',
      source: 'device',
      deviceName: 'Heart Monitor',
      timestamp: now,
      isAbnormal: heartRate < 50 || heartRate > 120,
    });

    const stepsDelta = Math.floor(Math.random() * 20); // 0-19 steps
    metrics.push({
      userId: user._id,
      patientId: null,
      metricType: 'steps',
      value: stepsDelta,
      unit: 'steps',
      source: 'device',
      deviceName: 'Smart Watch',
      timestamp: now,
      isAbnormal: stepsDelta > 100,
    });

    const caloriesDelta = 1 + Math.random() * 4; // 1-5 kcal
    metrics.push({
      userId: user._id,
      patientId: null,
      metricType: 'calories_burned',
      value: caloriesDelta,
      unit: 'kcal',
      source: 'device',
      deviceName: 'Smart Watch',
      timestamp: now,
    });

    const glucose = 4.0 + Math.random() * 3.0; // 4-7 mmol/L
    metrics.push({
      userId: user._id,
      patientId: null,
      metricType: 'glucose',
      value: glucose,
      unit: 'mmol/L',
      source: 'device',
      deviceName: 'CGM',
      timestamp: now,
      isAbnormal: glucose < 3.5 || glucose > 7.8,
    });

    await HealthMetric.insertMany(metrics, { ordered: false });

    res.json({
      success: true,
      message: `Generated ${metrics.length} real-time metrics for user ${user.email}`,
    });
  } catch (error) {
    console.error('Simulate live data error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Portal not found'
  });
});

app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    success: false,
    error: 'Server error occurred',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.listen(PORT, () => {
  console.log(`🚀 HealthTech ${PORT}`);
  console.log(`🌐 Homepage: http://localhost:${PORT}`);
  console.log(`📊 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`📝 Register: POST http://localhost:${PORT}/api/auth/register`);
  console.log(`🔐 Login: POST http://localhost:${PORT}/api/auth/login`);

  // Only start auto-simulation in development mode to prevent unintended data generation in production
  if (process.env.NODE_ENV !== 'production') {
    startAutoSimulate();
  } else {
    console.log('Production mode: auto-simulate disabled.');
  }
});