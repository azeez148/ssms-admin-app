// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentType _$PaymentTypeFromJson(Map<String, dynamic> json) => PaymentType(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PaymentTypeToJson(PaymentType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };

DeliveryType _$DeliveryTypeFromJson(Map<String, dynamic> json) => DeliveryType(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      charge: (json['charge'] as num).toDouble(),
    );

Map<String, dynamic> _$DeliveryTypeToJson(DeliveryType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'charge': instance.charge,
    };

CustomerResponse _$CustomerResponseFromJson(Map<String, dynamic> json) =>
    CustomerResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
    );

Map<String, dynamic> _$CustomerResponseToJson(CustomerResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'mobile': instance.mobile,
      'email': instance.email,
      'city': instance.city,
      'state': instance.state,
      'zip_code': instance.zipCode,
    };

SaleItem _$SaleItemFromJson(Map<String, dynamic> json) => SaleItem(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      productCategory: json['product_category'] as String,
      size: json['size'] as String,
      quantityAvailable: json['quantity_available'] as int,
      quantity: json['quantity'] as int,
      salePrice: (json['sale_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      saleId: json['sale_id'] as int?,
    );

Map<String, dynamic> _$SaleItemToJson(SaleItem instance) => <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'product_name': instance.productName,
      'product_category': instance.productCategory,
      'size': instance.size,
      'quantity_available': instance.quantityAvailable,
      'quantity': instance.quantity,
      'sale_price': instance.salePrice,
      'total_price': instance.totalPrice,
      'sale_id': instance.saleId,
    };

Sale _$SaleFromJson(Map<String, dynamic> json) => Sale(
      id: json['id'] as int,
      date: json['date'] as String,
      totalQuantity: json['total_quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      paymentTypeId: json['payment_type_id'] as int,
      paymentReferenceNumber: json['payment_reference_number'] as String?,
      deliveryTypeId: json['delivery_type_id'] as int,
      shopId: json['shop_id'] as int,
      customerId: json['customer_id'] as int,
      status: $enumDecodeNullable(_$SaleStatusEnumMap, json['status']),
      saleItems: (json['sale_items'] as List<dynamic>?)
          ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentType: json['payment_type'] == null
          ? null
          : PaymentType.fromJson(json['payment_type'] as Map<String, dynamic>),
      deliveryType: json['delivery_type'] == null
          ? null
          : DeliveryType.fromJson(json['delivery_type'] as Map<String, dynamic>),
      customer: json['customer'] == null
          ? null
          : CustomerResponse.fromJson(json['customer'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$SaleToJson(Sale instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'total_quantity': instance.totalQuantity,
      'total_price': instance.totalPrice,
      'payment_type_id': instance.paymentTypeId,
      'payment_reference_number': instance.paymentReferenceNumber,
      'delivery_type_id': instance.deliveryTypeId,
      'shop_id': instance.shopId,
      'customer_id': instance.customerId,
      'status': _$SaleStatusEnumMap[instance.status],
      'sale_items': instance.saleItems,
      'payment_type': instance.paymentType,
      'delivery_type': instance.deliveryType,
      'customer': instance.customer,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

const _$SaleStatusEnumMap = {
  SaleStatus.pending: 'PENDING',
  SaleStatus.completed: 'COMPLETED',
  SaleStatus.shipped: 'SHIPPED',
  SaleStatus.returned: 'RETURNED',
  SaleStatus.cancelled: 'CANCELLED',
};

SaleCreate _$SaleCreateFromJson(Map<String, dynamic> json) => SaleCreate(
      date: json['date'] as String,
      totalQuantity: json['total_quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      paymentTypeId: json['payment_type_id'] as int,
      paymentReferenceNumber: json['payment_reference_number'] as String?,
      deliveryTypeId: json['delivery_type_id'] as int,
      shopId: json['shop_id'] as int,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String?,
      customerAddress: json['customer_address'] as String?,
      customerMobile: json['customer_mobile'] as String?,
      customerEmail: json['customer_email'] as String?,
      saleItems: (json['sale_items'] as List<dynamic>)
          .map((e) => SaleItemCreate.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecodeNullable(_$SaleStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$SaleCreateToJson(SaleCreate instance) =>
    <String, dynamic>{
      'date': instance.date,
      'total_quantity': instance.totalQuantity,
      'total_price': instance.totalPrice,
      'payment_type_id': instance.paymentTypeId,
      'payment_reference_number': instance.paymentReferenceNumber,
      'delivery_type_id': instance.deliveryTypeId,
      'shop_id': instance.shopId,
      'customer_id': instance.customerId,
      'customer_name': instance.customerName,
      'customer_address': instance.customerAddress,
      'customer_mobile': instance.customerMobile,
      'customer_email': instance.customerEmail,
      'sale_items': instance.saleItems,
      'status': _$SaleStatusEnumMap[instance.status],
    };

SaleItemCreate _$SaleItemCreateFromJson(Map<String, dynamic> json) =>
    SaleItemCreate(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      productCategory: json['product_category'] as String,
      size: json['size'] as String,
      quantityAvailable: json['quantity_available'] as int,
      quantity: json['quantity'] as int,
      salePrice: (json['sale_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );

Map<String, dynamic> _$SaleItemCreateToJson(SaleItemCreate instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_name': instance.productName,
      'product_category': instance.productCategory,
      'size': instance.size,
      'quantity_available': instance.quantityAvailable,
      'quantity': instance.quantity,
      'sale_price': instance.salePrice,
      'total_price': instance.totalPrice,
    };

SaleStatusUpdate _$SaleStatusUpdateFromJson(Map<String, dynamic> json) =>
    SaleStatusUpdate(
      status: $enumDecode(_$SaleStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$SaleStatusUpdateToJson(SaleStatusUpdate instance) =>
    <String, dynamic>{
      'status': _$SaleStatusEnumMap[instance.status],
    };

SaleSummary _$SaleSummaryFromJson(Map<String, dynamic> json) => SaleSummary(
      totalCount: json['total_count'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalItemsSold: json['total_items_sold'] as int,
    );

Map<String, dynamic> _$SaleSummaryToJson(SaleSummary instance) =>
    <String, dynamic>{
      'total_count': instance.totalCount,
      'total_revenue': instance.totalRevenue,
      'total_items_sold': instance.totalItemsSold,
    };
