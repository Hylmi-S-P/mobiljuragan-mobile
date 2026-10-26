import 'package:flutter/foundation.dart';

/// Model data Tanya Jawab (FAQ) Pusat Bantuan MobilJuragan
@immutable
class FaqModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int orderIndex;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.orderIndex = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory untuk membuat FaqModel dari Map JSON API backend
  factory FaqModel.fromJson(Map<String, dynamic> json) {
    int parsedOrder = 0;
    if (json['orderIndex'] is num) {
      parsedOrder = (json['orderIndex'] as num).toInt();
    } else if (json['orderIndex'] != null) {
      parsedOrder = int.tryParse(json['orderIndex'].toString()) ?? 0;
    }

    bool parsedActive = true;
    if (json['isActive'] is bool) {
      parsedActive = json['isActive'] as bool;
    } else if (json['isActive'] != null) {
      parsedActive = json['isActive'].toString().toLowerCase() == 'true';
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString());
    }

    DateTime? parsedUpdatedAt;
    if (json['updatedAt'] != null) {
      parsedUpdatedAt = DateTime.tryParse(json['updatedAt'].toString());
    }

    return FaqModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Umum',
      orderIndex: parsedOrder,
      isActive: parsedActive,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Konversi FaqModel ke representasi JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'orderIndex': orderIndex,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaqModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          question == other.question &&
          answer == other.answer &&
          category == other.category &&
          orderIndex == other.orderIndex &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      question.hashCode ^
      answer.hashCode ^
      category.hashCode ^
      orderIndex.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'FaqModel(id: $id, question: $question, category: $category, orderIndex: $orderIndex, isActive: $isActive)';
}
