const urlParams = new URLSearchParams(window.location.search);
const token = urlParams.get('token');

const tokenInfo = document.getElementById('tokenInfo');
const resetFormDiv = document.getElementById('resetForm');
const messageDiv = document.getElementById('message');
const newPasswordInput = document.getElementById('newPassword');
const confirmInput = document.getElementById('confirmPassword');
const resetBtn = document.getElementById('resetBtn');

if (!token) {
  tokenInfo.textContent = 'Error: Missing token. Please use the link from your email.';
  resetFormDiv.style.display = 'none';
} else {
  tokenInfo.textContent = 'Token found. Please enter your new password.';
}

resetBtn.addEventListener('click', async (e) => {
  e.preventDefault();

  const newPassword = newPasswordInput.value.trim();
  const confirmPassword = confirmInput.value.trim();

  messageDiv.innerHTML = '';

  if (newPassword !== confirmPassword) {
    messageDiv.innerHTML = '<div style="color:red;">Passwords do not match!</div>';
    return;
  }

  if (newPassword.length < 6) {
    messageDiv.innerHTML = '<div style="color:red;">Password must be at least 6 characters.</div>';
    return;
  }

  resetBtn.disabled = true;
  messageDiv.innerHTML = '<div>Resetting password...</div>';

  try {
    const response = await fetch('/api/auth/reset-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token, newPassword })
    });

    const data = await response.json();

    if (response.ok) {
      messageDiv.innerHTML = `<div style="color:green;">${data.message || 'Password reset successful'}</div>`;
      newPasswordInput.value = '';
      confirmInput.value = '';
    } else {
      messageDiv.innerHTML = `<div style="color:red;">${data.error || 'Reset failed'}</div>`;
      resetBtn.disabled = false;
    }
  } catch (err) {
    console.error('Fetch error:', err);
    messageDiv.innerHTML = `<div style="color:red;">Network error: ${err.message}</div>`;
    resetBtn.disabled = false;
  }
});