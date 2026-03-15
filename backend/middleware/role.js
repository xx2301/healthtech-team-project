const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    
    const userRole = req.user.role || req.user.userType;
    if (!roles.includes(userRole)) {
      return res.status(403).json({ 
        success: false, 
        error: `Required role: ${roles.join(' or ')}` 
      });
    }
    next();
  };
};

module.exports = { requireRole };