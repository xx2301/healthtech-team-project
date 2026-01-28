class AppUser {
  final String uid;
  final String email;
  final String? fullName;
  final String? age;
  final String? height;
  final String? weight;

  AppUser({
    required this.uid,
    required this.email,
    this.fullName,
    this.age,
    this.height,
    this.weight,
  });


  factory AppUser.fromBackendJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['_id'] ?? json['id'] ?? json['uid'] ?? 'unknown',
      email: json['email'] ?? '',
      fullName: json['name'] ?? json['fullName'] ?? '',
      age: json['age']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toBackendJson() {
    return {
      'email': email,
      'name': fullName,
      'age': age != null ? int.tryParse(age!) : null,
      'height': height != null ? double.tryParse(height!) : null,
      'weight': weight != null ? double.tryParse(weight!) : null,
    };
  }
  
  //convert app user to json
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'age': age,
      'height': height,
      'weight': weight,
    };
  }

  // convert json to app user
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      age: json['age'],
      height: json['height'],
      weight: json['weight'],
    );
  }
}
