// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleResponse _$SaleResponseFromJson(Map<String, dynamic> json) => SaleResponse(
      id: (json['id'] as num?)?.toInt(),
      product_id: (json['product_id'] as num?)?.toInt(),
      product_name: json['product_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      total_amount: (json['total_amount'] as num?)?.toInt(),
      sale_date: json['sale_date'] as String?,
      total_price: (json['total_price'] as num?)?.toInt(),
      date: json['date'] as String?,
      sale_items: (json['sale_items'] as List<dynamic>?)
          ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      customer_id: (json['customer_id'] as num?)?.toInt(),
      shop_id: (json['shop_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SaleResponseToJson(SaleResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.product_id,
      'product_name': instance.product_name,
      'quantity': instance.quantity,
      'total_amount': instance.total_amount,
      'sale_date': instance.sale_date,
      'total_price': instance.total_price,
      'date': instance.date,
      'sale_items': instance.sale_items,
      'status': instance.status,
      'customer_id': instance.customer_id,
      'shop_id': instance.shop_id,
    };

SaleItem _$SaleItemFromJson(Map<String, dynamic> json) => SaleItem(
      id: (json['id'] as num?)?.toInt(),
      product_id: (json['product_id'] as num?)?.toInt(),
      product_name: json['product_name'] as String?,
      product_category: json['product_category'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      sale_price: (json['sale_price'] as num?)?.toInt(),
      total_price: (json['total_price'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SaleItemToJson(SaleItem instance) => <String, dynamic>{
      'id': instance.id,
      'product_id': instance.product_id,
      'product_name': instance.product_name,
      'product_category': instance.product_category,
      'quantity': instance.quantity,
      'sale_price': instance.sale_price,
      'total_price': instance.total_price,
    };

PurchaseResponse _$PurchaseResponseFromJson(Map<String, dynamic> json) =>
    PurchaseResponse(
      id: (json['id'] as num?)?.toInt(),
      product_id: (json['product_id'] as num?)?.toInt(),
      product_name: json['product_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      total_amount: (json['total_amount'] as num?)?.toInt(),
      purchase_date: json['purchase_date'] as String?,
      total_price: (json['total_price'] as num?)?.toInt(),
      date: json['date'] as String?,
    );

Map<String, dynamic> _$PurchaseResponseToJson(PurchaseResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.product_id,
      'product_name': instance.product_name,
      'quantity': instance.quantity,
      'total_amount': instance.total_amount,
      'purchase_date': instance.purchase_date,
      'total_price': instance.total_price,
      'date': instance.date,
    };

Dashboard _$DashboardFromJson(Map<String, dynamic> json) => Dashboard(
      total_sales: json['total_sales'] as Map<String, dynamic>?,
      total_products: (json['total_products'] as num?)?.toInt(),
      total_categories: (json['total_categories'] as num?)?.toInt(),
      most_sold_items: json['most_sold_items'] as Map<String, dynamic>?,
      recent_sales: (json['recent_sales'] as List<dynamic>?)
          ?.map((e) => SaleResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total_purchases: json['total_purchases'] as Map<String, dynamic>?,
      recent_purchases: (json['recent_purchases'] as List<dynamic>?)
          ?.map((e) => PurchaseResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardToJson(Dashboard instance) => <String, dynamic>{
      'total_sales': instance.total_sales,
      'total_products': instance.total_products,
      'total_categories': instance.total_categories,
      'most_sold_items': instance.most_sold_items,
      'recent_sales': instance.recent_sales,
      'total_purchases': instance.total_purchases,
      'recent_purchases': instance.recent_purchases,
    };
