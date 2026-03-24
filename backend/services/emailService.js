const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

exports.sendPasswordResetEmail = async (email, token) => {
  const resetUrl = `http://localhost:3001/reset-password?token=${token}`;
  const mailOptions = {
    from: `"HealthTech Team" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Password Reset Request',
    html: `<p>You requested a password reset. Use the token below to reset your password in the app:</p>
           <h3>${token}</h3>
           <p>Or click the link: <a href="${resetUrl}">${resetUrl}</a></p>
           <p>This token expires in 1 hour.</p>
           <p>If you didn't request this, please ignore this email.</p>`,
  };
  await transporter.sendMail(mailOptions);
};
