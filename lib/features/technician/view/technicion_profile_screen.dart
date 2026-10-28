import 'package:field_service/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/local_database.dart';

class TechnicianProfilePage extends StatefulWidget {
  const TechnicianProfilePage({super.key});

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String _address = '';
  bool _loading = true;
  bool _gettingLocation = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in again.');
      }

      Map<String, dynamic> profile;
      bool loadedOffline = false;

      try {
        // 1. Load profile from Supabase.
        final result = await client
            .from('profiles')
            .select('full_name, address, latitude, longitude')
            .eq('id', user.id)
            .single();

        profile = Map<String, dynamic>.from(result);

        // Email comes from Supabase Auth.
        profile['email'] = user.email ?? '';
      } catch (onlineError) {
        // 2. Fall back to SQLite.
        final LocalDatabase localDatabase = getIt<LocalDatabase>();
        final localProfile = await localDatabase.getUser(user.id);

        if (localProfile == null) {
          throw Exception(
            'Internet unavailable and no offline profile was found.',
          );
        }

        profile = Map<String, dynamic>.from(localProfile);

        // Use the authenticated email if SQLite has no email.
        profile['email'] = profile['email']?.toString() ?? user.email ?? '';

        loadedOffline = true;
      }

      if (!mounted) return;

      final latitude = (profile['latitude'] as num?)?.toDouble();
      final longitude = (profile['longitude'] as num?)?.toDouble();

      // 3. Populate all saved profile fields.
      setState(() {
        _nameController.text = profile['full_name']?.toString() ?? '';

        _emailController.text = profile['email']?.toString() ?? '';

        _addressController.text = profile['address']?.toString() ?? '';

        _latitude = latitude;
        _longitude = longitude;
      });

      // 4. Fill city, state, and PIN code from GPS coordinates.
      if (latitude != null && longitude != null) {
        try {
          final geocoding = Geocoding();
          final placemarks = await geocoding.placemarkFromCoordinates(
            _latitude!,
            _longitude!,
          );

          if (!mounted) return;

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;

            setState(() {
              // Fill only fields that are currently empty.
              if (_cityController.text.trim().isEmpty) {
                final locality = place.locality?.trim() ?? '';
                final subArea = place.subAdministrativeArea?.trim() ?? '';

                _cityController.text = locality.isNotEmpty ? locality : subArea;
              }

              if (_stateController.text.trim().isEmpty) {
                _stateController.text = place.administrativeArea?.trim() ?? '';
              }

              if (_pincodeController.text.trim().isEmpty) {
                final pin = place.postalCode?.trim() ?? '';

                if (pin.isNotEmpty) {
                  _pincodeController.text = pin;
                }
              }
            });
          }
        } catch (e) {
          // Keep saved profile data if geocoding fails.
          debugPrint('Reverse geocoding failed: $e');
        }
      }

      // if (mounted) {
      //   _showMessage(
      //     loadedOffline
      //         ? 'Showing your saved offline profile.'
      //         : 'Profile details loaded.',
      //   );
      // }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to load profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);

    try {
      // 1. Check whether device location is enabled.
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception('Please enable device location.');
      }

      // 2. Check and request location permission.
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required. Please enable it in settings.',
        );
      }

      // 3. Get the current GPS coordinates.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 4. Convert GPS coordinates into an address.
      String fullAddress = '';
      String city = '';
      String state = '';
      String pincode = '';

      try {
        final geocoding = Geocoding();
        final places = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (places.isNotEmpty) {
          final place = places.first;

          // Build the street address without duplicating components.
          final addressParts = <String>[
            if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
            if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
            if ((place.subLocality ?? '').trim().isNotEmpty)
              place.subLocality!.trim(),
          ];

          fullAddress = addressParts.toSet().join(', ');

          city = (place.locality ?? '').trim();

          // Fall back to sub-administrative area if city is absent.
          if (city.isEmpty) {
            city = (place.subAdministrativeArea ?? '').trim();
          }

          state = (place.administrativeArea ?? '').trim();
          pincode = (place.postalCode ?? '').trim();
        }
      } catch (_) {
        // GPS coordinates are still available if geocoding fails.
      }

      if (!mounted) return;

      // 5. Fill the form fields.
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;

        if (fullAddress.isNotEmpty) {
          _addressController.text = fullAddress;
        }

        if (city.isNotEmpty) {
          _cityController.text = city;
        }

        if (state.isNotEmpty) {
          _stateController.text = state;
        }

        print('pincode: $pincode');

        // Fill only a valid six-digit Indian PIN code.
        if (pincode.isNotEmpty) {
          _pincodeController.text = pincode;
        }
      });

      if (fullAddress.isEmpty &&
          city.isEmpty &&
          state.isEmpty &&
          pincode.isEmpty) {
        _showMessage(
          'GPS detected, but the address could not be found. '
          'Please enter the address manually.',
        );
      } else {
        _showMessage('Location detected. Please verify the address details.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to get location: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      _showMessage('Please sign in again.');
      return;
    }

    final address = _addressController.text.trim();

    setState(() => _saving = true);

    try {
      // Save profile changes locally first.
      final LocalDatabase localDatabase = getIt<LocalDatabase>();

      await localDatabase.updateLocalAddress(
        userId: user.id,
        address: address,
        latitude: _latitude,
        longitude: _longitude,
      );

      // Save the name and address online.
      await client
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'address': address,
            'latitude': _latitude,
            'longitude': _longitude,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);

      await localDatabase.markUserSynced(user.id);

      if (!mounted) return;
      _showMessage('Profile saved online and offline.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        'Profile saved locally if possible. Online sync pending: $e',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/technician');
            }
          },
        ),
        automaticallyImplyLeading: true,
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout != true) return;

              try {
                await Supabase.instance.client.auth.signOut();

                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const CircleAvatar(
                  radius: 44,
                  child: Icon(Icons.person, size: 48),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Technician Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const Text(
                  'Service Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full address
                    TextFormField(
                      controller: _addressController,
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
                      controller: _cityController,
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
                      controller: _stateController,
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
                      controller: _pincodeController,
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
                        if (!RegExp(r'^[0-9]').hasMatch(value.trim())) {
                          return 'Enter a valid 6-digit Indian PIN code';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // GPS location
                    OutlinedButton.icon(
                      onPressed: _gettingLocation ? null : _getCurrentLocation,
                      icon: _gettingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _gettingLocation
                            ? 'Getting location...'
                            : 'Use current location',
                      ),
                    ),

                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'GPS: $_latitude, $_longitude',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: Text(_saving ? 'Saving...' : 'Save Profile'),
                ),
              ],
            ),
    );
  }
}
