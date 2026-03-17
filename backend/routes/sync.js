const express = require('express');
const router = express.Router();
const Device = require('../models/Device');
const HealthMetric = require('../models/HealthMetric');
const authenticateToken = require('../middleware/auth');
const Threshold = require('../models/Threshold');
const Notification = require('../models/Notification');

const metricTypeSynonyms = {
  'steps': 'steps',
  'step': 'steps',

  'heart_rate': 'heart_rate',
  'heart': 'heart_rate',
  'hr': 'heart_rate',

  'calories': 'calories_burned',
  'calorie': 'calories_burned',
  'kcal': 'calories_burned',

  'sleep': 'sleep_duration',
  'sleep_duration': 'sleep_duration',
  'sleepduration': 'sleep_duration',

  'glucose': 'blood_glucose',
  'blood_glucose': 'blood_glucose',
  'blood glucose': 'blood_glucose',

  'blood_pressure': 'blood_pressure',
  'bp': 'blood_pressure',
  // can add more synonyms as needed
};

function normalizeMetricType(input) {
  if (!input) return null;
  const lower = input.trim().toLowerCase();
  return metricTypeSynonyms[lower] || lower;
}

router.post('/:deviceId', authenticateToken, async (req, res) => {
  try {
    const deviceId = req.params.deviceId;
    const userId = req.user.userId;

    const device = await Device.findOne({ _id: deviceId, userId });
    if (!device) {
      return res.status(404).json({ success: false, error: 'Device not found or access denied' });
    }

    const now = new Date();
    const mockData = generateMockData(device.type, device._id, userId);

    if (mockData.length > 0) {
      await HealthMetric.create(mockData);

      for (const metric of mockData) {
        await checkThresholdAndNotify(metric);
      }
    }

    device.lastSyncAt = now;
    await device.save();

    res.json({
      success: true,
      message: 'Device synced successfully',
      data: {
        deviceId: device._id,
        lastSyncAt: device.lastSyncAt,
        metricsGenerated: mockData.length
      }
    });
  } catch (error) {
    console.error('Sync error:', error);
    res.status(500).json({ success: false, error: 'Sync failed' });
  }
});

async function checkThresholdAndNotify(metric) {
  try {
    const userId = metric.userId;
    const metricType = metric.metricType;
    const value = metric.value;

    const threshold = await Threshold.findOne({ userId, metricType, enabled: true });
    if (!threshold) return;

    let exceeded = false;
    let message = '';

    if (metricType === 'blood_pressure' && typeof value === 'object') {
      const systolic = value.systolic;
      const diastolic = value.diastolic;
      if (threshold.maxThreshold && systolic > threshold.maxThreshold) {
        exceeded = true;
        message = `Systolic blood pressure ${systolic} exceeds maximum ${threshold.maxThreshold}`;
      } else if (threshold.minThreshold && systolic < threshold.minThreshold) {
        exceeded = true;
        message = `Systolic blood pressure ${systolic} below minimum ${threshold.minThreshold}`;
      } else if (threshold.maxThreshold && diastolic > threshold.maxThreshold) {
        exceeded = true;
        message = `Diastolic blood pressure ${diastolic} exceeds maximum ${threshold.maxThreshold}`;
      } else if (threshold.minThreshold && diastolic < threshold.minThreshold) {
        exceeded = true;
        message = `Diastolic blood pressure ${diastolic} below minimum ${threshold.minThreshold}`;
      }
    } else {
      if (threshold.maxThreshold && value > threshold.maxThreshold) {
        exceeded = true;
        message = `${metricType} value ${value} exceeds maximum ${threshold.maxThreshold}`;
      } else if (threshold.minThreshold && value < threshold.minThreshold) {
        exceeded = true;
        message = `${metricType} value ${value} below minimum ${threshold.minThreshold}`;
      }
    }

    if (exceeded) {
      await Notification.create({
        userId,
        type: 'threshold_alert',
        title: 'Health Alert',
        message,
        data: {
          metricType,
          value,
          threshold: threshold.maxThreshold || threshold.minThreshold,
          deviceId: metric.deviceId,
          timestamp: metric.timestamp
        }
      });
    }
  } catch (err) {
    console.error('Threshold check error:', err);
  }
}

function generateMockData(deviceType, deviceId, userId) {
  const normalizedType = normalizeMetricType(deviceType);
  if (!normalizedType) return [];

  const validTypes = [
    'steps', 'heart_rate', 'blood_pressure', 'blood_glucose',
    'weight', 'height', 'bmi', 'body_temperature',
    'oxygen_saturation', 'sleep_duration', 'calories_burned',
    'water_intake', 'respiratory_rate'
  ];
  if (!validTypes.includes(normalizedType)) {
    console.warn(`Unrecognized metric type: ${deviceType} -> ${normalizedType}`);
    return [];
  }

  const now = new Date();
  const mockMetrics = [];
  const count = 5; // generate 5 datas

  for (let i = 0; i < count; i++) {
    const timestamp = new Date(now.getTime() - i * 60000);
    let value;
    let unit = '';

    switch (normalizedType) {
      case 'steps':
        value = Math.floor(Math.random() * 200) + 50;
        unit = 'steps';
        break;
      case 'heart_rate':
        value = Math.floor(Math.random() * 40) + 60;
        unit = 'bpm';
        break;
      case 'calories_burned':
        value = Math.floor(Math.random() * 10) + 5;
        unit = 'kcal';
        break;
      case 'sleep_duration':
        value = (Math.random() * 2 + 6).toFixed(1);
        value = parseFloat(value);
        unit = 'hours';
        break;
      case 'blood_glucose':
        value = (Math.random() * 2 + 4).toFixed(1);
        value = parseFloat(value);
        unit = 'mg/dL';
        break;
      case 'blood_pressure':
        value = {
          systolic: Math.floor(Math.random() * 30) + 110,
          diastolic: Math.floor(Math.random() * 20) + 70
        };
        unit = 'mmHg';
        break;
      default:
        // If the type is not supported, skip this data 
        // (but it has already been verified above, so this should not be executed here)
        continue;
    }

    mockMetrics.push({
      userId,
      deviceId,
      metricType: normalizedType,
      value,
      unit,
      timestamp,
      source: 'device',
      qualityScore: 100,
      isAbnormal: false,
      isVerified: false
    });
  }

  return mockMetrics;
}

module.exports = router;