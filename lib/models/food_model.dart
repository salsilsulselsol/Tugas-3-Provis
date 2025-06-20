// File: lib/models/food_model.dart

import 'dart:convert';

Food foodFromJson(String str) => Food.fromJson(json.decode(str));
String foodToJson(Food data) => json.encode(data.toMap());

class Food {
  final int? id;
  final String name;
  final String? description;
  final String image;
  final int? cookingTime;
  final double? rating;
  final int? likes;
  final String? price;
  final String? difficulty;
  final String? detailRoute;

  Food({
    this.id,
    required this.name,
    this.description,
    required this.image,
    this.cookingTime,
    this.rating,
    this.likes,
    this.price,
    this.difficulty,
    this.detailRoute,
  });

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      image: map['image'] as String,
      cookingTime: map['cookingTime'] as int?,
      rating: (map['rating'] as num?)?.toDouble(),
      likes: map['likes'] as int?,
      price: map['price'] as String?,
      difficulty: map['difficulty'] as String?,
      detailRoute: map['detailRoute'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'cookingTime': cookingTime,
      'rating': rating,
      'likes': likes,
      'price': price,
      'difficulty': difficulty,
    };
  }

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as int?,
      name: json['title']?.toString() ?? 'Resep Tanpa Nama',
      description: json['description']?.toString(),
      image: json['image_url']?.toString() ?? '',
      cookingTime: (json['cooking_time'] as num?)?.toInt() ?? 0,
      rating: double.tryParse(json['avg_rating']?.toString() ?? '') ?? 0.0,
      likes: (json['total_reviews'] as num?)?.toInt() ?? 0,
      price: json['price']?.toString() ?? 'Gratis',
      difficulty: json['difficulty']?.toString(),
      detailRoute: null,
    );
  }
}
