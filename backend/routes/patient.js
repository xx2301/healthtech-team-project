const express = require('express');
const router = express.Router();
const Patient = require('../models/patient');
const User = require('../models/User');
const Doctor = require('../models/doctor');
const EmergencyContact = require('../models/EmergencyContact');
const auth = require('../middleware/auth');
const role = require('../middleware/role');
const mongoose = require('mongoose');

router.delete('/:id', auth, role(['admin', 'super_admin']), async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const patientIdRaw = req.params.id;
    console.log('[DELETE] 原始ID:', patientIdRaw);
    console.log('[DELETE] ID长度:', patientIdRaw.length);
    console.log('[DELETE] ID字符编码:', patientIdRaw.split('').map(c => c.charCodeAt(0)));

    const patientId = patientIdRaw.trim();

    let objectId;
    try {
      objectId = new mongoose.Types.ObjectId(patientId);
    } catch (err) {
      console.log('[DELETE] 无效的ObjectId格式');
      await session.abortTransaction();
      return res.status(400).json({ message: 'Invalid patient ID format' });
    }

    let patient = await Patient.findById(objectId).session(session);
    console.log('[DELETE] findById结果:', patient ? '找到' : '未找到');

    if (!patient) {
      patient = await Patient.findById(objectId).bypassMiddleware().session(session);
      console.log('[DELETE] bypassMiddleware结果:', patient ? '找到' : '未找到');
    }

    if (!patient) {
      patient = await Patient.findOne({ _id: objectId, deletedAt: { $ne: null } }).session(session);
      console.log('[DELETE] 查找已删除结果:', patient ? '找到' : '未找到');
    }

    if (!patient) {
      await session.abortTransaction();
      return res.status(404).json({ message: 'Patient not found' });
    }

    if (patient.deletedAt) {
      await session.commitTransaction();
      return res.json({ message: 'Patient already deleted', patientId: patient._id });
    }

    patient.deletedAt = new Date();
    await patient.save({ session });

    await User.findByIdAndUpdate(patient.userId, { patientProfileId: null }, { session });

    await Doctor.updateMany(
      { assignedPatients: patientId },
      { $pull: { assignedPatients: patientId } },
      { session }
    );

    if (patient.emergencyContacts && patient.emergencyContacts.length > 0) {
      await EmergencyContact.updateMany(
        { _id: { $in: patient.emergencyContacts } },
        { deletedAt: new Date() },
        { session }
      );
    }

    await session.commitTransaction();
    res.json({ message: 'Patient deleted successfully', patientId: patient._id });
  } catch (err) {
    await session.abortTransaction();
    console.error('Delete patient error:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  } finally {
    session.endSession();
  }
});

module.exports = router;