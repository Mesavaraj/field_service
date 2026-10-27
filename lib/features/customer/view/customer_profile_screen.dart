import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/customer_profile_view_model.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerProfileViewModel()..loadProfile(),
      child: const _CustomerProfileView(),
    );
  }
}

class _CustomerProfileView extends StatelessWidget {
  const _CustomerProfileView();

  void _showMessage(BuildContext context, String? message) {
    if (message == null || !context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(
    BuildContext context,
    CustomerProfileViewModel vm,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await vm.logout();

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      _showMessage(context, 'Logout failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProfileViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () => _logout(context, vm),
              ),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: vm.formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const CircleAvatar(
                        radius: 44,
                        child: Icon(Icons.person, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Customer Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Full name
                      TextFormField(
                        controller: vm.nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: vm.emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Service Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Full address
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the city or town';
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the state';
                          }
                          return null;
                        },
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
                          if (value.isEmpty) {
                            return 'Enter a valid 6-digit Indian PIN code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // GPS location
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

                      // Save profile
                      FilledButton(
                        onPressed: vm.isSaving
                            ? null
                            : () async {
                                final message = await vm.saveProfile();
                                if (context.mounted) {
                                  _showMessage(context, message);
                                }
                              },
                        child: vm.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Profile'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
