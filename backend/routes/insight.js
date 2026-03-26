const express = require('express');
const router = express.Router();
const axios = require('axios');
const authMiddleware = require('../middleware/auth');

const AI_API_URL = 'https://api.openai.com/v1/chat/completions';
const AI_MODEL = 'gpt-4o';
const AI_API_KEY = process.env.AI_API_KEY;

router.post('/weekly-insight', authMiddleware, async (req, res) => {
  try {
    const { stepsTotal, stepsGoal, stepsChangePercent, sleepTotal, sleepGoal, sleepChangePercent, waterTotal, waterGoal, waterChangePercent, avgHeartRate } = req.body;

    const prompt = `
      You are a friendly health coach. Based on the user's weekly data, give a short, encouraging insight (2–3 sentences):
      - Steps this week: ${stepsTotal} (goal: ${stepsGoal * 7} steps, change: ${stepsChangePercent > 0 ? '+' : ''}${stepsChangePercent}%)
      - Sleep: ${sleepTotal} hours (goal: ${sleepGoal * 7} hours, change: ${sleepChangePercent > 0 ? '+' : ''}${sleepChangePercent}%)
      - Water: ${waterTotal} ml (goal: ${waterGoal * 7} ml, change: ${waterChangePercent > 0 ? '+' : ''}${waterChangePercent}%)
      - Average heart rate: ${avgHeartRate} bpm (normal 60–100)
      Provide positive feedback and one actionable tip. Keep it concise.
    `;

    const requestBody = {
      model: AI_MODEL,
      messages: [
        { role: 'system', content: 'You are a helpful health coach.' },
        { role: 'user', content: prompt }
      ],
      max_tokens: 150,
      temperature: 0.7,
    };

    const response = await axios.post(AI_API_URL, requestBody, {
      headers: {
        'Authorization': `Bearer ${AI_API_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    const insight = response.data.choices?.[0]?.message?.content?.trim();
    if (!insight) throw new Error('No insight returned');

    res.json({ success: true, insight });
  } catch (error) {
    console.error('AI insight error:', error);
    res.json({ success: false, insight: 'Keep up your healthy habits this week! 🌟' });
  }
});

module.exports = router;