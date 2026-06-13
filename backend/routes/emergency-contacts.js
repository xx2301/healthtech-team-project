const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const EmergencyContact = require('../models/EmergencyContact');
const Patient = require('../models/patient');
const authenticateToken = require('../middleware/auth');
const { requireRole } = require('../middleware/role');

router.post('/', authenticateToken, requireRole('patient'), [
  body('fullName').notEmpty().trim(),
  body('relationship').isIn([
    'spouse', 'parent', 'child', 'sibling',
    'friend', 'relative', 'caregiver', 'other'
  ]),
  body('phoneNum').isMobilePhone(),
  body('email').optional().isEmail(),
  body('isPrimary').optional().isBoolean()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  try {
    const {
      fullName,
      relationship,
      phoneNum,
      email,
      address,
      isPrimary = false,
      notiEnabled = true,
      preferredContactMethod = 'phone'
    } = req.body;
    
    const emergencyContact = new EmergencyContact({
      patientId: req.user._id,
      fullName,
      relationship,
      phoneNum,
      email,
      address,
      isPrimary,
      notiEnabled,
      preferredContactMethod
    });
    
    await emergencyContact.save();
    
    await Patient.findByIdAndUpdate(
      req.user._id,
      { $push: { emergencyContacts: emergencyContact._id } }
    );
    
    res.status(201).json({
      success: true,
      message: 'Emergency contact added successfully',
      data: emergencyContact
    });
    
  } catch (error) {
    console.error('Add emergency contact error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add emergency contact'
    });
  }
}); 

module.exports = router;