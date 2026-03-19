class HealthBotService {
  static String getReply(String userMessage, Map<String, dynamic> data) {
    final text = userMessage.toLowerCase();

    final int steps = data['todaySteps'] ?? 0;
    final int goal = data['stepsGoal'] ?? 6700;
    final double heartRate = (data['avgHeartRate'] ?? 0).toDouble();
    final int calories = data['todayCalories'] ?? 0;
    final double sleep = (data['todaySleep'] ?? 0).toDouble();

    if (text.contains('health') || text.contains('summary')) {
      return 'Today you have walked $steps steps. '
          'Your average heart rate is ${heartRate.toInt()} bpm. '
          'You burned $calories kcal today and slept ${sleep.toStringAsFixed(1)} hours.';
    }

    if (text.contains('step')) {
      if (steps >= goal) {
        return 'Great job! You have already reached your daily step goal.';
      } else {
        final remaining = goal - steps;
        return 'You still need $remaining more steps to reach your daily goal.';
      }
    }

    if (text.contains('sleep')) {
      if (sleep >= 8) {
        return 'You slept ${sleep.toStringAsFixed(1)} hours. That looks good today.';
      } else {
        return 'You slept ${sleep.toStringAsFixed(1)} hours. Try resting a bit earlier tonight.';
      }
    }

    if (text.contains('heart')) {
      return 'Your average heart rate today is ${heartRate.toInt()} bpm. '
          'Heart rate shows how fast your heart is beating.';
    }

    return 'I can help with your health summary, steps, sleep, and heart rate.';
  }
}