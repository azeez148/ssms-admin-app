import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class ProductSizeBase {
  final String size;
  final int quantity;

  ProductSizeBase({
    required this.size,
    required this.quantity,
  });

  factory ProductSizeBase.fromJson(Map<String, dynamic> json) => _$ProductSizeBaseFromJson(json);
  Map<String, dynamic> toJson() => _$ProductSizeBaseToJson(this);
}

@JsonSerializable()
class CategoryBase {
  final String name;
  final String? description;

  CategoryBase({
    required this.name,
    this.description,
  });

  factory CategoryBase.fromJson(Map<String, dynamic> json) => _$CategoryBaseFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryBaseToJson(this);
}

@JsonSerializable()
class Product {
  final int id;
  final String name;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? description;
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
  final CategoryBase? category;
  @JsonKey(name: 'discounted_price')
  final int? discountedPrice;
  @JsonKey(name: 'offer_id')
  final int? offerId;
  @JsonKey(name: 'offer_price')
  final int? offerPrice;
  @JsonKey(name: 'offer_name')
  final String? offerName;
  @JsonKey(name: 'size_map')
  final List<ProductSizeBase>? sizeMap;

  Product({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.unitPrice = 0,
    this.sellingPrice = 0,
    this.categoryId = 0,
    this.isActive = false,
    this.canListed = false,
    this.category,
    this.discountedPrice,
    this.offerId,
    this.offerPrice,
    this.offerName,
    this.sizeMap,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}