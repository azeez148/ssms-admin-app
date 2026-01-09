import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _customerService = CustomerService();
  List<Customer> customers = [];
  List<Customer> allCustomers = [];
  int page = 1;
  String filterValue = '';
  final int itemsPerPage = 10;
  bool isLoading = false;
  String? errorMessage;

  // Styling
  final Color primaryColor = const Color(0xFF2A2D3E);
  final Color surfaceColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  void loadCustomers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await _customerService.getCustomers();
      setState(() {
        allCustomers = data;
        applyFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading customers: $e';
        isLoading = false;
      });
    }
  }

  void applyFilter([String? value]) {
    if (value != null) filterValue = value.toLowerCase();
    setState(() {
      customers = allCustomers
          .where((c) => c.name.toLowerCase().contains(filterValue))
          .toList();
      page = 1;
    });
  }

  void openDialog([Customer? customer]) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => CustomerDialog(customer: customer),
    );
    if (result != null) {
      if (customer != null) {
        await _customerService.updateCustomer(result);
      } else {
        await _customerService.createCustomer(result);
      }
      loadCustomers();
    }
  }

  void deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await _customerService.deleteCustomer(id);
      loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagedCustomers = customers.skip((page - 1) * itemsPerPage).take(itemsPerPage).toList();
    final totalPages = (customers.length / itemsPerPage).ceil();
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;
    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: loadCustomers,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh Data',
                )
              ],
            ),
          ),
          // 2. Filter/Action Bar
          Transform.translate(
            offset: const Offset(0, -25),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => openDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customer'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('Export to Excel'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 2, child: _buildSearchField()),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => openDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customer'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('Export to Excel'),
                        ),
                      ],
                    ),
            ),
          ),
          // 3. Table/List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                    : customers.isEmpty
                        ? _buildEmptyState()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: isMobile
                                ? ListView.builder(
                                    itemCount: pagedCustomers.length,
                                    itemBuilder: (context, idx) => _buildMobileCustomerCard(pagedCustomers[idx]),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                                      dataRowHeight: 60,
                                      columns: const [
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Address')),
                                        DataColumn(label: Text('Mobile')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: pagedCustomers.map((customer) => DataRow(cells: [
                                        DataCell(Text(customer.id.toString())),
                                        DataCell(Text(customer.name)),
                                        DataCell(Text(customer.address ?? '')),
                                        DataCell(Text(customer.mobile)),
                                        DataCell(Text(customer.email ?? '')),
                                        DataCell(Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () => openDialog(customer),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => deleteCustomer(customer.id),
                                            ),
                                          ],
                                        )),
                                      ])).toList(),
                                    ),
                                  ),
                          ),
          ),
          if (customers.isNotEmpty && totalPages > 1)
            _buildPaginationControls(totalPages),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by name',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
      onChanged: applyFilter,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No customers found",
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCustomerCard(Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${customer.id}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => openDialog(customer),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteCustomer(customer.id),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (customer.address != null && customer.address!.isNotEmpty)
            Text(customer.address!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(customer.mobile, style: const TextStyle(fontSize: 13)),
          if (customer.email != null && customer.email!.isNotEmpty)
            Text(customer.email!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? () => setState(() => page--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text("Page $page of $totalPages"),
          IconButton(
            onPressed: page < totalPages ? () => setState(() => page++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class CustomerDialog extends StatefulWidget {
  final Customer? customer;
  const CustomerDialog({Key? key, this.customer}) : super(key: key);

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController mobileController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer?.name ?? '');
    addressController = TextEditingController(text: widget.customer?.address ?? '');
    mobileController = TextEditingController(text: widget.customer?.mobile ?? '');
    emailController = TextEditingController(text: widget.customer?.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final customer = Customer(
              id: widget.customer?.id ?? 0,
              name: nameController.text.trim(),
              address: addressController.text.trim(),
              mobile: mobileController.text.trim(),
              email: emailController.text.trim(),
            );
            Navigator.pop(context, customer);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
