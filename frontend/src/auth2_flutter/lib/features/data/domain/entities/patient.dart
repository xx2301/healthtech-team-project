class Patient {
  final String pid;
  final String fname;
  final DateTime? dateOfBirth; // nullable in case backend sends null/invalid
  final String gender;
  final double? height; // cm (use double for flexibility)
  final double? weight; // kg
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicConditions;
  final int? emergencyContactID;
  final String patientCode;
  final int? age;
  final DateTime? deletedAt;
  final String? primaryDoctorName;

  Patient({
    required this.pid,
    required this.fname,
    this.dateOfBirth,
    required this.gender,
    this.height,
    this.weight,
    this.bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    this.emergencyContactID,
    required this.patientCode,
    this.age,
    this.deletedAt,
    this.primaryDoctorName,
  })  : allergies = allergies ?? const [],
        chronicConditions = chronicConditions ?? const [];

  /// Backend → Patient
  /// Adjust key names here to match your API response.
  factory Patient.fromBackendJson(Map<String, dynamic> json) {
    DateTime? parseDob(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    List<String> parseStringList(dynamic v) {
      if (v == null) return <String>[];
      if (v is List) return v.map((e) => e.toString()).toList();
      return <String>[];
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    int? age;
    if (json['age'] != null) {
      if (json['age'] is int) age = json['age'];
      else if (json['age'] is num) age = json['age'].toInt();
      else age = int.tryParse(json['age'].toString());
    }

    DateTime? deletedAt;
    if (json['deletedAt'] != null) {
      deletedAt = DateTime.tryParse(json['deletedAt'].toString());
    }

    return Patient(
      pid: (json['_id'] ?? json['id'] ?? json['pid'] ?? '').toString(),
      fname: (json['fname'] ?? json['fullName'] ?? json['name'] ?? '').toString(),
      dateOfBirth: parseDob(json['dateOfBirth'] ?? json['dob']),
      gender: (json['gender'] ?? '').toString(),
      height: parseDouble(json['height']),
      weight: parseDouble(json['weight']),
      bloodType: (json['bloodType'] ?? json['blood_type'])?.toString(),
      allergies: parseStringList(json['allergies']),
      chronicConditions: parseStringList(json['chronicConditions'] ?? json['chronic_conditions']),
      emergencyContactID: parseInt(json['emergencyContactID'] ?? json['emergency_contact_id']),
      patientCode: (json['patientCode'] ?? json['patient_code'] ?? '').toString(),
      age: parseInt(json['age']),
      deletedAt: deletedAt,
    );
  }

  /// Patient → Backend JSON (types converted properly)
  Map<String, dynamic> toBackendJson() {
    return {
      // usually backend doesn't want pid on create; include if your API expects it
      'pid': pid,
      'fname': fname,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'emergencyContactID': emergencyContactID,
      'patientCode': patientCode,
    };
  }

  /// Local storage JSON (same as above, but you can keep it consistent)
  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'fname': fname,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'emergencyContactID': emergencyContactID,
      'patientCode': patientCode,
    };
  }

  /// Local JSON → Patient
  factory Patient.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    final v = json['dateOfBirth'];
    if (v is String && v.isNotEmpty) dob = DateTime.tryParse(v);

    List<String> safeList(dynamic x) =>
        (x is List) ? x.map((e) => e.toString()).toList() : <String>[];

    double? safeDouble(dynamic x) {
      if (x == null) return null;
      if (x is num) return x.toDouble();
      return double.tryParse(x.toString());
    }

    int? safeInt(dynamic x) {
      if (x == null) return null;
      if (x is int) return x;
      if (x is num) return x.toInt();
      return int.tryParse(x.toString());
    }

    final doctor = json['primaryDoctor'];
    String? primaryDoctorName;

    if (doctor is Map<String, dynamic>) {
      final userId = doctor['userId'];
      if (userId is Map<String, dynamic>) {
        primaryDoctorName = userId['fullName']?.toString();
      } else {
        primaryDoctorName = doctor['fullName']?.toString();
      }
    }

    return Patient(
      pid: (json['pid'] ?? '').toString(),
      fname: (json['fname'] ?? '').toString(),
      dateOfBirth: dob,
      gender: (json['gender'] ?? '').toString(),
      height: safeDouble(json['height']),
      weight: safeDouble(json['weight']),
      bloodType: json['bloodType']?.toString(),
      allergies: safeList(json['allergies']),
      chronicConditions: safeList(json['chronicConditions']),
      emergencyContactID: safeInt(json['emergencyContactID']),
      patientCode: (json['patientCode'] ?? '').toString(),
      age: safeInt(json['age']),
      primaryDoctorName: primaryDoctorName,
    );
  }
}