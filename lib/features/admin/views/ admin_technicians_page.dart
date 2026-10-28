import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../technician/viewmodel/technician_view_model.dart';

class AdminTechniciansPage extends StatefulWidget {
  const AdminTechniciansPage({super.key});

  @override
  State<AdminTechniciansPage> createState() => _AdminTechniciansPageState();
}

class _AdminTechniciansPageState extends State<AdminTechniciansPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<TechnicianViewModel>().loadTechnicians();
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
        title: const Text('Technician Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TechnicianViewModel>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<TechnicianViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // _buildSummary(viewModel),
                // const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or technician ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              viewModel.searchTechnicians('');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: viewModel.searchTechnicians,
                ),
                const SizedBox(height: 16),
                if (viewModel.isLoading && viewModel.technicians.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (viewModel.errorMessage != null)
                  _buildError(viewModel)
                else if (viewModel.technicians.isEmpty)
                  _buildEmptyState()
                else ...[
                  Text(
                    'Technicians (${viewModel.technicians.length})',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...viewModel.technicians.map(
                    (technician) => _buildTechnicianCard(context, technician),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(TechnicianViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              child: Icon(Icons.engineering, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registered Technicians'),
                  const SizedBox(height: 4),
                  Text(
                    '${viewModel.technicians.length}',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianCard(
    BuildContext context,
    Map<String, dynamic> technician,
  ) {
    final name = (technician['full_name'] ?? '').toString().trim();
    final id = (technician['id'] ?? '').toString();
    final createdAt = technician['created_at']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
        ),
        title: Text(name.isEmpty ? 'Unnamed technician' : name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('ID: $id'),
            if (createdAt != null)
              Text('Registered: ${_formatDate(createdAt)}'),
            const SizedBox(height: 5),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 15),
                SizedBox(width: 5),
                Text('Technician'),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'View details',
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showTechnicianDetails(context, technician),
        ),
      ),
    );
  }

  void _showTechnicianDetails(
    BuildContext context,
    Map<String, dynamic> technician,
  ) {
    final name = (technician['full_name'] ?? 'Unnamed technician').toString();
    final id = (technician['id'] ?? '').toString();
    final createdAt = technician['created_at']?.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Technician Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name'),
            const SizedBox(height: 8),
            Text('ID: $id'),
            const SizedBox(height: 8),
            Text('Role: ${technician['role'] ?? 'technician'}'),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text('Created: ${_formatDate(createdAt)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(TechnicianViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            'Unable to load technicians',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(viewModel.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: viewModel.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No technicians found',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Technician profiles will appear here when available.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}
