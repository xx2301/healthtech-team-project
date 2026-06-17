const cron = require('node-cron');
const HealthMetric = require('../models/HealthMetric');

function startCleanup() {
    cron.schedule('0 3 * * 0', async () => {
        try {
            const cutoff = new Date();
            cutoff.setDate(cutoff.getDate() - 90); // 90 days ago

            const result = await HealthMetric.deleteMany({ 
                timestamp: { $lt: cutoff },
                source: 'device' // Only delete device-generated metrics
            });

            console.log(`Cleanup completed. Deleted ${result.deletedCount} old health metrics.`);
        } catch (error) {
            console.error('Error occurred during cleanup:', error);
        }
    });
}

module.exports = { startCleanup };