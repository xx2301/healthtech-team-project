const express = require('express');
const router = express.Router();
const axios = require('axios');
const authMiddleware = require('../middleware/auth');

const AI_API_URL = 'https://api.openai.com/v1/chat/completions';
const AI_MODEL = 'gpt-4o';
const AI_API_KEY = process.env.AI_API_KEY;

router.post('/message', authMiddleware, async (req, res) => {
  try {
    const { message, healthData } = req.body;
    if (!message) return res.status(400).json({ error: 'Message required' });

    let systemPrompt = 'You are a friendly and encouraging health coach. Keep your replies very short, 1-2 sentences maximum. Avoid repeating the same words or phrases. Be concise and helpful.';
    if (healthData) {
    const { steps, stepsGoal, avgHeartRate, calories, sleep } = healthData;
    systemPrompt += ` Today's data: Steps: ${steps || 0}/${stepsGoal || 6700}, Heart rate: ${avgHeartRate || 0} bpm, Calories: ${calories || 0} kcal, Sleep: ${sleep || 0} hours.`;
    }
    systemPrompt += ' Keep answers short, positive, and actionable.';

    const response = await axios.post(
      AI_API_URL,
      {
        model: AI_MODEL,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: message }
        ],
        max_tokens: 100,
        temperature: 0.7,
      },
      {
        headers: {
          'Authorization': `Bearer ${AI_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const reply = response.data.choices[0]?.message?.content?.trim();
    if (!reply) throw new Error('No reply from AI');

    res.json({ success: true, reply });
  } catch (error) {
    console.error('Chatbot AI error:', error);
    res.json({ success: false, reply: "I'm having trouble connecting right now. Please try again later!" });
  }
});

module.exports = router;