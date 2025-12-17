import 'package:json_annotation/json_annotation.dart';

part 'shop.g.dart';

@JsonSerializable()
class Shop {
  final int id;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String zipcode;
  final String mobileNumber;
  final String email;
  final String? whatsappGroupLink;
  final String? instagramLink;
  final String? websiteLink;

  Shop({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.zipcode,
    required this.mobileNumber,
    required this.email,
    this.whatsappGroupLink,
    this.instagramLink,
    this.websiteLink,
  });

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);
  Map<String, dynamic> toJson() => _$ShopToJson(this);
}