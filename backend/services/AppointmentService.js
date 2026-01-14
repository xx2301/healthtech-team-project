class AppointmentService {
  constructor() {
    this.appointments = [];
    this.nextId = 1;
  }

  getAllAppointments() {
    return {
      success: true,
      data: this.appointments,
      count: this.appointments.length,
      message: 'Retrieved appointment list successfully'
    };
  }

  getAppointmentById(id) {
    const appointment = this.appointments.find(a => a.id === id);
    if (appointment) {
      return { success: true, data: appointment };
    }
    return { success: false, message: 'Appointment not found' };
  }

  createAppointment(appointmentData) {
    const newAppointment = {
      id: this.nextId++,
      status: 'pending',
      ...appointmentData,
      createdAt: new Date().toISOString()
    };
    
    this.appointments.push(newAppointment);
    return { 
      success: true, 
      data: newAppointment, 
      message: 'Appointment created successfully' 
    };
  }

  updateAppointmentStatus(id, status) {
    const index = this.appointments.findIndex(a => a.id === id);
    if (index === -1) {
      return { success: false, message: 'Appointment not found' };
    }
    
    this.appointments[index].status = status;
    this.appointments[index].updatedAt = new Date().toISOString();
    
    return { 
      success: true, 
      data: this.appointments[index],
      message: 'Appointment status updated successfully' 
    };
  }

  getAppointmentByPatientId(patientId) {
    const patientAppointments = this.appointments.filter(
      a => a.patientId == patientId
    );
    
    return {
      success: true,
      data: patientAppointments,
      count: patientAppointments.length
    };
  }

  getAppointmentByDate(date) {
    const dayAppointments = this.appointments.filter(
      a => a.date === date
    );
    
    return {
      success: true,
      data: dayAppointments,
      count: dayAppointments.length
    };
  }

  initTestData() {
    this.appointments = [
      {
        id: 1,
        patientId: 1,
        patientName: "Zhang Wei",
        doctorId: 1,
        doctorName: "Doctor Chong",
        date: "2024-01-20",
        time: "09:00",
        reason: "Regular check-up",
        status: "pending"
      },
      {
        id: 2,
        patientId: 2,
        patientName: "Lee Fang",
        doctorId: 1,
        doctorName: "Doctor Chong",
        date: "2024-01-20",
        time: "10:30",
        reason: "Blood sugar follow-up",
        status: "pending"
      }
    ];
    this.nextId = 3;
    
    return { 
      success: true, 
      count: this.appointments.length,
      message: 'Test data initialized successfully' 
    };
  }
}

module.exports = new AppointmentService();
