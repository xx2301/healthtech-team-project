const cron = require('node-cron');
const User = require('../models/User');
const HealthMetric = require('../models/HealthMetric');

const isTestUser = (user) => {
  return user.email && user.email.includes('test');
};

 async function generateLiveDataForUser(user) {
  const now = new Date();
  const metrics = [];

// 1. Heart rate (one per minute, consistent with real monitoring)
// Access medical records (available to doctors and admin)
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

  // 2. Steps (steps per minute, simulating real walking, e.g., 0-20 steps/minute)
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
    isAbnormal: stepsDelta > 100, // impossible
  });

  // 3. Calories (calories burned per minute, approximately 1-5 kcal/minute)
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

  // 4. Blood Glucose (optional, generating every minute is not very realistic, 
  // but for demonstration purposes it can be random)
  const glucose = 4.0 + Math.random() * 3.0; // 4-7 mmol/L
  metrics.push({
    userId: user._id,
    patientId: null,
    metricType: 'blood_glucose',
    value: glucose,
    unit: 'mmol/L',
    source: 'device',
    deviceName: 'CGM',
    timestamp: now,
    isAbnormal: glucose < 3.5 || glucose > 7.8,
  });

// 5. Blood Pressure (example: 110/70 mmhg)
  const systolic = 110 + Math.floor(Math.random() * 20); // 110-130 mmHg
  const diastolic = 70 + Math.floor(Math.random() * 10);  // 70-80 mmHg
  metrics.push({
    userId: user._id,
    patientId: null,
    metricType: 'blood_pressure',
    value: { systolic, diastolic },
    unit: 'mmHg',
    source: 'device',
    deviceName: 'BP Monitor',
    timestamp: now,
    isAbnormal: systolic > 140 || systolic < 90 || diastolic > 90 || diastolic < 60,
  });

  // 6. Sleep Duration (simulate sleep data every minute, which is not realistic but for demonstration)
  const sleepIncrement = Math.random() * 0.5; // 0-0.5hrs
  metrics.push({
    userId: user._id,
    patientId: null,
    metricType: 'sleep_duration',
    value: sleepIncrement,
    unit: 'hours',
    source: 'device',
    deviceName: 'Sleep Tracker',
    timestamp: now,
    isAbnormal: false,
  });

  // Batch insert (ignore duplicate key and other errors)
  try {
    await HealthMetric.create(metrics);
    console.log(`[AutoSimulate] Inserted ${metrics.length} metrics for user ${user.email}`);
  } catch (error) {
    console.error(`[AutoSimulate] Failed for user ${user.email}:`, error.message);
  }
}

// Generate real-time data for all test users
async function generateLiveDataForAllTestUsers() {
  try {
    const testUsers = await User.find({});
    
    for (const user of testUsers) {
      await generateLiveDataForUser(user);
    }
    console.log(`[AutoSimulate] Completed run at ${new Date().toISOString()}`);
  } catch (error) {
    console.error('[AutoSimulate] Error:', error);
  }
}

function startAutoSimulate() {
  cron.schedule('* * * * *', async () => {
    console.log('Running auto-simulate task...');
    await generateLiveDataForAllTestUsers();
  });
  console.log('Auto-simulate cron job scheduled (every minute).');
}

module.exports = { startAutoSimulate };