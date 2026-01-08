// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      unitPrice: (json['unit_price'] as num).toInt(),
      sellingPrice: (json['selling_price'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      isActive: json['is_active'] as bool,
      canListed: json['can_listed'] as bool,
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
      offerId: (json['offer_id'] as num?)?.toInt(),
      discountedPrice: (json['discounted_price'] as num).toInt(),
      offerPrice: (json['offer_price'] as num).toInt(),
      sizeMap: (json['size_map'] as List<dynamic>?)
          ?.map((e) => ProductSize.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'unit_price': instance.unitPrice,
      'selling_price': instance.sellingPrice,
      'category_id': instance.categoryId,
      'is_active': instance.isActive,
      'can_listed': instance.canListed,
      'category': instance.category?.toJson(),
      'offer_id': instance.offerId,
      'discounted_price': instance.discountedPrice,
      'offer_price': instance.offerPrice,
      'size_map': instance.sizeMap?.map((e) => e.toJson()).toList(),
    };
