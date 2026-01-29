const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');

const app = express();
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

app.use(helmet()); //Security headers
app.use(cors({
  origin: '*', //Allow all origins; in a production environment, specific origins should be specified.
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json()); //Parse JSON request body
app.use(express.urlencoded({ extended: true })); //Parse URL-encoded request body

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, //15mins
  max: 100, //each ip max 100 requests in 15 minutes
  message: 'Request limit exceeded, please try again later.'
});
app.use('/api/', limiter);

mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/healthtech', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB'))
.catch(err => console.error('❌ MongoDB connection error:', err));

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true },
  name: { type: String, required: true, trim: true },
  age: { type: Number, min: 0, max: 150 },
  weight: { type: Number, min: 0, max: 300 },
  height: { type: Number, min: 0, max: 300 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const healthDataSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, default: Date.now },
  steps: { type: Number, min: 0, default: 0 },
  heartRate: { type: Number, min: 0, max: 300, default: 0 },
  calories: { type: Number, min: 0, default: 0 },
  sleepHours: { type: Number, min: 0, max: 24, default: 0 },
  notes: { type: String, trim: true }
});

const reminderSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true, trim: true },
  description: { type: String, trim: true },
  dueDate: { type: Date, required: true },
  completed: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);
const HealthData = mongoose.model('HealthData', healthDataSchema);
const Reminder = mongoose.model('Reminder', reminderSchema);

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, error: 'Access token missing' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, error: 'Invalid access token' });
    }
    req.user = user;
    next();
  });
};

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>HealthTech - Health Management System</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            }
            
            body {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }
            
            .container {
                background: white;
                border-radius: 20px;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                overflow: hidden;
                width: 100%;
                max-width: 900px;
            }
            
            .header {
                background: #4CAF50;
                color: white;
                padding: 30px;
                text-align: center;
            }
            
            .header h1 {
                font-size: 2.5rem;
                margin-bottom: 10px;
            }
            
            .header p {
                font-size: 1.1rem;
                opacity: 0.9;
            }
            
            .content {
                padding: 40px;
            }
            
            .stats-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 20px;
                margin-bottom: 40px;
            }
            
            .stat-card {
                background: #f8f9fa;
                border-radius: 10px;
                padding: 20px;
                text-align: center;
                transition: transform 0.3s;
            }
            
            .stat-card:hover {
                transform: translateY(-5px);
            }
            
            .stat-card h3 {
                color: #4CAF50;
                font-size: 2.5rem;
                margin-bottom: 10px;
            }
            
            .stat-card p {
                color: #666;
                font-size: 1rem;
            }
            
            .api-info {
                background: #f0f7ff;
                border-left: 4px solid #2196F3;
                padding: 20px;
                margin-bottom: 30px;
                border-radius: 0 8px 8px 0;
            }
            
            .api-info h3 {
                color: #2196F3;
                margin-bottom: 15px;
            }
            
            .endpoint {
                background: white;
                padding: 10px 15px;
                margin: 10px 0;
                border-radius: 5px;
                border: 1px solid #e0e0e0;
                font-family: monospace;
            }
            
            .buttons {
                display: flex;
                gap: 15px;
                flex-wrap: wrap;
            }
            
            .btn {
                padding: 12px 24px;
                border: none;
                border-radius: 8px;
                font-size: 1rem;
                cursor: pointer;
                transition: all 0.3s;
                text-decoration: none;
                display: inline-block;
            }
            
            .btn-primary {
                background: #4CAF50;
                color: white;
            }
            
            .btn-secondary {
                background: #2196F3;
                color: white;
            }
            
            .btn-outline {
                background: transparent;
                border: 2px solid #4CAF50;
                color: #4CAF50;
            }
            
            .btn:hover {
                opacity: 0.9;
                transform: translateY(-2px);
            }
            
            .footer {
                text-align: center;
                padding: 20px;
                color: #666;
                border-top: 1px solid #eee;
            }
            
            @media (max-width: 768px) {
                .container {
                    margin: 10px;
                }
                
                .content {
                    padding: 20px;
                }
                
                .header h1 {
                    font-size: 2rem;
                }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🏥 HealthTech API</h1>
                <p>Health Management System Backend Service</p>
            </div>
            
            <div class="content">
                <div class="stats-grid" id="stats">
                    <!-- Dynamic data will be populated using JavaScript -->
                    <div class="stat-card">
                        <h3 id="userCount">...</h3>
                        <p>Registered Users</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="healthDataCount">...</h3>
                        <p>Health Records</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="reminderCount">...</h3>
                        <p>Active Reminders</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="dbStatus">✅</h3>
                        <p>Database Status</p>
                    </div>
                </div>
                
                <div class="api-info">
                    <h3>📡 API Endpoints</h3>
                    <div class="endpoint">GET /api/health - Health check</div>
                    <div class="endpoint">POST /api/auth/register - User registration</div>
                    <div class="endpoint">POST /api/auth/login - User login</div>
                    <div class="endpoint">GET /api/health-data - Get health data (auth required)</div>
                    <div class="endpoint">POST /api/health-data - Add health data (auth required)</div>
                    <div class="endpoint">GET /api/reminders - Get reminders (auth required)</div>
                </div>
                
                <div class="buttons">
                    <a href="/api/health" class="btn btn-primary">Check API Health</a>
                    <a href="/admin" class="btn btn-secondary">Admin Dashboard</a>
                    <a href="https://github.com/xx2301" class="btn btn-outline">GitHub Repository</a>
                </div>
            </div>
            
            <div class="footer">
                <p>© 2026 HealthTech System | Port: ${PORT} | MongoDB Connected</p>
            </div>
        </div>
        
        <script>
            // 获取并显示统计信息
            async function loadStats() {
                try {
                    const response = await fetch('/api/health');
                    const data = await response.json();
                    
                    document.getElementById('userCount').textContent = data.database.stats.users;
                    document.getElementById('healthDataCount').textContent = data.database.stats.healthData;
                    document.getElementById('reminderCount').textContent = data.database.stats.reminders;
                    
                    if (!data.database.connected) {
                        document.getElementById('dbStatus').textContent = '❌';
                        document.getElementById('dbStatus').style.color = 'red';
                    }
                } catch (error) {
                    console.error('Failed to load stats:', error);
                    document.getElementById('userCount').textContent = 'Error';
                    document.getElementById('healthDataCount').textContent = 'Error';
                    document.getElementById('reminderCount').textContent = 'Error';
                    document.getElementById('dbStatus').textContent = '❌';
                }
            }
            
            document.addEventListener('DOMContentLoaded', loadStats);
            
            setInterval(loadStats, 30000);
        </script>
    </body>
    </html>
  `);
});

app.get('/api/health', async (req, res) => {
  try {
    const dbState = mongoose.connection.readyState;
    const dbStatus = dbState === 1 ? 'connected' : 'disconnected';

    const userCount = await User.countDocuments();
    const healthDataCount = await HealthData.countDocuments();
    const reminderCount = await Reminder.countDocuments();

    res.status(200).json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'HealthTech API',
      version: '1.0.0',
      database: {
        connected: dbState === 1,
        message: dbState === 1 ? '✅ Connected to MongoDB successfully!' : '❌ MongoDB connection issue',
        stats: {
          users: userCount,
          healthData: healthDataCount,
          reminders: reminderCount,
          status: dbStatus
        }
      },
      endpoints: {
        auth: [
          'POST /api/auth/register',
          'POST /api/auth/login'
        ],
        health: [
          'GET /api/health-data',
          'POST /api/health-data'
        ],
        reminders: [
          'GET /api/reminders',
          'POST /api/reminders'
        ],
        admin: [
          'GET /api/admin/stats',
          'POST /api/admin/backup'
        ]
      },
      services: {
        patientService: 'running',
        appointmentService: 'running',
        authService: 'running'
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
  body('name').notEmpty().trim().escape(),
  body('age').optional().isInt({ min: 0, max: 150 }),
  body('weight').optional().isFloat({ min: 0, max: 300 }),
  body('height').optional().isFloat({ min: 0, max: 300 })
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { email, password, name, age, weight, height } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ success: false, error: 'Email has already been registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = new User({
      email,
      password: hashedPassword,
      name,
      age,
      weight,
      height
    });

    await user.save();

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    //return data for user excluded password
    const userResponse = {
      _id: user._id,
      email: user.email,
      name: user.name,
      age: user.age,
      weight: user.weight,
      height: user.height,
      createdAt: user.createdAt
    };

    res.status(201).json({
      success: true,
      message: 'Register successful',
      user: userResponse,
      token
    });
  } catch (error) {
    console.error('Register Error:', error);
    res.status(500).json({ success: false, error: 'Register failed, please try again later' });
  }
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
      return res.status(401).json({ success: false, error: 'Email or password is incorrect' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ success: false, error: 'Email or password is incorrect' });
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    //return data for user excluded password
    const userResponse = {
      _id: user._id,
      email: user.email,
      name: user.name,
      age: user.age,
      weight: user.weight,
      height: user.height,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };

    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: userResponse,
      token
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, error: 'Login failed, please try again later' });
  }
});

app.get('/api/auth/verify', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.status(200).json({
      success: true,
      user: {
        _id: user._id,
        email: user.email,
        name: user.name,
        age: user.age,
        weight: user.weight,
        height: user.height,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
  } catch (error) {
    console.error('Verification failed:', error);
    res.status(500).json({ success: false, error: 'Verification failed' });
  }
});

app.post('/api/auth/forgot-password', [
  body('email').isEmail().normalizeEmail()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      //for security, return a success message even if email not found
      return res.status(200).json({
        success: true,
        message: 'If the email exists, a password reset link has been sent'
      });
    }

    const resetToken = jwt.sign(
      { userId: user._id, email: user.email, purpose: 'password_reset' },
      JWT_SECRET,
      { expiresIn: '1h' }
    );

    // An email should be sent here, but for simplicity, we just return a message
    // In a real project: sendResetEmail(user.email, resetToken);
    res.status(200).json({
      success: true,
      message: 'password reset link has been sent to your email',
      resetToken // This should not be returned in an actual project; it is only used for demonstration here.
    });
  } catch (error) {
    console.error('forgot password error:', error);
    res.status(500).json({ success: false, error: 'request failed, please try again later' });
  }
});

app.post('/api/auth/logout', authenticateToken, (req, res) => {
  res.status(200).json({ success: true, message: 'Logged out successfully' });
});

app.delete('/api/auth/delete-account', authenticateToken, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user.userId);
    //await HealthData.deleteMany({ userId: req.user.userId });
    //await Reminder.deleteMany({ userId: req.user.userId });

    res.status(200).json({ success: true, message: 'account deleted successfully' });
  } catch (error) {
    console.error('delete account error:', error);
    res.status(500).json({ success: false, error: 'delete account failed' });
  }
});

app.get('/api/health-data', authenticateToken, async (req, res) => {
  try {
    const healthData = await HealthData.find({ userId: req.user.userId })
      .sort({ date: -1 })
      .limit(30);

    res.status(200).json({
      success: true,
      data: healthData
    });
  } catch (error) {
    console.error('Fetch health data error:', error);
    res.status(500).json({ success: false, error: 'Fetch health data failed' });
  }
});

app.post('/api/health-data', authenticateToken, [
  body('steps').optional().isInt({ min: 0 }),
  body('heartRate').optional().isInt({ min: 0, max: 300 }),
  body('calories').optional().isFloat({ min: 0 }),
  body('sleepHours').optional().isFloat({ min: 0, max: 24 }),
  body('notes').optional().trim().escape()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { steps, heartRate, calories, sleepHours, notes } = req.body;

    const healthData = new HealthData({
      userId: req.user.userId,
      steps,
      heartRate,
      calories,
      sleepHours,
      notes
    });

    await healthData.save();

    res.status(201).json({
      success: true,
      message: 'Health data saved successfully',
      data: healthData
    });
  } catch (error) {
    console.error('Save health data error:', error);
    res.status(500).json({ success: false, error: 'Save health data failed' });
  }
});

app.get('/api/reminders', authenticateToken, async (req, res) => {
  try {
    const reminders = await Reminder.find({ userId: req.user.userId })
      .sort({ dueDate: 1 });

    res.status(200).json({
      success: true,
      data: reminders
    });
  } catch (error) {
    console.error('Fetch reminders error:', error);
    res.status(500).json({ success: false, error: 'Fetch reminders failed' });
  }
});

app.post('/api/reminders', authenticateToken, [
  body('title').notEmpty().trim().escape(),
  body('description').optional().trim().escape(),
  body('dueDate').isISO8601()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  try {
    const { title, description, dueDate } = req.body;

    const reminder = new Reminder({
      userId: req.user.userId,
      title,
      description,
      dueDate
    });

    await reminder.save();

    res.status(201).json({
      success: true,
      message: 'Reminder created successfully',
      data: reminder
    });
  } catch (error) {
    console.error('Create reminder error:', error);
    res.status(500).json({ success: false, error: 'Create reminder failed' });
  }
});

app.get('/api/admin/stats', authenticateToken, async (req, res) => {
  try {
    // Verify administrator privileges (simplified: check a specific user ID)
    const ADMIN_USER_ID = process.env.ADMIN_USER_ID;
    if (req.user.userId !== ADMIN_USER_ID) {
      return res.status(403).json({ success: false, error: 'Restricted access' });
    }

    const totalUsers = await User.countDocuments();
    const totalHealthData = await HealthData.countDocuments();
    const totalReminders = await Reminder.countDocuments();

    //new users in the last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const recentUsers = await User.countDocuments({
      createdAt: { $gte: sevenDaysAgo }
    });

    res.status(200).json({
      success: true,
      stats: {
        totalUsers,
        totalHealthData,
        totalReminders,
        recentUsers
      }
    });
  } catch (error) {
    console.error('Fetch statistics error:', error);
    res.status(500).json({ success: false, error: 'Fetch statistics failed' });
  }
});

app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    success: false,
    error: 'Server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 Homepage: http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔧 Admin panel: http://localhost:${PORT}/admin`);
});