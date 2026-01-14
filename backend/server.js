const express = require("express");
const cors = require("cors");
require("dotenv").config();

const PatientService = require("./services/PatientService");
const AppointmentService = require("./services/AppointmentService");
const AuthService = require("./services/AuthService");

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

const initializeTestData = () => {
  PatientService.initializeTestData();
  AppointmentService.initTestData();
  console.log("Test data initialized");
};

initializeTestData();

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    message: "The backend server is running",
    timestamp: new Date().toISOString(),
    port: PORT,
    service: {
      patients: PatientService.getAllPatients().data.length,
      appointments: AppointmentService.getAllAppointments().data.length,
      users: "In-memory storage"
    }
  });
});

// Patients Management API
app.get("/api/patients", (req, res) => {
  const result = PatientService.getAllPatients();
  res.status(result.success ? 200 : 404).json(result);
});

app.get("/api/patients/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const result = PatientService.getPatientById(id);
  res.status(result.success ? 200 : 404).json(result);
});

app.post("/api/patients", (req, res) => {
  const result = PatientService.createPatient(req.body);
  res.status(result.success ? 201 : 400).json(result);
});

app.put("/api/patients/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const result = PatientService.updatePatient(id, req.body);
  res.status(result.success ? 200 : 404).json(result);
});

app.delete("/api/patients/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const result = PatientService.deletePatient(id);
  res.status(result.success ? 200 : 404).json(result);
});

// Appointments Management API
app.get("/api/appointments", (req, res) => {
  const result = AppointmentService.getAllAppointments();
  res.status(result.success ? 200 : 404).json(result);
});

app.get("/api/appointments/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const result = AppointmentService.getAppointmentById(id);
  res.status(result.success ? 200 : 404).json(result);
});

app.post("/api/appointments", (req, res) => {
  const result = AppointmentService.createAppointment(req.body);
  res.status(result.success ? 201 : 400).json(result);
});

app.put("/api/appointments/:id/status", (req, res) => {
  const id = parseInt(req.params.id);
  const { status } = req.body;
  
  if (!status || !['pending', 'confirmed', 'cancelled', 'completed'].includes(status)) {
    return res.status(400).json({
      success: false,
      message: 'Status must be: pending, confirmed, cancelled, completed'
    });
  }

  const result = AppointmentService.updateAppointmentStatus(id, status);
  res.status(result.success ? 200 : 404).json(result);
});

app.get("/api/patients/:patientId/appointments", (req, res) => {
  const patientId = parseInt(req.params.patientId);
  const result = AppointmentService.getAppointmentByPatientId(patientId);
  res.status(result.success ? 200 : 400).json(result);
});

app.get("/api/appointments/date/:date", (req, res) => {
  const { date } = req.params;
  const result = AppointmentService.getAppointmentByDate(date);
  res.status(result.success ? 200 : 400).json(result);
});

// User Login API
app.post("/api/auth/login", (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Please provide email and password'
    });
  }
  
  const result = AuthService.login(email, password);
  res.status(result.success ? 200 : 401).json(result);
});

// User Registration API
app.post("/api/auth/register", (req, res) => {
  const { email, password, name, role } = req.body;
  
  if (!email || !password || !name) {
    return res.status(400).json({
      success: false,
      message: 'Please provide email, password, and name'
    });
  }
  
  const result = AuthService.register({ email, password, name, role });
  res.status(result.success ? 201 : 400).json(result);
});

// Data Statistics API
app.get("/api/stats", (req, res) => {
  const patients = PatientService.getAllPatients();
  const appointments = AppointmentService.getAllAppointments();
  const doctors = AuthService.getAllDoctors();
  
  const pendingAppointments = appointments.data.filter(
    a => a.status === 'pending'
  ).length;
  
  const completedAppointments = appointments.data.filter(
    a => a.status === 'completed'
  ).length;
  
  res.json({
    success: true,
    data: {
      totalPatients: patients.count,
      totalAppointments: appointments.count,
      pendingAppointments,
      completedAppointments,
      totalDoctors: doctors.count,
      recentPatients: patients.data.slice(-5).map(p => ({
        id: p.id,
        name: p.name,
        lastVisit: p.lastVisit
      })),
      systemStatus: "All systems operational",
      database: "In-memory storage (no persistent DB)",
      lastUpdated: new Date().toISOString()
    }
  });
});

// Initializing mock data (must be called manually)
app.post("/api/init-test-data", (req, res) => {
  const patientResult = PatientService.initializeTestData();
  const appointmentResult = AppointmentService.initTestData();
  
  res.json({
    success: true,
    message: "Test data initialized successfully",
    data: {
      patients: patientResult.count,
      appointments: appointmentResult.count,
      timestamp: new Date().toISOString()
    }
  });
});

// Get all doctors
app.get("/api/doctors", (req, res) => {
  const result = AuthService.getAllDoctors();
  res.status(result.success ? 200 : 400).json(result);
});

// Main page
app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>HealthTech Backend API</title>
        <style>
          body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px; 
            margin: 0 auto; 
            padding: 20px; 
            background: #f8f9fa; 
          }
          .header {
            background: linear-gradient(135deg, #39B27A 0%, #2E8B63 100%);
            color: white;
            padding: 40px;
            border-radius: 15px;
            margin-bottom: 30px;
          }
          .container { 
            background: white; 
            padding: 30px; 
            border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
          }
          h1 { color: white; margin: 0; }
          h2 { color: #39B27A; border-bottom: 2px solid #39B27A; padding-bottom: 10px; }
          .api-list { margin-top: 20px; }
          .api-group { margin-bottom: 30px; }
          .api-item { 
            background: #f9f9f9; 
            padding: 15px; 
            margin: 10px 0; 
            border-left: 5px solid #39B27A;
            border-radius: 5px;
            display: flex;
            align-items: center;
          }
          .method { 
            display: inline-block; 
            padding: 5px 10px; 
            border-radius: 4px; 
            font-weight: bold; 
            margin-right: 15px;
            min-width: 60px;
            text-align: center;
          }
          .get { background: #61affe; color: white; }
          .post { background: #49cc90; color: white; }
          .put { background: #fca130; color: white; }
          .delete { background: #f93e3e; color: white; }
          .endpoint { 
            font-family: 'Courier New', monospace; 
            font-size: 16px; 
            flex-grow: 1;
          }
          .test-btn { 
            background: #39B27A; 
            color: white; 
            border: none; 
            padding: 8px 15px; 
            border-radius: 5px; 
            cursor: pointer; 
            margin-left: 10px;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s;
          }
          .test-btn:hover { 
            background: #2E8B63; 
            transform: translateY(-2px);
          }
          .status-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: bold;
            margin-left: 10px;
          }
          .status-ready { background: #d4edda; color: #155724; }
          .note-box {
            background: #e8f5e9;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 5px solid #39B27A;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>🚀 HealthTech Backend API</h1>
          <p>The server is running on port ${PORT}</p>
          <p>Service Layer Architecture | In-Memory Storage | Switchable Database</p>
        </div>
        
        <div class="container">
          <div class="note-box">
            <h3>🎯 Backend Leader's Focused Plan</h3>
            <p>✅ <strong>Done: </strong>Complete API layer + service layer architecture</p>
            <p>🔧 <strong>Current use: </strong>In-Memory Storage (data lost on restart)</p>
            <p>🔄 <strong>Switch Ready: </strong>After database team decides, only service layer needs to be modified</p>
            <p>📡 <strong>Available for immediate frontend use: </strong>All APIs are ready</p>
          </div>
          
          <div class="api-group">
            <h2>📋 Patient Management API</h2>
            <div class="api-list">
              <div class="api-item">
                <span class="method get">GET</span>
                <span class="endpoint">/api/patients</span>
                <span class="status-badge status-ready">Ready</span>
                <a href="/api/patients" class="test-btn" target="_blank">Test</a>
              </div>
              <div class="api-item">
                <span class="method get">GET</span>
                <span class="endpoint">/api/patients/{id}</span>
                <span class="status-badge status-ready">Ready</span>
                <button class="test-btn" onclick="testGet('/api/patients/1')">Test</button>
              </div>
              <div class="api-item">
                <span class="method post">POST</span>
                <span class="endpoint">/api/patients</span>
                <span class="status-badge status-ready">Ready</span>
                <button class="test-btn" onclick="testPost('/api/patients', {name: 'Test Patient', age: 30})">Test</button>
              </div>
              <div class="api-item">
                <span class="method put">PUT</span>
                <span class="endpoint">/api/patients/{id}</span>
                <span class="status-badge status-ready">Ready</span>
                <button class="test-btn" onclick="testPut('/api/patients/1', {age: 31})">Test</button>
              </div>
              <div class="api-item">
                <span class="method delete">DELETE</span>
                <span class="endpoint">/api/patients/{id}</span>
                <span class="status-badge status-ready">Ready</span>
                <button class="test-btn" onclick="testDelete('/api/patients/1')">Test</button>
              </div>
            </div>
          </div>
          
          <div class="api-group">
            <h2>📅 Appointment Management API</h2>
            <div class="api-list">
              <div class="api-item">
                <span class="method get">GET</span>
                <span class="endpoint">/api/appointments</span>
                <a href="/api/appointments" class="test-btn" target="_blank">Test</a>
              </div>
              <div class="api-item">
                <span class="method post">POST</span>
                <span class="endpoint">/api/appointments</span>
                <button class="test-btn" onclick="testPost('/api/appointments', {patientId: 1, date: '2024-01-25'})">Test</button>
              </div>
              <div class="api-item">
                <span class="method put">PUT</span>
                <span class="endpoint">/api/appointments/{id}/status</span>
                <button class="test-btn" onclick="testPut('/api/appointments/1/status', {status: 'confirmed'})">Test</button>
              </div>
            </div>
          </div>
          
          <div class="api-group">
            <h2>🔐 Authentication API</h2>
            <div class="api-list">
              <div class="api-item">
                <span class="method post">POST</span>
                <span class="endpoint">/api/auth/login</span>
                <button class="test-btn" onclick="testPost('/api/auth/login', {email: 'doctor@healthtech.com', password: 'password123'})">Test</button>
              </div>
              <div class="api-item">
                <span class="method post">POST</span>
                <span class="endpoint">/api/auth/register</span>
                <button class="test-btn" onclick="testPost('/api/auth/register', {email: 'test@example.com', password: '123456', name: 'Test User'})">Test</button>
              </div>
            </div>
          </div>
          
          <div class="api-group">
            <h2>📊 System API</h2>
            <div class="api-list">
              <div class="api-item">
                <span class="method get">GET</span>
                <span class="endpoint">/api/health</span>
                <a href="/api/health" class="test-btn" target="_blank">Test</a>
              </div>
              <div class="api-item">
                <span class="method get">GET</span>
                <span class="endpoint">/api/stats</span>
                <a href="/api/stats" class="test-btn" target="_blank">Test</a>
              </div>
              <div class="api-item">
                <span class="method post">POST</span>
                <span class="endpoint">/api/init-test-data</span>
                <button class="test-btn" onclick="testPost('/api/init-test-data', {})">Initialize Data</button>
              </div>
            </div>
          </div>
          
          <div class="note-box">
            <h3>📚 Instructions for Frontend Teammates</h3>
            <p><strong>API Base URL:</strong> <code>http://localhost:${PORT}</code></p>
            <p><strong>Suggested Steps:</strong></p>
            <ol>
              <li>First, run <code>POST /api/init-test-data</code> to initialize test data</li>
              <li>Use <code>POST /api/auth/login</code> to get a mock token</li>
              <li>All patient and appointment APIs are now available</li>
              <li>Use <code>GET /api/health</code> to check server status</li>
            </ol>
          </div>
        </div>
        
        <script>
          async function testGet(url) {
            try {
              const response = await fetch(url);
              const result = await response.json();
              alert(JSON.stringify(result, null, 2));
            } catch (error) {
              alert('Request failed: ' + error.message);
            }
          }
          
          async function testPost(url, data) {
            try {
              const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
              });
              const result = await response.json();
              alert(JSON.stringify(result, null, 2));
            } catch (error) {
              alert('Request failed: ' + error.message);
            }
          }
          
          async function testPut(url, data) {
            try {
              const response = await fetch(url, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
              });
              const result = await response.json();
              alert(JSON.stringify(result, null, 2));
            } catch (error) {
              alert('Request failed: ' + error.message);
            }
          }
          
          async function testDelete(url) {
            try {
              const response = await fetch(url, { method: 'DELETE' });
              const result = await response.json();
              alert(JSON.stringify(result, null, 2));
            } catch (error) {
              alert('Request failed: ' + error.message);
            }
          }
        </script>
      </body>
    </html>
  `);
});

module.exports = app;

// Starting Server
app.listen(PORT, () => {
  console.log("========================================");
  console.log("✅ Backend server started successfully!");
  console.log("📍 Local Host: http://localhost:" + PORT);
  console.log("📡 API Health Check: http://localhost:" + PORT + "/api/health");
  console.log("🔧 Development command: npm run dev");
  console.log("🎯 Frontend Local Host: http://localhost:5173");
  console.log("========================================");
});
