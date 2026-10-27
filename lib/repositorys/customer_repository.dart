import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerRepository {
  final SupabaseClient _supabase;

  CustomerRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getCustomers({String search = ''}) async {
    final response = await _supabase
        .from('profiles')
        .select('id, full_name, role, created_at')
        .eq('role', 'customer')
        .order('full_name');

    final customers = List<Map<String, dynamic>>.from(response);

    if (search.trim().isEmpty) {
      return customers;
    }

    final keyword = search.trim().toLowerCase();

    return customers.where((customer) {
      final name = (customer['full_name'] ?? '').toString().toLowerCase();
      final id = (customer['id'] ?? '').toString().toLowerCase();

      return name.contains(keyword) || id.contains(keyword);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCustomerRequests(
    String customerId,
  ) async {
    final response = await _supabase
        .from('service_requests')
        .select('id, category, address, status, created_at')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
