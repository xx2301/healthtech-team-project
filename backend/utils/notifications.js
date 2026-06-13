const Notification = require('./models/Notification');

async function createNotification(userId, type, title, message, data = {}) {
  try {
    const notification = new Notification({
      userId,
      type,
      title,
      message,
      data
    });
    await notification.save();
  } catch (err) {
    console.error('Failed to create notification:', err);
  }
}

module.exports = { createNotification }