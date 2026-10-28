import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../viewmodel/customer_home_view_model.dart';
import '../viewmodel/customer_request_tracking_view_model.dart';
import '../viewmodel/service_request_view_model.dart';

class ServiceRequestScreen extends StatelessWidget {
  final String category;

  const ServiceRequestScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceRequestViewModel(category: category)..loadProfile(),
      child: const _ServiceRequestView(),
    );
  }
}

class _ServiceRequestView extends StatelessWidget {
  const _ServiceRequestView();

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectDate(
    BuildContext context,
    ServiceRequestViewModel vm,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: vm.preferredDate ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );

    if (date != null) vm.selectDate(date);
  }

  String _formatSelectedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceRequestViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Service Request')),
          body: SafeArea(
            child: vm.isLoadingProfile
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: vm.formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'What service do you need?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tell us about the problem and where you need help.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Category
                        DropdownButtonFormField<String>(
                          initialValue: vm.selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Service category',
                            prefixIcon: Icon(Icons.home_repair_service),
                            border: OutlineInputBorder(),
                          ),
                          items: vm.categories
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: vm.selectCategory,
                          validator: (value) =>
                              value == null ? 'Select a category' : null,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        TextFormField(
                          controller: vm.descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            labelText: 'Describe the problem',
                            hintText:
                                'Explain the issue you are experiencing...',
                            prefixIcon: Icon(Icons.description_outlined),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please describe the problem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Service address
                        TextFormField(
                          controller: vm.addressController,
                          minLines: 2,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Full address *',
                            hintText: 'House/Flat No., Street, Area, Landmark',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the full address';
                            }
                            if (value.trim().length < 5) {
                              return 'Please enter a complete address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // City
                        TextFormField(
                          controller: vm.cityController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'City / Town *',
                            hintText: 'Enter city or town',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter the city or town'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // State
                        TextFormField(
                          controller: vm.stateController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            hintText: 'Enter state',
                            prefixIcon: Icon(Icons.map_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter the state'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // PIN code
                        TextFormField(
                          controller: vm.pincodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'PIN code *',
                            hintText: 'Enter 6-digit PIN code',
                            prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the PIN code';
                            }
                            if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
                              return 'Enter a valid 6-digit Indian PIN code';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // GPS
                        OutlinedButton.icon(
                          onPressed: vm.isGettingLocation
                              ? null
                              : () async {
                                  final message = await vm.getCurrentLocation();
                                  if (context.mounted) {
                                    _showMessage(context, message);
                                  }
                                },
                          icon: vm.isGettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            vm.isGettingLocation
                                ? 'Getting location...'
                                : 'Use current location',
                          ),
                        ),

                        if (vm.latitude != null && vm.longitude != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'GPS: ${vm.latitude}, ${vm.longitude}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Preferred date
                        const Text(
                          'Preferred service date',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context, vm),
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            vm.preferredDate == null
                                ? 'Choose a date (optional)'
                                : _formatSelectedDate(vm.preferredDate!),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Submit
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: vm.isSubmitting
                                ? null
                                : () async {
                                    final message = await vm.submitRequest();

                                    if (!context.mounted) return;

                                    _showMessage(context, message);

                                    if (message ==
                                        'Service request submitted successfully.') {
                                      vm.clearForm();

                                      // Pop back with true to indicate a refresh is needed.
                                      context.pop(true);
                                    } else if (message ==
                                        'Request saved locally. Synchronization is pending.') {
                                      vm.clearForm();

                                      // Pop back with true as it's saved locally.
                                      context.pop(true);
                                    }
                                  },
                            icon: vm.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              vm.isSubmitting
                                  ? 'Submitting...'
                                  : 'Submit Service Request',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
