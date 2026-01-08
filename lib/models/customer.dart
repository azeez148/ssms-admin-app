class Customer {
  final int id;
  final String name;
  final String? address;
  final String mobile;
  final String? email;

  Customer({
    required this.id,
    required this.name,
    this.address,
    required this.mobile,
    this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String?,
        mobile: json['mobile'] as String,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'mobile': mobile,
        'email': email,
      };
}
