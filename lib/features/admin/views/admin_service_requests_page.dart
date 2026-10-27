import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminServiceRequestsPage extends StatefulWidget {
  const AdminServiceRequestsPage({super.key});

  @override
  State<AdminServiceRequestsPage> createState() =>
      _AdminServiceRequestsPageState();
}

class _AdminServiceRequestsPageState extends State<AdminServiceRequestsPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;
  String _selectedStatus = 'all';

  final List<String> _statuses = [
    'all',
    'pending',
    'assigned',
    'in_progress',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      debugPrint('Current user: ${user?.id}');
      debugPrint('Session exists: ${client.auth.currentSession != null}');

      final result = await client
          .from('service_requests')
          .select()
          .order('created_at', ascending: false);

      debugPrint('Supabase result: $result');
      debugPrint('Number of requests: ${result.length}');

      if (!mounted) return;

      setState(() {
        _requests = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Supabase request error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    final query = _searchController.text.trim().toLowerCase();

    return _requests.where((request) {
      final status = (request['status'] ?? 'pending').toString().toLowerCase();

      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;

      final category = (request['category'] ?? '').toString().toLowerCase();
      final address = (request['address'] ?? '').toString().toLowerCase();
      final id = (request['id'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          category.contains(query) ||
          address.contains(query) ||
          id.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statuses.map((status) {
          final selected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_formatStatus(status == 'all' ? 'all' : status)),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedStatus = status);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final category = (request['category'] ?? 'Service request').toString();
    final address = (request['address'] ?? 'No address').toString();
    final status = (request['status'] ?? 'pending').toString();
    final id = (request['id'] ?? '').toString();
    final date = request['preferred_date']?.toString() ?? 'nil';

    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/admin/request-details', extra: request);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.home_repair_service_outlined,
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.blueGrey),
              ),
              if (date != null && date.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Preferred date: $date'),
              ],
              const SizedBox(height: 8),
              Text(
                'Request ID: $id',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View details →',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = _filteredRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search category, address, or ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusFilter(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${requests.length} requests',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to load requests',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadRequests,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : requests.isEmpty
                  ? const Center(child: Text('No service requests found.'))
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: requests.length,
                        itemBuilder: (context, index) =>
                            _buildRequestCard(requests[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
