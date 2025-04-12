import 'dart:convert';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class CaseModel {
  final String id;
  final String title;
  final String description;
  final int priority; // 0-100 percentage
  final DateTime createdAt;

  CaseModel({
    String? id, // Allow providing an ID, otherwise generate one
    required this.title,
    required this.description,
    required this.priority,
    DateTime? createdAt, // Allow providing creation date
  })  : id = id ?? uuid.v4(), // Generate ID if not provided
        createdAt = createdAt ?? DateTime.now(), // Set creation date if not provided
        assert(priority >= 0 && priority <= 100, 'Priority must be between 0 and 100');

  // Method to convert a CaseModel instance to a Map (for JSON encoding)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(), // Store date as ISO string
    };
  }

  // Factory constructor to create a CaseModel instance from a Map (from JSON decoding)
  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String), // Parse date from ISO string
    );
  }

   // Helper to convert a CaseModel to a JSON string
  String toJsonString() => jsonEncode(toJson());

  // Helper to create a CaseModel from a JSON string
  factory CaseModel.fromJsonString(String jsonString) => CaseModel.fromJson(jsonDecode(jsonString));
}