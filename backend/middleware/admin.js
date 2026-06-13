const requireAdmin = (req, res, next) => {
  if (!req.user || (req.user.userType !== 'admin' && !['super_admin', 'admin', 'moderator'].includes(req.user.role))) {
    return res.status(403).json({ 
      success: false, 
      error: 'Admin access required' 
    });
  }
  next();
};

module.exports = requireAdmin;