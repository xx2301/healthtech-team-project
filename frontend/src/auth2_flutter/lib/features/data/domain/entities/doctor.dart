class Doctor {
  final String dID;
  final String fName;
  final String medicalLicenseNumber;
  final String specialization;
  final String hospitalAffiliation;
  final String department;
  final int yearsOfExperience;
  final double consultationFee;
  final String availabilitySchedule;
  final String status;
  final double rating;

  Doctor({
    required this.dID,
    required this.fName,
    required this.medicalLicenseNumber,
    required this.specialization,
    required this.hospitalAffiliation,
    required this.department,
    required this.yearsOfExperience,
    required this.consultationFee,
    required this.availabilitySchedule,
    required this.status,
    required this.rating,
  });

  /// Backend → Doctor
  factory Doctor.fromBackendJson(Map<String, dynamic> json) {
    return Doctor(
      dID: json['_id'] ?? json['dID'] ?? '',
      fName: json['fName'] ?? json['fullName'] ?? json['name'] ?? '',
      medicalLicenseNumber: json['medicalLicenseNumber'] ?? '',
      specialization: json['specialization'] ?? '',
      hospitalAffiliation: json['hospitalAffiliation'] ?? '',
      department: json['department'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] is int
          ? json['yearsOfExperience']
          : int.tryParse(json['yearsOfExperience']?.toString() ?? '0') ?? 0,
      consultationFee: json['consultationFee'] is num
          ? json['consultationFee'].toDouble()
          : double.tryParse(json['consultationFee']?.toString() ?? '0') ?? 0.0,
      availabilitySchedule: json['availabilitySchedule'] ?? '',
      status: json['status'] ?? 'Active',
      rating: json['rating'] is num
          ? json['rating'].toDouble()
          : double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
    );
  }

  /// Doctor → Backend JSON
  Map<String, dynamic> toBackendJson() {
    return {
      'dID': dID,
      'fName': fName,
      'medicalLicenseNumber': medicalLicenseNumber,
      'specialization': specialization,
      'hospitalAffiliation': hospitalAffiliation,
      'department': department,
      'yearsOfExperience': yearsOfExperience,
      'consultationFee': consultationFee,
      'availabilitySchedule': availabilitySchedule,
      'status': status,
      'rating': rating,
    };
  }

  /// Local JSON → Doctor
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      dID: json['dID'] ?? '',
      fName: json['fName'] ?? '',
      medicalLicenseNumber: json['medicalLicenseNumber'] ?? '',
      specialization: json['specialization'] ?? '',
      hospitalAffiliation: json['hospitalAffiliation'] ?? '',
      department: json['department'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      availabilitySchedule: json['availabilitySchedule'] ?? '',
      status: json['status'] ?? 'Active',
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }

  /// Doctor → Local JSON
  Map<String, dynamic> toJson() {
    return {
      'dID': dID,
      'fName': fName,
      'medicalLicenseNumber': medicalLicenseNumber,
      'specialization': specialization,
      'hospitalAffiliation': hospitalAffiliation,
      'department': department,
      'yearsOfExperience': yearsOfExperience,
      'consultationFee': consultationFee,
      'availabilitySchedule': availabilitySchedule,
      'status': status,
      'rating': rating,
    };
  }
}
