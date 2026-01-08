// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_size.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductSize _$ProductSizeFromJson(Map<String, dynamic> json) => ProductSize(
      size: json['size'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$ProductSizeToJson(ProductSize instance) =>
    <String, dynamic>{
      'size': instance.size,
      'quantity': instance.quantity,
    };
