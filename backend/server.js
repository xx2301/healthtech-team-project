const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// Main page
app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>HealthTech Backend API</title>
        <style>
          body { font-family: Arial; max-width: 1000px; margin: 50px auto; padding: 20px; background: #f5f5f5; }
          .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          h1 { color: #39B27A; }
          .api-list { margin-top: 20px; }
          .api-item { 
            background: #f9f9f9; 
            padding: 15px; 
            margin: 10px 0; 
            border-left: 5px solid #39B27A;
            border-radius: 5px;
          }
          .method { 
            display: inline-block; 
            padding: 5px 10px; 
            border-radius: 4px; 
            font-weight: bold; 
            margin-right: 10px;
          }
          .get { background: #61affe; color: white; }
          .post { background: #49cc90; color: white; }
          .endpoint { font-family: monospace; font-size: 16px; }
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
          }
          .test-btn:hover { background: #2E8B63; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 HealthTech Backend API</h1>
          <p>The server is running on port ${PORT}</p>
          <p>Frontend running on: <a href="http://localhost:5173" target="_blank">http://localhost:5173</a></p>
          
          <div class="api-list">
            <h3>Available API endpoints:</h3>
            
            <div class="api-item">
              <span class="method get">GET</span>
              <span class="endpoint">/api/health</span> - Health check endpoint
              <a href="/api/health" class="test-btn" target="_blank">Test</a>
            </div>
            
            <div class="api-item">
              <span class="method get">GET</span>
              <span class="endpoint">/api/patients</span> - Get patients list
              <a href="/api/patients" class="test-btn" target="_blank">Test</a>
            </div>
            
            <div class="api-item">
              <span class="method post">POST</span>
              <span class="endpoint">/api/patients</span> - Create new patient
              <button class="test-btn" onclick="testPost('/api/patients', {name: 'Test Patient', age: 30})">Test</button>
            </div>
            
            <div class="api-item">
              <span class="method get">GET</span>
              <span class="endpoint">/api/appointments</span> - Get appointments list
              <a href="/api/appointments" class="test-btn" target="_blank">Test</a>
            </div>
            
            <div class="api-item">
              <span class="method post">POST</span>
              <span class="endpoint">/api/appointments</span> - Create new appointment
              <button class="test-btn" onclick="testPost('/api/appointments', {patientId: 1, date: '2024-01-20'})">Test</button>
            </div>
            
            <div class="api-item">
              <span class="method post">POST</span>
              <span class="endpoint">/api/auth/login</span> - User Login
              <button class="test-btn" onclick="testPost('/api/auth/login', {email: 'doctor@healthtech.com', password: 'password123'})">Test</button>
            </div>
            
            <div class="api-item">
              <span class="method get">GET</span>
              <span class="endpoint">/api/stats</span> - Get statistics data
              <a href="/api/stats" class="test-btn" target="_blank">Test</a>
            </div>
            
            <div class="api-item">
              <span class="method post">POST</span>
              <span class="endpoint">/api/init-test-data</span> - Initialize test data
              <button class="test-btn" onclick="testPost('/api/init-test-data', {})">Initialize</button>
            </div>
          </div>
          
          <div style="margin-top: 30px; padding: 20px; background: #f0f9f4; border-radius: 8px;">
            <h3>📚 Message for the frontend team:</h3>
            <p>All APIs are ready; you can start front-end development!</p>
            <p>API base URL: <code>http://localhost:3001</code></p>
            <p>It is recommended to run <code>POST /api/init-test-data</code> first to initialize test data.</p>
          </div>
        </div>
        
        <script>
          async function testPost(endpoint, data) {
            try {
              const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
              });
              
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

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    message: "The backend server is running",
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

// Storage (In-memory for development, if needed later can switch to database)
let patients = [];
let appointments = [];
let users = [{
  id: 1,
  email:"doctor@healthtech.com",
  password:"password123",
  name:"Dr. Smith",
  role:"doctor"
}];

// Patients Management API
app.get("/api/patients", (req, res) => {
  res.json({
    success: true,
    message: "Patients retrieved successfully",
    count: patients.length,
    data: patients
  });
});

app.post("/api/patients", (req, res) => {
  const newPatient = {
    id: patients.length + 1,
    ...req.body,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  patients.push(newPatient);

  res.json({
    success: true,
    message: "Patient added successfully",
    data: newPatient
  });
});

// Get Patients by ID
app.get("/api/patients/:id", (req, res) => {
  const patientId = parseInt(req.params.id);
  const patient = patients.find(p => p.id === patientId);

  if (patient) {
    res.json({
      success: true,
      message: "Patient retrieved successfully",
      data: patient
    });
  } else {
    res.status(404).json({
      success: false,
      message: "Patient not found"
    });
  }
});

// Appointments Management API
app.get("/api/appointments", (req, res) => {
  res.json({
    success: true,
    message: "Appointments retrieved successfully",
    count: appointments.length,
    data: appointments
  });
});

app.post("/api/appointments", (req, res) => {
  const newAppointment = {
    id: appointments.length + 1,
    ...req.body,
    status: "pending",
    createdAt: new Date().toISOString()
  };
  appointments.push(newAppointment);

  res.json({
    success: true,
    message: "Appointment created successfully",
    data: newAppointment
  });
});

// User Login API (Mocked for development)
app.post("/api/auth/login", (req, res) => {
  const { email, password } = req.body;
  
  // Find user
  const user = users.find(u => u.email === email && u.password === password);

  if (user) {
    const { password, ...userWithoutPassword } = user; // Exclude password from response

    res.json({
      success: true,
      message: "Login successful",
      user: userWithoutPassword,
      token: "mock-jwt-token-for-"
    });
  } else {
    res.status(401).json({
      success: false,
      message: "Invalid email or password"
    });
  }
});

// User Registration API (Mocked for development)
app.post("/api/auth/register", (req, res) => {
  const { email, password, name, role } = req.body;

  // Check if user already exists
  const existingUser = users.find(u => u.email === email);
  if (existingUser) {
    return res.status(400).json({
      success: false,
      message: "User already exists"
    });
  }

  const newUser = {
    id: users.length + 1,
    email,
    password,
    name,
    role: "user",
    createdAt: new Date().toISOString()
  };
  users.push(newUser);

  const { password: _, ...userWithoutPassword } = newUser; // Exclude password from response

  res.json({
    success: true,
    message: "Registration successful",
    user: userWithoutPassword
  });
});

// Data Statistics API (Mocked for development)
app.get("/api/stats", (req, res) => {
  res.json({
    success: true,
    message: "Statistics retrieved successfully",
    data: {
      totalPatients: patients.length,
      totalAppointments: appointments.length,
      pendingAppointments: appointments.filter(a => a.status === "pending").length,
      completedAppointments: appointments.filter(a => a.status === "completed").length,
      recentPatients: patients.slice(-5).map(p => ({ id: p.id, name: p.name })),
      systemStatus: "All systems operational",
      lastUpdated: new Date().toISOString()
    }
  });
});

// Initializing some mock data for development
app.post("/api/init-test-data", (req, res) => {
  // Clear existing data
  patients = [];
  appointments = [];

  // Add mock patients
  const testPatients = [{
    id: 1,
      name: "Zhang Wei",
      age: 45,
      gender: "male",
      condition: "Hypertension",
      contact: "13800138001",
      address: "Beijing Chaoyang District",
      lastVisit: "2024-01-15",
      status: "stable"
    },
    {
      id: 2,
      name: "Lee Fang",
      age: 32,
      gender: "female",
      condition: "Diabetes",
      contact: "13800138002",
      address: "Shanghai Pudong New District",
      lastVisit: "2024-01-10",
      status: "monitoring"
    },
    {
      id: 3,
      name: "Jerry Tan",
      age: 28,
      gender: "male",
      condition: "Flu",
      contact: "123642778",
      address: "Kuala Lumpur, Malaysia",
      lastVisit: "2024-01-05",
      status: "recovering"
    }
  ];

  // Add mock appointments
  const testAppointments = [
    {
      id: 1,
      patientId: 1,
      patientName: "Zhang Wei",
      doctorId: 1,
      doctorName: "Doctor Chong",
      date: "2024-01-20",
      time: "09:00",
      reason: "Regular check-up",
      status: "pending"
    },
    {
      id: 2,
      patientId: 2,
      patientName: "Lee Fang",
      doctorId: 1,
      doctorName: "Doctor Chong",
      date: "2024-01-20",
      time: "10:30",
      reason: "Blood sugar follow-up",
      status: "pending"
    }
  ];
  
  patients.push(...testPatients);
  appointments.push(...testAppointments);

  res.json({
    success: true,
    message: "Mock data initialized",
    patientsAdded: testPatients.length,
    appointmentsAdded: testAppointments.length
  });
});

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
