class AuthService {
  constructor() {
    this.users = [
      {
        id: 1,
        email: "doctor@healthtech.com",
        password: "password123",
        name: "Dr. Smith",
        role: "doctor"
      }
    ];
    this.nextId = 2;
  }

  login(email, password) {
    const user = this.users.find(u => 
      u.email === email && u.password === password
    );
    
    if (user) {
      const { password, ...userWithoutPassword } = user;
      return {
        success: true,
        data: {
          user: userWithoutPassword,
          token: `mock-jwt-token-${Date.now()}`
        },
        message: 'Login successful'
      };
    }
    
    return {
      success: false,
      message: 'Email or password incorrect'
    };
  }

  register(userData) {
    if (this.users.some(u => u.email === userData.email)) {
      return {
        success: false,
        message: 'Email already registered'
      };
    }
    
    const newUser = {
      id: this.nextId++,
      ...userData,
      role: userData.role || 'patient',
      createdAt: new Date().toISOString()
    };
    
    this.users.push(newUser);
    
    const { password, ...userWithoutPassword } = newUser;
    
    return {
      success: true,
      data: { user: userWithoutPassword },
      message: 'Registration successful'
    };
  }

  getUserById(id) {
    const user = this.users.find(u => u.id === id);
    if (user) {
      const { password, ...userWithoutPassword } = user;
      return { success: true, data: userWithoutPassword };
    }
    return { success: false, message: 'user not found' };
  }

  getAllDoctors() {
    const doctors = this.users
      .filter(u => u.role === 'doctor')
      .map(({ password, ...doctor }) => doctor);
    
    return {
      success: true,
      data: doctors,
      count: doctors.length
    };
  }
}

module.exports = new AuthService();
