import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/kennel_profile.dart';
import 'package:breedly/utils/dog_breeds.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';

class KennelProfileScreen extends StatefulWidget {
  const KennelProfileScreen({super.key});

  @override
  State<KennelProfileScreen> createState() => _KennelProfileScreenState();
}

class _KennelProfileScreenState extends State<KennelProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kennelNameController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;
  List<String> _selectedBreeds = [];
  KennelProfile? _profile;

  @override
  void initState() {
    super.initState();
    _kennelNameController = TextEditingController();
    _contactEmailController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadProfile();
  }

  void _loadProfile() {
    final box = Hive.box<KennelProfile>('kennel_profile');
    if (box.isNotEmpty) {
      _profile = box.values.first;
      _kennelNameController.text = _profile?.kennelName ?? '';
      _contactEmailController.text = _profile?.contactEmail ?? '';
      _contactPhoneController.text = _profile?.contactPhone ?? '';
      _addressController.text = _profile?.address ?? '';
      _websiteController.text = _profile?.website ?? '';
      _descriptionController.text = _profile?.description ?? '';
      _selectedBreeds = List<String>.from(_profile?.breeds ?? []);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _kennelNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<KennelProfile>('kennel_profile');
      
      if (_profile != null) {
        _profile!.kennelName = _kennelNameController.text.isEmpty ? null : _kennelNameController.text;
        _profile!.breeds = _selectedBreeds;
        _profile!.contactEmail = _contactEmailController.text.isEmpty ? null : _contactEmailController.text;
        _profile!.contactPhone = _contactPhoneController.text.isEmpty ? null : _contactPhoneController.text;
        _profile!.address = _addressController.text.isEmpty ? null : _addressController.text;
        _profile!.website = _websiteController.text.isEmpty ? null : _websiteController.text;
        _profile!.description = _descriptionController.text.isEmpty ? null : _descriptionController.text;
        await _profile!.save();
      } else {
        final newProfile = KennelProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          kennelName: _kennelNameController.text.isEmpty ? null : _kennelNameController.text,
          breeds: _selectedBreeds,
          contactEmail: _contactEmailController.text.isEmpty ? null : _contactEmailController.text,
          contactPhone: _contactPhoneController.text.isEmpty ? null : _contactPhoneController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          website: _websiteController.text.isEmpty ? null : _websiteController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        );
        await box.put('profile', newProfile);
        _profile = newProfile;
      }

      // Save to Firebase
      final userId = AuthService().currentUser?.uid;
      if (userId != null && _profile != null) {
        await CloudSyncService().saveKennelProfile(
          userId: userId,
          profileData: _profile!.toJson(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kennelprofil lagret')),
        );
      }
    }
  }

  void _showBreedSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => BreedSelectionDialog(
        allBreeds: dogBreeds,
        selectedBreeds: _selectedBreeds,
        onBreedsSelected: (breeds) {
          setState(() {
            _selectedBreeds = breeds;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kennelprofil'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.neutral900,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Lagre',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Kennel Name Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.home_work_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Kennelinformasjon',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _kennelNameController,
                        decoration: InputDecoration(
                          labelText: 'Kennelnavn',
                          hintText: 'F.eks. "Nordlys Kennel"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Beskrivelse (valgfritt)',
                          hintText: 'Fortell litt om din kennel...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Breeds Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.pets_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Raser',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Velg rasene du er oppdretter av',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _showBreedSelectionDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedBreeds.isEmpty
                                      ? 'Trykk for å velge raser...'
                                      : '${_selectedBreeds.length} ${_selectedBreeds.length == 1 ? 'rase' : 'raser'} valgt',
                                  style: TextStyle(
                                    color: _selectedBreeds.isEmpty ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ),
                              const Icon(Icons.add_circle_outline, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedBreeds.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedBreeds.map((breed) {
                            return Chip(
                              label: Text(breed),
                              backgroundColor: primaryColor.withValues(alpha: 0.2),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _selectedBreeds.remove(breed);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.contact_mail_rounded,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Kontaktinformasjon',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _contactEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-post (valgfritt)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Telefon (valgfritt)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Adresse (valgfritt)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'Nettside (valgfritt)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(Icons.language_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Lagre kennelprofil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class BreedSelectionDialog extends StatefulWidget {
  final List<String> allBreeds;
  final List<String> selectedBreeds;
  final Function(List<String>) onBreedsSelected;

  const BreedSelectionDialog({
    super.key,
    required this.allBreeds,
    required this.selectedBreeds,
    required this.onBreedsSelected,
  });

  @override
  State<BreedSelectionDialog> createState() => _BreedSelectionDialogState();
}

class _BreedSelectionDialogState extends State<BreedSelectionDialog> {
  late TextEditingController _searchController;
  late List<String> _filteredBreeds;
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredBreeds = widget.allBreeds;
    _selected = List<String>.from(widget.selectedBreeds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBreeds(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBreeds = widget.allBreeds;
      } else {
        _filteredBreeds = widget.allBreeds
            .where((breed) => breed.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Velg raser'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterBreeds,
              decoration: InputDecoration(
                hintText: 'Søk rase...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selected.length} valgt',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredBreeds.isEmpty
                  ? Center(
                      child: Text(
                        'Ingen raser funnet for "${_searchController.text}"',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredBreeds.length,
                      itemBuilder: (context, index) {
                        final breed = _filteredBreeds[index];
                        final isSelected = _selected.contains(breed);
                        return CheckboxListTile(
                          title: Text(breed),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(breed);
                              } else {
                                _selected.remove(breed);
                              }
                            });
                          },
                          activeColor: Theme.of(context).primaryColor,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onBreedsSelected(_selected);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text('Bekreft', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
