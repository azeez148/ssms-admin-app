import 'package:flutter_admin_app/models/category.dart';
import 'package:flutter_admin_app/models/product_size.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable(explicitToJson: true)
class Product {
  final int id;
  final String name;
  final String? description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'unit_price')
  final int unitPrice;

  @JsonKey(name: 'selling_price')
  final int sellingPrice;

  @JsonKey(name: 'category_id')
  final int categoryId;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'can_listed')
  final bool canListed;

  final Category? category;

  @JsonKey(name: 'offer_id')
  final int? offerId;

  @JsonKey(name: 'discounted_price')
  final int discountedPrice;

  @JsonKey(name: 'offer_price')
  final int? offerPrice;

  @JsonKey(name: 'size_map')
  final List<ProductSize>? sizeMap;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.unitPrice,
    required this.sellingPrice,
    required this.categoryId,
    required this.isActive,
    required this.canListed,
    this.category,
    this.offerId,
    required this.discountedPrice,
    this.offerPrice,
    this.sizeMap,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
