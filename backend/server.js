const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>HealthTech Backend API</title>
        <style>
          body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; background: #f5f5f5; }
          .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          h1 { color: #39B27A; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 HealthTech Backend API</h1>
          <p>The server is running on port ${PORT}</p>
          <p>API endpoint: </p>
          <ul>
            <li><strong>GET /</strong> - Main</li>
            <li><strong>GET /api/health</strong> - Health Check</li>
          </ul>
        </div>
      </body>
    </html>
  `);
});

app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    message: "The backend server is running",
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log("========================================");
  console.log("✅ Backend server started successfully!");
  console.log("📍 Local Host: http://localhost:" + PORT);
  console.log("📡 API Health Check: http://localhost:" + PORT + "/api/health");
  console.log("🔧 Development command: npm run dev");
  console.log("🎯 Frontend Local Host: http://localhost:5173");
  console.log("========================================");
});
