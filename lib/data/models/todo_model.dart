// lib/data/models/todo_model.dart

class TodoModel {
  const TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isDone,
    this.urlCover,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isDone;
  final String? urlCover;
  final String createdAt;
  final String updatedAt;

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id:          json['id']          as String?          ?? '',
      userId:      json['userId']      as String?          ?? '',
      title:       json['title']       as String?          ?? '',
      description: json['description'] as String?          ?? '',
      isDone:      json['isDone']      as bool?            ?? false,  // null-safe
      urlCover:    json['cover']    as String?,
      createdAt:   json['createdAt']   as String?          ?? '',
      updatedAt:   json['updatedAt']   as String?          ?? '',
    );
  }
}