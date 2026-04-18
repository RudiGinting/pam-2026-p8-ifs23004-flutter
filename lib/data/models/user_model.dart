// lib/data/models/user_model.dart

/// Model untuk data pengguna yang dikembalikan dari API.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.urlPhoto,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String username;
  final String? urlPhoto;   // URL publik foto profil
  final String createdAt;
  final String updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id']        as String,
      name:      json['name']      as String,
      username:  json['username']  as String,
      urlPhoto:  json['urlPhoto']  as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}