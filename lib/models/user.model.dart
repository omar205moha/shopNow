class UserModel {
  final String? uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? accountType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
     this.uid,
     this.name,
     this.email,
     this.phone,
     this.address,
     this.accountType,
     this.createdAt,
     this.updatedAt,
  });

  // Convert model to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'accountType': accountType,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create model from Firestore data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ,
      name: map['name'] ,
      email: map['email'] ,
      phone: map['phone'] ,
      address: map['address'] ,
      accountType: map['accountType'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
