// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Shop _$ShopFromJson(Map<String, dynamic> json) => Shop(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      zipcode: json['zipcode'] as String,
      mobileNumber: json['mobileNumber'] as String,
      email: json['email'] as String,
      whatsappGroupLink: json['whatsappGroupLink'] as String?,
      instagramLink: json['instagramLink'] as String?,
      websiteLink: json['websiteLink'] as String?,
    );

Map<String, dynamic> _$ShopToJson(Shop instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'addressLine1': instance.addressLine1,
      'addressLine2': instance.addressLine2,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'zipcode': instance.zipcode,
      'mobileNumber': instance.mobileNumber,
      'email': instance.email,
      'whatsappGroupLink': instance.whatsappGroupLink,
      'instagramLink': instance.instagramLink,
      'websiteLink': instance.websiteLink,
    };
