import 'package:json_annotation/json_annotation.dart';

part 'product_size.g.dart';

@JsonSerializable()
class ProductSize {
  final String size;
  final int quantity;

  ProductSize({
    required this.size,
    required this.quantity,
  });

  factory ProductSize.fromJson(Map<String, dynamic> json) =>
      _$ProductSizeFromJson(json);

  Map<String, dynamic> toJson() => _$ProductSizeToJson(this);
}
