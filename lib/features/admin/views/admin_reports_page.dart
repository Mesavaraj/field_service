import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _technicians = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _supabase.from('service_requests').select('id, status, created_at'),
        _supabase.from('tasks').select('id, technician_id, status'),
        _supabase
            .from('profiles')
            .select('id, full_name, role')
            .eq('role', 'technician')
            .order('full_name'),
      ]);

      if (!mounted) return;

      setState(() {
        _requests = List<Map<String, dynamic>>.from(results[0]);
        _tasks = List<Map<String, dynamic>>.from(results[1]);
        _technicians = List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _status(Map<String, dynamic> item) {
    return (item['status'] ?? '').toString().toLowerCase().trim();
  }

  int _requestCount(String status) {
    return _requests.where((r) => _status(r) == status).length;
  }

  int _taskCount(String status) {
    return _tasks.where((t) => _status(t) == status).length;
  }

  int _technicianTaskCount(String technicianId) {
    return _tasks
        .where((t) => t['technician_id']?.toString() == technicianId)
        .length;
  }

  int _technicianActiveTaskCount(String technicianId) {
    return _tasks.where((t) {
      final assignedTo = t['technician_id']?.toString() == technicianId;
      final status = _status(t);

      return assignedTo &&
          (status == 'assigned' ||
              status == 'accepted' ||
              status == 'in_progress');
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Job Monitoring'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadReports,
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Service Request Overview',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 700
                        ? 3
                        : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _summaryCard(
                        'Total Requests',
                        _requests.length,
                        Icons.assignment,
                        Colors.blue,
                      ),
                      _summaryCard(
                        'Pending Requests',
                        _requestCount('pending'),
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                      _summaryCard(
                        'Assigned Requests',
                        _requestCount('assigned'),
                        Icons.assignment_ind,
                        Colors.indigo,
                      ),
                      _summaryCard(
                        'In Progress',
                        _requestCount('in_progress'),
                        Icons.engineering,
                        Colors.purple,
                      ),
                      _summaryCard(
                        'Completed Requests',
                        _requestCount('completed'),
                        Icons.task_alt,
                        Colors.green,
                      ),
                      _summaryCard(
                        'Total Tasks',
                        _tasks.length,
                        Icons.work,
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Task Status Overview',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _statusRow('Assigned', _taskCount('assigned'), Colors.indigo),
                  _statusRow('Accepted', _taskCount('accepted'), Colors.blue),
                  _statusRow(
                    'In Progress',
                    _taskCount('in_progress'),
                    Colors.orange,
                  ),
                  _statusRow(
                    'Completed',
                    _taskCount('completed'),
                    Colors.green,
                  ),
                  _statusRow('Cancelled', _taskCount('cancelled'), Colors.red),
                  const SizedBox(height: 28),
                  const Text(
                    'Technician Workload',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_technicians.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No technicians found.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._technicians.map((technician) {
                      final id = technician['id'].toString();
                      final name = (technician['full_name'] ?? 'Unnamed')
                          .toString();
                      final total = _technicianTaskCount(id);
                      final active = _technicianActiveTaskCount(id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.engineering),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            'Total tasks: $total  •  Active: $active',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Text(name),
                                content: Text(
                                  'Total assigned tasks: $total\n'
                                  'Active tasks: $active\n'
                                  'Completed tasks: ${_tasks.where((t) => t['technician_id']?.toString() == id && _status(t) == 'completed').length}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text(
                    'Report data is based on records visible to your '
                    'current Supabase user and its Row Level Security '
                    'policies.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Could not load reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, int count, IconData icon, Color color) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, int count, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(radius: 6, backgroundColor: color),
        title: Text(label),
        trailing: Text(
          count.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
