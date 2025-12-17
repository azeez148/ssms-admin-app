// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductSizeBase _$ProductSizeBaseFromJson(Map<String, dynamic> json) =>
    ProductSizeBase(
      size: json['size'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$ProductSizeBaseToJson(ProductSizeBase instance) =>
    <String, dynamic>{
      'size': instance.size,
      'quantity': instance.quantity,
    };

CategoryBase _$CategoryBaseFromJson(Map<String, dynamic> json) => CategoryBase(
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CategoryBaseToJson(CategoryBase instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toInt() ?? 0,
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      canListed: json['can_listed'] as bool? ?? false,
      category: json['category'] == null
          ? null
          : CategoryBase.fromJson(json['category'] as Map<String, dynamic>),
      discountedPrice: (json['discounted_price'] as num?)?.toInt(),
      offerId: (json['offer_id'] as num?)?.toInt(),
      offerPrice: (json['offer_price'] as num?)?.toInt(),
      offerName: json['offer_name'] as String?,
      sizeMap: (json['size_map'] as List<dynamic>?)
          ?.map((e) => ProductSizeBase.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_url': instance.imageUrl,
      'description': instance.description,
      'unit_price': instance.unitPrice,
      'selling_price': instance.sellingPrice,
      'category_id': instance.categoryId,
      'is_active': instance.isActive,
      'can_listed': instance.canListed,
      'category': instance.category,
      'discounted_price': instance.discountedPrice,
      'offer_id': instance.offerId,
      'offer_price': instance.offerPrice,
      'offer_name': instance.offerName,
      'size_map': instance.sizeMap,
    };
