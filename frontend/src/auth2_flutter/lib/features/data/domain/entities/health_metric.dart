class HealthMetric {
  final String id;
  final String patientId;
  final String userId;
  final String? deviceId;
  final String metricType;
  final dynamic value;
  final String unit;
  final DateTime timestamp;
  final String source;
  final String? deviceName;
  final int qualityScore;
  final bool isAbnormal;
  final double? accuracy;
  final String? notes;
  final List<String> tags;

  HealthMetric({
    required this.id,
    required this.patientId,
    required this.userId,
    this.deviceId,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.source,
    this.deviceName,
    required this.qualityScore,
    required this.isAbnormal,
    this.accuracy,
    this.notes,
    required this.tags,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId'] is Map
          ? json['patientId']['_id'].toString()
          : json['patientId'].toString(),
      userId: json['userId'] is Map
          ? json['userId']['_id'].toString()
          : json['userId'].toString(),
      deviceId: json['deviceId'] == null
          ? null
          : (json['deviceId'] is Map
              ? json['deviceId']['_id'].toString()
              : json['deviceId'].toString()),
      metricType: json['metricType'] ?? '',
      value: json['value'],
      unit: json['unit'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      source: json['source'] ?? 'manual',
      deviceName: json['deviceName'],
      qualityScore: json['qualityScore'] != null
          ? (json['qualityScore'] is int
              ? json['qualityScore']
              : int.tryParse(json['qualityScore'].toString()) ?? 100)
          : 100,
      isAbnormal: json['isAbnormal'] ?? false,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] is double
              ? json['accuracy']
              : double.tryParse(json['accuracy'].toString()))
          : null,
      notes: json['notes'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
