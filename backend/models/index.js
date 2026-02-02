const User = require('./User');
const Patient = require('./patient');
const Doctor = require('./doctor');
const HealthMetric = require('./HealthMetric');
const MedicalRecord = require('./MedicalRecord');
const EmergencyContact = require('./EmergencyContact');
const DoctorPatientRelation = require('./DoctorPatientRelation');
const HealthGoal = require('./HealthGoal');
const SymptomLog = require('./SymptomLog');
const Device = require('./Device');
const HealthReport = require('./HealthReport');
const Conversation = require('./conversation');
const ChatMessage = require('./ChatMessage');

module.exports = {
  User,
  Doctor,
  Patient,
  HealthMetric,
  MedicalRecord,
  EmergencyContact,
  DoctorPatientRelation,
  HealthGoal,
  SymptomLog,
  Device,
  HealthReport,
  Conversation,
  ChatMessage
};