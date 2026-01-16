import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';

const testAPI = async () => {
  try {
    const res = await fetch("http://localhost:3001/api/health");
    const data = await res.json();
    alert("✅ Backend connected!\n\n" + JSON.stringify(data, null, 2));
  } catch (err) {
    alert("❌ Backend connection failed");
  }
};

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <div style={{
      padding: '40px',
      textAlign: 'center',
      fontFamily: 'Arial, sans-serif'
    }}>
      <h1 style={{ color: '#39B27A' }}>🏥 HealthTech Frontend</h1>
      <p>Frontend teammate, please start your development here!</p>
      <p>Backend API address: <code>http://localhost:3001</code></p>
      <p>Check <code>FRONTEND_GUIDE.md</code> for detailed instructions</p>

      <button 
        style={{
          marginTop: '20px',
          padding: '10px 20px',
          background: '#39B27A',
          color: 'white',
          border: 'none',
          borderRadius: '5px',
          cursor: 'pointer'
        }}
        onClick={testAPI}
      >
        🧪 Testing API connection
      </button>
    </div>
  </React.StrictMode>
);


