const mongoose = require('mongoose');
const HealthMetrics = require('../models/HealthMetrics');
const HealthGoal = require('../models/HealthGoal');

async function getDailySummary(userId, date) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setDate(end.getDate() + 1);

    const pipeline = [
        {
            $match: {
                userId: new mongoose.Types.ObjectId(userId),
                timestamp: { $gte: start, $lt: end }
            }
        },
        {
            $group: {
                _id: '$metricType',
                total: { $sum: { $toDouble: '$value' } },
                average: { $avg: { $toDouble: '$value' } },
                min: { $min: { $toDouble: '$value' } },
                max: { $max: { $toDouble: '$value' } },
                count: { $sum: 1 },
                latest: { $last: '$value' }
            }
        }
    ];

    const results = await HealthMetrics.aggregate(pipeline);

    const summary = {};
    results.forEach(result => {
        summary[result._id] = {
            total: Math.round(result.total * 100) / 100,
            average: Math.round(result.average * 100) / 100,
            min: result.min,
            max: result.max,
            count: result.count,
            latest: result.latest
        };
    });

    const stepsGoalDoc = await HealthGoal.findOne({ userId, goalType: 'steps', isActive: true });
    const stepsGoal = stepsGoalDoc?.targetValue || 6700;

    const weekAgo = new Date(start);
    weekAgo.setDate(weekAgo.getDate() - 6);

    const weekPipeline = [
        {
            $match: {
                userId: new mongoose.Types.ObjectId(userId),
                metricType: 'steps',
                timestamp: { $gte: weekAgo, $lt: end }
            }
        },
        {
            $group: {
                _id: {
                    $dateToString: { format: "%Y-%m-%d", date: "$timestamp" }
                },
                totalSteps: { $sum: { $toDouble: '$value' } }
            }
        }
    ];

    const weeklySteps = await HealthMetrics.aggregate(weekPipeline);
    const weeklyDailyStatus = [];
    for (let i= 0; i< 7; i++) {
        const day = new Date(start);
        day.setDate(day.getDate() - (6 - i));
        const dayStr = day.toISOString().split('T')[0];
        const dayData = weeklySteps.find(d => d._id === dayStr);
        weeklyDailyStatus.push(dayData ? dayData.totalSteps >= stepsGoal : false);
    }

    const todaySteps = summary.steps?.total || 0;
    const stepsProgress = stepsGoal > 0 ? Math.min(todaySteps / stepsGoal, 1) : 0;

    return {
        date: start.toISOString().split('T')[0],
        steps: {
            total: Math.round(todaySteps),
            goal: stepsGoal,
            progress: Math.round(stepsProgress * 1000) / 1000
        },
        heartRate: {
            avg: summary.heartRate?.average || null,
            min: summary.heartRate?.min || null,
            max: summary.heartRate?.max || null
        },
        calories: { total: summary.calories_burned?.total || 0 },
        sleep: { total: summary.sleep_duration?.total || 0 },
        glucose: {avg: summary.glucose?.average || null},
        bloodPressure: { latest: summary.blood_pressure?.latest || null },
        weight: { latest: summary.weight?.latest || null },
        waterIntake: { total: summary.water_intake?.total || 0 },
        oxygenSaturation: { latest: summary.oxygen_saturation?.latest || null },
        respiratoryRate: { latest: summary.respiratory_rate?.latest || null },
        weeklyDailyStatus,
        isGoalArchievedToday: todaySteps >= stepsGoal
    };
}

module.exports = { getDailySummary };