import '../models/customer.dart';

class CustomerService {
  // Replace with your API logic
  List<Customer> _customers = [
    Customer(id: 1, name: 'John Doe', address: '123 Main St', mobile: '1234567890', email: 'john@example.com'),
    Customer(id: 2, name: 'Jane Smith', address: '456 Oak Ave', mobile: '9876543210', email: 'jane@example.com'),
  ];
  int _nextId = 3;

  Future<List<Customer>> getCustomers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Customer>.from(_customers);
  }

  Future<void> createCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _customers.add(customer.copyWith(id: _nextId++));
  }

  Future<void> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) _customers[idx] = customer;
  }

  Future<void> deleteCustomer(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _customers.removeWhere((c) => c.id == id);
  }
}

extension on Customer {
  Customer copyWith({int? id, String? name, String? address, String? mobile, String? email}) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
    );
  }
}
