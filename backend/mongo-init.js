//it will auto create test data
db = db.getSiblingDB('healthtech');

db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["email", "name", "passwordHash"],
      properties: {
        email: { bsonType: "string", description: "user email" },
        name: { bsonType: "string", description: "user name" },
        passwordHash: { bsonType: "string", description: "encrypted password" },
        age: { bsonType: "int", minimum: 0, maximum: 120, description: "age" },
        phone: { bsonType: "string", description: "phone number" },
        emergencyContact: { bsonType: "string", description: "emergency contact" },
        healthConditions: { bsonType: "array", description: "health conditions" },
        createdAt: { bsonType: "date", description: "created time" },
        updatedAt: { bsonType: "date", description: "updated time" }
      }
    }
  }
});

db.users.insertMany([
  {
    _id: ObjectId("651234567890123456789001"),
    email: "test@healthtech.com",
    name: "Test User",
    passwordHash: "$2b$10$N9qo8uLOickgx2ZMRZoMye3Y7C3Yd7F6Kc3uB5pOQ9p1Jf4rKJ9Wq", // =password123
    age: 65,
    phone: "+60123456789",
    emergencyContact: "+60198765432",
    healthConditions: ["High Blood Pressure", "Diabetes"],
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    _id: ObjectId("651234567890123456789002"),
    email: "lim@example.com",
    name: "Mr. Lim",
    passwordHash: "$2b$10$N9qo8uLOickgx2ZMRZoMye3Y7C3Yd7F6Kc3uB5pOQ9p1Jf4rKJ9Wq",
    age: 72,
    phone: "+60111222333",
    emergencyContact: "+60199887766",
    healthConditions: ["Arthritis", "High Cholesterol"],
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

db.createCollection('health_data', {
  timeseries: {
    timeField: "timestamp",
    metaField: "metadata",
    granularity: "hours"
  },
  expireAfterSeconds: 31536000 // 1 year later it will delete
});

db.health_data.insertMany([
  {
    userId: db.users.findOne({email: "test@healthtech.com"})._id,
    timestamp: new Date(),
    source: "simulated", // simulated, manual, fitbit, apple_health, google_fit
    dataType: "daily_summary",
    data: {
      steps: 5263,
      heartRate: { avg: 72, min: 65, max: 85 },
      bloodPressure: { systolic: 120, diastolic: 80 },
      sleepHours: 7.5,
      caloriesBurned: 2345,
      waterIntake: 2000
    },
    metadata: {
      device: "simulator",
      version: "1.0"
    }
  },
  {
    userId: db.users.findOne({email: "lim@example.com"})._id,
    timestamp: new Date(),
    source: "simulated",
    dataType: "daily_summary",
    data: {
      steps: 8234,
      heartRate: { avg: 68, min: 62, max: 75 },
      bloodPressure: { systolic: 118, diastolic: 76 },
      sleepHours: 8.2,
      caloriesBurned: 2876,
      waterIntake: 1800
    },
    metadata: {
      device: "simulator",
      version: "1.0"
    }
  }
]);

db.createCollection('reminders');
db.reminders.insertMany([
  {
    userId: db.users.findOne({email: "test@healthtech.com"})._id,
    title: "eat medication",
    description: "reduce pressure medicine",
    type: "medication",
    scheduledTime: "08:00",
    repeat: ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
    active: true,
    createdAt: new Date(),
    lastTriggered: null
  },
  {
    userId: db.users.findOne({email: "lim@example.com"})._id,
    title: "reminder for clinic appointment",
    description: "heart check -up at clinic",
    type: "appointment",
    scheduledTime: "14:30",
    date: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // 1 day later
    active: true,
    createdAt: new Date()
  }
]);

// super admin
db.getSiblingDB('admin').createUser({
  user: "super_admin",
  pwd: "SuperAdmin@123",
  roles: [{
    role: "root",
    db: "admin"
  }],
  mechanisms: ["SCRAM-SHA-256"]
});

// create application admin user
db.createUser({
  user: "app_admin",
  pwd: "AppAdmin@456", 
  roles: [
    { role: "dbOwner", db: "healthtech" },
    { role: "readWrite", db: "healthtech" },
    { role: "dbAdmin", db: "healthtech" }
  ],
  mechanisms: ["SCRAM-SHA-256"]
});

// create monitoring admin user
db.createUser({
  user: "monitor_user",
  pwd: "Monitor@789", 
  roles: [
    { role: "read", db: "healthtech" },
    { role: "clusterMonitor", db: "admin" }
  ],
  mechanisms: ["SCRAM-SHA-256"]
});

db.createUser({
  user: "backend_app",
  pwd: "Backend@2024",
  roles: [
    {
      role: "dbOwner", 
      db: "healthtech"
    }
  ],
  mechanisms: ["SCRAM-SHA-256"]
});


db.users.createIndex({ email: 1 }, { unique: true, name: "email_unique_idx" });
db.users.createIndex({ phone: 1 }, { unique: true, sparse: true, name: "phone_unique_idx" });
db.users.createIndex({ createdAt: -1 }, { name: "created_at_idx" });

db.health_data.createIndex({ userId: 1, timestamp: -1 }, { name: "user_timestamp_idx" });
db.health_data.createIndex({ "metadata.device": 1 }, { name: "device_idx" });
db.health_data.createIndex({ source: 1 }, { name: "source_idx" });

db.reminders.createIndex({ userId: 1, active: 1 }, { name: "user_active_idx" });
db.reminders.createIndex({ scheduledTime: 1 }, { name: "scheduled_time_idx" });

print("\n MongoDB initialization completed successfully!");
print("=".repeat(50));
print(" Created collections:");
db.getCollectionNames().forEach(col => print(`   • ${col}`));

print("\n Created database users:");
db.getUsers().forEach(user => {
  print(`   • ${user.user} (roles: ${user.roles.map(r => r.role).join(", ")})`);
});

print("\n Stats: ");
print(`   • Number of users: ${db.users.countDocuments()}`);
print(`   • Health records: ${db.health_data.countDocuments()}`);
print(`   • Reminders: ${db.reminders.countDocuments()}`);

print("\n Connection Information:");
print(`   • Database: healthtech`);
print(`   • Application connection: mongodb://backend_app:Backend@2024@localhost:27017/healthtech`);
print(`   • Management interface: http://localhost:8081 (if running)`);
print("=".repeat(50));
