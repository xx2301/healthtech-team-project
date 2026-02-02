const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://admin:simplepassword@localhost:27017/healthtech?authSource=admin';
    
    console.log('🔗 Trying to connect MongoDB...');
    console.log('URI:', mongoURI ? 'Already Set' : 'Not Set');

    const conn = await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    
    mongoose.connection.on('connected', () => {
      console.log('✅ Mongoose connected to DB');
    });

    mongoose.connection.on('error', (err) => {
      console.error(`❌ Mongoose connection error: ${err}`);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('⚠️  Mongoose disconnected');
    });

  } catch (error) {
    console.error(`❌ Database connection error: ${error.message}`);
    console.error('Check .env "MONGODB_URI"');
    console.error('Current MONGODB_URI:', process.env.MONGODB_URI);
    process.exit(1);
  }
};

module.exports = connectDB;