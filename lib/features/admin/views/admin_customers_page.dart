import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/customer_view_model.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerViewModel>().loadCustomers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            onPressed: () => context.read<CustomerViewModel>().refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<CustomerViewModel>(
        builder: (context, vm, child) {
          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: vm.searchCustomers,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name or ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              vm.searchCustomers('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (vm.isLoading && vm.customers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (vm.errorMessage != null)
                  _errorView(vm)
                else if (vm.customers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.person_search, size: 55, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No customers found'),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'Customers (${vm.customers.length})',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...vm.customers.map(
                    (customer) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(_initial(customer['full_name'])),
                        ),
                        title: Text(
                          (customer['full_name'] ?? 'Unnamed customer')
                              .toString(),
                        ),
                        subtitle: Text(
                          'ID: ${customer['id']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showCustomerDetails(context, vm, customer),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(CustomerViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 45),
          const SizedBox(height: 12),
          const Text('Unable to load customers'),
          const SizedBox(height: 8),
          Text(vm.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: vm.refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Future<void> _showCustomerDetails(
    BuildContext context,
    CustomerViewModel vm,
    Map<String, dynamic> customer,
  ) async {
    final customerId = customer['id'].toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text((customer['full_name'] ?? 'Customer').toString()),
          content: SizedBox(
            width: 450,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: vm.getCustomerRequests(customerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Could not load request history:\n${snapshot.error}',
                  );
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Text(
                    'No service requests found for this customer.',
                  );
                }

                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.home_repair_service),
                        title: Text(
                          (request['category'] ?? 'Service request').toString(),
                        ),
                        subtitle: Text(
                          '${request['address'] ?? 'No address'}\n'
                          'Status: ${request['status'] ?? 'Unknown'}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _initial(dynamic value) {
    final name = (value ?? '').toString().trim();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}
