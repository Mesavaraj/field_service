import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRequestDetailsPage extends StatefulWidget {
  final Map<String, dynamic> request;

  const AdminRequestDetailsPage({super.key, required this.request});

  @override
  State<AdminRequestDetailsPage> createState() =>
      _AdminRequestDetailsPageState();
}

class _AdminRequestDetailsPageState extends State<AdminRequestDetailsPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _technicians = [];
  List<Map<String, dynamic>> _tasks = [];

  String? _selectedTechnician;
  DateTime? _scheduledAt;

  bool _loadingTechnicians = true;
  bool _loadingTasks = true;
  bool _creatingTask = false;

  String? _technicianError;
  String? _taskError;

  static const List<String> _taskStatuses = [
    'assigned',
    // 'accepted',
    // 'in_progress',
    // 'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
    _loadTasks();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String get _requestId => widget.request['id'].toString();

  Future<void> _loadTechnicians() async {
    setState(() {
      _loadingTechnicians = true;
      _technicianError = null;
    });

    try {
      final result = await _client
          .from('profiles')
          .select('id, full_name, role')
          .eq('role', 'technician')
          .order('full_name');

      if (!mounted) return;

      setState(() {
        _technicians = List<Map<String, dynamic>>.from(result);
        _loadingTechnicians = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _technicianError = e.toString();
        _loadingTechnicians = false;
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loadingTasks = true;
      _taskError = null;
    });

    try {
      final result = await _client
          .from('tasks')
          .select(
            'id, service_request_id, technician_id, '
            'scheduled_at, status, notes, created_at',
          )
          .eq('service_request_id', _requestId)
          .order('scheduled_at', ascending: true);

      final tasks = List<Map<String, dynamic>>.from(result);

      // Load technician names separately to avoid depending
      // on an automatically generated Supabase join name.
      final technicianIds = tasks
          .map((task) => task['technician_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, String> technicianNames = {};

      if (technicianIds.isNotEmpty) {
        final profiles = await _client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', technicianIds);

        for (final profile in profiles) {
          technicianNames[profile['id'].toString()] =
              (profile['full_name'] ?? 'Technician').toString();
        }
      }

      for (final task in tasks) {
        task['technician_name'] =
            technicianNames[task['technician_id']?.toString()] ?? 'Technician';
      }

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _loadingTasks = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _taskError = e.toString();
        _loadingTasks = false;
      });
    }
  }

  Future<void> _selectAppointment() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );

    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledAt != null
          ? TimeOfDay.fromDateTime(_scheduledAt!)
          : TimeOfDay.now(),
    );

    if (!mounted || time == null) return;

    final appointment = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (appointment.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future appointment time.')),
      );
      return;
    }

    setState(() {
      _scheduledAt = appointment;
    });
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'Not scheduled';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final local = parsed.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';

    final time = TimeOfDay.fromDateTime(local).format(context);

    return '$date • $time';
  }

  String _formatStatus(String value) {
    return value
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
      case 'assigned':
        return Colors.blue;
      // case 'accepted':
      //   return Colors.indigo;
      // case 'in_progress':
      //   return Colors.orange;
      // case 'completed':
      //   return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _createTask() async {
    if (_selectedTechnician == null) {
      _showMessage('Please select a technician.');
      return;
    }

    if (_scheduledAt == null) {
      _showMessage('Please select the onsite date and time.');
      return;
    }

    if (_scheduledAt!.isBefore(DateTime.now())) {
      _showMessage('The appointment must be in the future.');
      return;
    }

    setState(() => _creatingTask = true);

    try {
      await _client.from('tasks').insert({
        'service_request_id': _requestId,
        'technician_id': _selectedTechnician,
        'scheduled_at': _scheduledAt!.toUtc().toIso8601String(),
        'status': 'assigned',
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      if (!mounted) return;

      _notesController.clear();

      setState(() {
        _selectedTechnician = null;
        _scheduledAt = null;
      });

      _showMessage('Task created and technician assigned.');

      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to create task: $e');
    } finally {
      if (mounted) {
        setState(() => _creatingTask = false);
      }
    }
  }

  Future<void> _updateTaskStatus(
    Map<String, dynamic> task,
    String status,
  ) async {
    try {
      await _client
          .from('tasks')
          .update({
            'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', task['id']);

      if (!mounted) return;

      _showMessage('Task status updated.');
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to update task: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _detail(String label, dynamic value) {
    final text = value?.toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            text == null || text.isEmpty ? 'Not provided' : text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails() {
    final request = widget.request;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Service Request',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _detail('Request ID', request['id']),
            _detail('Customer ID', request['customer_id']),
            _detail('Category', request['category']),
            _detail('Description', request['description']),
            _detail('Address', request['address']),
            _detail('Preferred Date', request['preferred_date']),
            _detail('Request Status', request['status']),
            _detail(
              'GPS Coordinates',
              request['latitude'] != null && request['longitude'] != null
                  ? '${request['latitude']}, '
                        '${request['longitude']}'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Task & Assign Technician',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This creates a task without directly changing '
              'the service request status.',
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),

            if (_loadingTechnicians)
              const Center(child: CircularProgressIndicator())
            else if (_technicianError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _technicianError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: _loadTechnicians,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (_technicians.isEmpty)
              const Text('No technicians found.')
            else
              DropdownButtonFormField<String>(
                value: _selectedTechnician,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Technician',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.engineering),
                ),
                items: _technicians.map((technician) {
                  return DropdownMenuItem<String>(
                    value: technician['id'].toString(),
                    child: Text(
                      (technician['full_name'] ?? 'Unnamed').toString(),
                    ),
                  );
                }).toList(),
                onChanged: _creatingTask
                    ? null
                    : (value) {
                        setState(() {
                          _selectedTechnician = value;
                        });
                      },
              ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _creatingTask ? null : _selectAppointment,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _scheduledAt == null
                    ? 'Select onsite appointment'
                    : _formatDateTime(_scheduledAt!.toUtc().toIso8601String()),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _notesController,
              enabled: !_creatingTask,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Task instructions (optional)',
                hintText: 'Describe the work to be performed onsite',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _creatingTask || _loadingTechnicians || _technicians.isEmpty
                    ? null
                    : _createTask,
                icon: _creatingTask
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.assignment_ind),
                label: Text(
                  _creatingTask ? 'Creating task...' : 'Create Task & Assign',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = (task['status'] ?? 'assigned').toString();

    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Task ${task['id']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),
            _detail('Technician', task['technician_name']),
            _detail(
              'Onsite Appointment',
              _formatDateTime(task['scheduled_at']),
            ),
            _detail('Task Instructions', task['notes']),
            const SizedBox(height: 8),
            const Text(
              'Update Task Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _taskStatuses.contains(status) ? status : null,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _taskStatuses.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(_formatStatus(value)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != status) {
                  _updateTaskStatus(task, value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingTasks() {
    if (_loadingTasks) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_taskError != null) {
      return Column(
        children: [
          Text(_taskError!, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: _loadTasks, child: const Text('Retry')),
        ],
      );
    }

    if (_tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, size: 36, color: Colors.blueGrey),
            SizedBox(height: 8),
            Text('No tasks assigned to this request yet.'),
          ],
        ),
      );
    }

    return Column(children: _tasks.map(_buildTaskCard).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details & Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadTechnicians();
            await _loadTasks();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildRequestDetails(),
              const SizedBox(height: 16),
              _buildAssignmentForm(),
              const SizedBox(height: 24),
              const Text(
                'Assigned Tasks & Appointments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildExistingTasks(),
            ],
          ),
        ),
      ),
    );
  }
}
