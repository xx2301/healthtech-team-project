const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');
require('dotenv').config();
const { startAutoSimulate } = require('./services/autoSimulateService');
const deviceRoutes = require('./routes/devices');
const Session = require('./models/Session');
const sessionRoutes = require('./routes/sessions');
const syncRoutes = require('./routes/sync');
const thresholdRoutes = require('./routes/thresholds');
const Notification = require('./models/Notification');
const notificationRoutes = require('./routes/notifications');
const goalRoutes = require('./routes/goals');
const doctorRoutes = require('./routes/doctor');
const chatRoutes = require('./routes/chat');
const Appointment = require('./models/Appointment');
const appointmentRoutes = require('./routes/appointments');
const patientRoutes = require('./routes/patient');
const authRoutes = require('./routes/auth');
const path = require('path');
const insightRoutes = require('./routes/insight');
const chatbotRoutes = require('./routes/chatbot');
const { requireRole } = require('./middleware/role');
const authenticateToken = require('./middleware/auth');
const adminRoutes = require('./routes/admin');
const userProfileRoutes = require('./routes/user-profile');
const goalsRoutes = require('./routes/goals');
const healthMetricRoutes = require('./routes/health-metrics');
const medicalRecordRoutes = require('./routes/medical-records');
const emergencyContactRoutes = require('./routes/emergency-contacts');
const relationRoutes = require('./routes/relations');
const symptomLogRoutes = require('./routes/symptom-logs');

const { User, Doctor, Patient, HealthMetric, MedicalRecord, EmergencyContact, DoctorPatientRelation, HealthGoal, SymptomLog, Device, Conversation, ChatMessage} = require('./models/index');
const mongoURI = process.env.MONGODB_URI || 'mongodb://admin:simplepassword@localhost:27017/healthtech?authSource=admin';

const app = express();
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/devices', deviceRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/devices/sync', syncRoutes);
app.use('/api/thresholds', thresholdRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/goals', goalRoutes);
app.use('/api/doctor', doctorRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/insight', insightRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/user', userProfileRoutes);
app.use('/api/health-goals', goalsRoutes);
app.use('/api/health-metrics', healthMetricRoutes);
app.use('/api/medical-records', medicalRecordRoutes);
app.use('/api/emergency-contacts', emergencyContactRoutes);
app.use('/api/doctor-patient-relations', relationRoutes);
app.use('/api/symptom-logs', symptomLogRoutes);
app.use(express.static(path.join(__dirname, 'public')));

app.use((req, res, next) => {
  console.log('=== REQUEST LOG ===');
  console.log('Method:', req.method);
  console.log('URL:', req.url);
  console.log('Content-Type:', req.headers['content-type']);
  console.log('Body:', req.body);
  console.log('=== END REQUEST LOG ===');
  next();
});

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

app.post('/auth/register', (req, res) => {
  req.url = '/api/auth/register';
  app._router.handle(req, res);
});

app.post('/auth/login', (req, res) => {
  req.url = '/api/auth/login';
  app._router.handle(req, res);
});

app.get('/auth/me', (req, res) => {
  res.redirect('/api/auth/me');
});

app.all('/api/patient/*', (req, res, next) => {
  req.url = req.url.replace('/api/patient', '/api/patients');
  app._router.handle(req, res);
});

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
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    
    const existingSleep = await HealthMetric.findOne({
      userId: user._id,
      metricType: 'sleep_duration',
      timestamp: { $gte: todayStart, $lt: todayEnd },
    });
    
    const metrics = [];
    
    if (!existingSleep) {
      const sleepHours = 6 + Math.random() * 3; // 6-9 小时
      metrics.push({
        userId: user._id,
        metricType: 'sleep_duration',
        value: sleepHours,
        unit: 'hours',
        source: 'device',
        deviceName: 'Sleep Tracker',
        timestamp: now,
        isAbnormal: false,
      });
    }

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