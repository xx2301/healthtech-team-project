const createActivityLog = (data) => {
  console.log('[ActivityLog]', new Date().toISOString(), data);
};

module.exports = { createActivityLog };