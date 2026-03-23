const express = require('express');
const router = express.Router();
const Appointment = require('../models/Appointment');
const Patient = require('../models/patient');
const Doctor = require('../models/doctor');
const User = require('../models/User');
const DoctorPatientRelation = require('../models/DoctorPatientRelation');
const Notification = require('../models/Notification');
const authenticateToken = require('../middleware/auth');
const { requireRole } = require('../middleware/role');

async function createNotification(userId, type, title, message, data = {}) {
  try {
    const notification = new Notification({
      userId,
      type,
      title,
      message,
      data,
    });
    await notification.save();
  } catch (err) {
    console.error('Failed to send notification:', err);
  }
}

router.get('/patient/:patientId/last', authenticateToken, async (req, res) => {
  try {
    const appointment = await Appointment.findOne({ patientId: req.params.patientId })
      .sort({ date: -1 })
      .select('date');
    res.json({ success: true, data: appointment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/my', authenticateToken, requireRole('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ userId: req.user.userId });
    if (!patient) return res.status(404).json({ success: false, error: 'Patient not found' });
    const appointments = await Appointment.find({ patientId: patient._id }).sort({ date: -1 });
    res.json({ success: true, data: appointments });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/doctor', authenticateToken, requireRole('doctor'), async (req, res) => {
  try {
    const doctorUser = await User.findById(req.user.userId);
    if (!doctorUser || !doctorUser.doctorProfileId) {
      return res.status(400).json({ success: false, error: 'Doctor profile not found' });
    }
    const doctorId = doctorUser.doctorProfileId;
    const appointments = await Appointment.find({ doctorId })
      .populate({
        path: 'patientId',
        populate: { path: 'userId', select: 'fullName' }
      })
      .sort({ date: -1 });
    const result = appointments.map(apt => ({
      _id: apt._id,
      patientName: apt.patientId?.userId?.fullName || 'Unknown',
      date: apt.date,
      time: apt.time,
      reason: apt.reason,
      status: apt.status,
    }));
    res.json({ success: true, data: result });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Failed to fetch appointments' });
  }
});

router.post('/', authenticateToken, async (req, res) => {
  const user = await User.findById(req.user.userId);
  if (!user) return res.status(401).json({ success: false, error: 'Unauthorized' });

  let doctorId, patientId, status;
  let patientUserId;
  let doctorUserId;

  if (user.role === 'doctor') {
    const doctorUser = await User.findById(req.user.userId);
    if (!doctorUser || !doctorUser.doctorProfileId) {
      return res.status(400).json({ success: false, error: 'Doctor profile not found' });
    }
    doctorId = doctorUser.doctorProfileId;
    status = 'confirmed';
    const { patientCode, patientId: bodyPatientId } = req.body;
    let patient;
    if (bodyPatientId) patient = await Patient.findById(bodyPatientId);
    else if (patientCode) patient = await Patient.findOne({ patientCode });
    if (!patient) return res.status(404).json({ success: false, error: 'Patient not found' });
    patientId = patient._id;
    patientUserId = patient.userId;
  } else if (user.role === 'patient') {
    const { doctorId: targetDoctorId, date, time, reason } = req.body;
    if (!targetDoctorId) return res.status(400).json({ success: false, error: 'Doctor ID required' });
    const doctor = await Doctor.findById(targetDoctorId).populate('userId');
    if (!doctor) return res.status(404).json({ success: false, error: 'Doctor not found' });
    const patient = await Patient.findOne({ userId: req.user.userId });
    if (!patient) return res.status(404).json({ success: false, error: 'Patient profile not found' });
    doctorId = targetDoctorId;
    patientId = patient._id;
    patientUserId = patient.userId;
    doctorUserId = doctor.userId._id;
    status = 'pending';
  } else {
    return res.status(403).json({ success: false, error: 'Forbidden' });
  }

  const { date, time, reason } = req.body;
  if (!date || !time) {
    return res.status(400).json({ success: false, error: 'Date and time required' });
  }

  const existing = await Appointment.findOne({
    doctorId,
    date: new Date(date),
    time,
    status: { $nin: ['cancelled', 'rejected'] }
  });
  if (existing) {
    return res.status(409).json({ success: false, error: 'Doctor already has an appointment at this time' });
  }

  const appointment = new Appointment({
    doctorId,
    patientId,
    date: new Date(date),
    time,
    reason,
    status
  });
  await appointment.save();

  if (status === 'confirmed') {
    await createNotification(
      patientUserId,
      'appointment_created',
      'New Appointment',
      `Your appointment on ${date} at ${time} has been confirmed.`,
      { appointmentId: appointment._id }
    );
  } else {
    await createNotification(
      doctorUserId,
      'appointment_request',
      'New Appointment Request',
      `New appointment request on ${date} at ${time} from ${user.fullName}.`,
      { appointmentId: appointment._id }
    );
  }

  res.status(201).json({ success: true, data: appointment });
});

router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { date, time, reason, status } = req.body;
    const userId = req.user.userId;

    const appointment = await Appointment.findById(id)
      .populate({
        path: 'doctorId',
        populate: { path: 'userId', select: 'fullName' }
      })
      .populate({
        path: 'patientId',
        populate: { path: 'userId', select: 'fullName' }
      });
    if (!appointment) return res.status(404).json({ success: false, error: 'Appointment not found' });

    const isDoctor = await Doctor.findOne({ userId }) && appointment.doctorId.equals(await Doctor.findOne({ userId }).select('_id'));
    const isPatient = await Patient.findOne({ userId }) && appointment.patientId.equals(await Patient.findOne({ userId }).select('_id'));
    if (!isDoctor && !isPatient) {
      return res.status(403).json({ success: false, error: 'Not authorized to modify this appointment' });
    }

    if (isPatient && (date || time || status)) {
      return res.status(403).json({ success: false, error: 'Patients can only modify the reason' });
    }

    if (date) appointment.date = new Date(date);
    if (time) appointment.time = time;
    if (reason) appointment.reason = reason;
    if (status && isDoctor) appointment.status = status;
    await appointment.save();

    const recipientId = isDoctor
      ? appointment.patientId.userId._id
      : appointment.doctorId.userId._id;
    let message = '';
    if (date || time) {
      message = `Appointment changed to ${appointment.date.toISOString().slice(0,10)} at ${appointment.time}`;
    } else if (status) {
      message = `Appointment ${status}`;
    } else if (reason) {
      message = `Appointment reason updated to: ${reason}`;
    } else {
      message = `Appointment details updated`;
    }
    await createNotification(
      recipientId,
      'appointment_updated',
      'Appointment Updated',
      message,
      { appointmentId: appointment._id }
    );

    res.json({ success: true, data: appointment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ success: false, error: 'Appointment not found' });

    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });

    let allowed = false;
    if (user.role === 'doctor') {
      const doctor = await Doctor.findOne({ userId: user._id });
      if (doctor && appointment.doctorId.toString() === doctor._id.toString()) allowed = true;
    } else if (user.role === 'admin' || user.role === 'super_admin') {
      allowed = true;
    }
    if (!allowed) return res.status(403).json({ success: false, error: 'Not authorized' });

    await appointment.deleteOne();
    res.json({ success: true, message: 'Appointment deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;