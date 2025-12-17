import 'package:json_annotation/json_annotation.dart';

part 'sale.g.dart';

enum SaleStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('SHIPPED')
  shipped,
  @JsonValue('RETURNED')
  returned,
  @JsonValue('CANCELLED')
  cancelled,
}

@JsonSerializable()
class PaymentType {
  final int id;
  final String name;
  final String? description;

  PaymentType({
    required this.id,
    required this.name,
    this.description,
  });

  factory PaymentType.fromJson(Map<String, dynamic> json) => _$PaymentTypeFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTypeToJson(this);
}

@JsonSerializable()
class DeliveryType {
  final int id;
  final String name;
  final String? description;
  final double charge;

  DeliveryType({
    required this.id,
    required this.name,
    this.description,
    required this.charge,
  });

  factory DeliveryType.fromJson(Map<String, dynamic> json) => _$DeliveryTypeFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryTypeToJson(this);
}

@JsonSerializable()
class CustomerResponse {
  final int id;
  final String name;
  final String? address;
  final String? mobile;
  final String? email;
  final String? city;
  final String? state;
  @JsonKey(name: 'zip_code')
  final String? zipCode;

  CustomerResponse({
    required this.id,
    required this.name,
    this.address,
    this.mobile,
    this.email,
    this.city,
    this.state,
    this.zipCode,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) => _$CustomerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerResponseToJson(this);
}

@JsonSerializable()
class SaleItem {
  final int? id;
  @JsonKey(name: 'product_id')
  final int productId;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'product_category')
  final String productCategory;
  final String size;
  @JsonKey(name: 'quantity_available')
  final int quantityAvailable;
  int quantity;
  @JsonKey(name: 'sale_price')
  double salePrice;
  @JsonKey(name: 'total_price')
  double totalPrice;
  @JsonKey(name: 'sale_id')
  final int? saleId;

  SaleItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.size,
    required this.quantityAvailable,
    required this.quantity,
    required this.salePrice,
    required this.totalPrice,
    this.saleId,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => _$SaleItemFromJson(json);
  Map<String, dynamic> toJson() => _$SaleItemToJson(this);

  double calculateTotal() => quantity * salePrice;
}

@JsonSerializable()
class Sale {
  final int id;
  final String date;
  @JsonKey(name: 'total_quantity')
  final int totalQuantity;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  @JsonKey(name: 'payment_type_id')
  final int paymentTypeId;
  @JsonKey(name: 'payment_reference_number')
  final String? paymentReferenceNumber;
  @JsonKey(name: 'delivery_type_id')
  final int deliveryTypeId;
  @JsonKey(name: 'shop_id')
  final int shopId;
  @JsonKey(name: 'customer_id')
  final int customerId;
  final SaleStatus? status;
  @JsonKey(name: 'sale_items')
  final List<SaleItem>? saleItems;
  @JsonKey(name: 'payment_type')
  final PaymentType? paymentType;
  @JsonKey(name: 'delivery_type')
  final DeliveryType? deliveryType;
  final CustomerResponse? customer;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Sale({
    required this.id,
    required this.date,
    required this.totalQuantity,
    required this.totalPrice,
    required this.paymentTypeId,
    this.paymentReferenceNumber,
    required this.deliveryTypeId,
    required this.shopId,
    required this.customerId,
    this.status,
    this.saleItems,
    this.paymentType,
    this.deliveryType,
    this.customer,
    this.createdAt,
    this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
  Map<String, dynamic> toJson() => _$SaleToJson(this);

  String get customerName => customer?.name ?? '';
  String get customerAddress => customer?.address ?? '';
  String get customerMobile => customer?.mobile ?? '';
  String get customerEmail => customer?.email ?? '';
  String get customerCity => customer?.city ?? '';
  String get customerState => customer?.state ?? '';
  String get customerZipCode => customer?.zipCode ?? '';
}

@JsonSerializable()
class SaleCreate {
  final String date;
  @JsonKey(name: 'total_quantity')
  final int totalQuantity;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  @JsonKey(name: 'payment_type_id')
  final int paymentTypeId;
  @JsonKey(name: 'payment_reference_number')
  final String? paymentReferenceNumber;
  @JsonKey(name: 'delivery_type_id')
  final int deliveryTypeId;
  @JsonKey(name: 'shop_id')
  final int shopId;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'customer_address')
  final String? customerAddress;
  @JsonKey(name: 'customer_mobile')
  final String? customerMobile;
  @JsonKey(name: 'customer_email')
  final String? customerEmail;
  @JsonKey(name: 'sale_items')
  final List<SaleItemCreate> saleItems;
  final SaleStatus? status;

  SaleCreate({
    required this.date,
    required this.totalQuantity,
    required this.totalPrice,
    required this.paymentTypeId,
    this.paymentReferenceNumber,
    required this.deliveryTypeId,
    required this.shopId,
    required this.customerId,
    this.customerName,
    this.customerAddress,
    this.customerMobile,
    this.customerEmail,
    required this.saleItems,
    this.status,
  });

  factory SaleCreate.fromJson(Map<String, dynamic> json) => _$SaleCreateFromJson(json);
  Map<String, dynamic> toJson() => _$SaleCreateToJson(this);
}

@JsonSerializable()
class SaleItemCreate {
  @JsonKey(name: 'product_id')
  final int productId;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'product_category')
  final String productCategory;
  final String size;
  @JsonKey(name: 'quantity_available')
  final int quantityAvailable;
  final int quantity;
  @JsonKey(name: 'sale_price')
  final double salePrice;
  @JsonKey(name: 'total_price')
  final double totalPrice;

  SaleItemCreate({
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.size,
    required this.quantityAvailable,
    required this.quantity,
    required this.salePrice,
    required this.totalPrice,
  });

  factory SaleItemCreate.fromJson(Map<String, dynamic> json) => _$SaleItemCreateFromJson(json);
  Map<String, dynamic> toJson() => _$SaleItemCreateToJson(this);
}

@JsonSerializable()
class SaleStatusUpdate {
  final SaleStatus status;

  SaleStatusUpdate({required this.status});

  factory SaleStatusUpdate.fromJson(Map<String, dynamic> json) => _$SaleStatusUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$SaleStatusUpdateToJson(this);
}

@JsonSerializable()
class SaleSummary {
  @JsonKey(name: 'total_count')
  final int totalCount;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'total_items_sold')
  final int totalItemsSold;

  SaleSummary({
    required this.totalCount,
    required this.totalRevenue,
    required this.totalItemsSold,
  });

  factory SaleSummary.fromJson(Map<String, dynamic> json) => _$SaleSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$SaleSummaryToJson(this);
}
