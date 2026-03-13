class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String? age;
  final String? height;
  final String? weight;
  final String? gender;
  final DateTime? weightUpdatedAt;
  final DateTime? heightUpdatedAt;
  final String role;
  final int? avatarColor;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.weightUpdatedAt,
    this.heightUpdatedAt,
    required this.role,
    this.avatarColor,
  });

  // convert json to app user
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      age: json['age'],
      height: json['height'],
      weight: json['weight'],
      gender: json['gender'] ?? 'other', 
      role: json['role'] ?? 'user', 
    );
  }

  factory AppUser.fromBackendJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['_id'] ?? json['id'] ?? json['uid'] ?? 'unknown',
      email: json['email'] ?? '',
      fullName: json['name'] ?? json['fullName'] ?? '',
      age: json['age']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      gender: json['gender'] ?? 'other',
      weightUpdatedAt: json['weightUpdatedAt'] != null ? DateTime.tryParse(json['weightUpdatedAt']) : null,
      heightUpdatedAt: json['heightUpdatedAt'] != null ? DateTime.tryParse(json['heightUpdatedAt']) : null,
      role: json['role'] ?? 'user',
      avatarColor: json['avatarColor'] != null ? json['avatarColor'] as int : null,
    );
  }

  /*Map<String, dynamic> toBackendJson() {
    return {
      'email': email,
      'name': fullName,
      'age': age != null ? int.tryParse(age!) : null,
      'height': height != null ? double.tryParse(height!) : null,
      'weight': weight != null ? double.tryParse(weight!) : null,
    };
  }*/
  
  //convert app user to json
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      if (avatarColor != null) 'avatarColor': avatarColor,
    };
  }
}
