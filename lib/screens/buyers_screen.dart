import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/utils/id_generator.dart';
import 'package:breedly/utils/ui_helpers.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class BuyersScreen extends StatefulWidget {
  final bool showAppBar;

  const BuyersScreen({super.key, this.showAppBar = true});

  @override
  State<BuyersScreen> createState() => _BuyersScreenState();
}

class _BuyersScreenState extends State<BuyersScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLitterFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar ? AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: AppColors.neutral900),
                decoration: InputDecoration(
                  hintText: localizations?.search ?? 'Søk etter kjøper...',
                  hintStyle: TextStyle(color: AppColors.neutral500),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text(
                localizations?.buyers ?? 'Kjøpere',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.neutral900,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _addBuyer(context),
            tooltip: localizations?.addBuyer ?? 'Ny kjøper',
          ),
        ],
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.showAppBar) ...[
              // Custom header når app bar er skjult
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: _showSearch
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: TextStyle(color: AppColors.neutral900),
                              decoration: InputDecoration(
                                hintText: 'Søk etter kjøper...',
                                hintStyle: TextStyle(color: AppColors.neutral500),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                            )
                          : Text(
                              'Kjøpere',
                              style: AppTypography.headlineLarge.copyWith(
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showSearch ? Icons.close : Icons.search,
                            color: AppColors.neutral600,
                          ),
                          onPressed: () {
                            setState(() {
                              _showSearch = !_showSearch;
                              if (!_showSearch) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.person_add, color: AppColors.neutral600),
                          onPressed: () => _addBuyer(context),
                          tooltip: 'Ny kjøper',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: _buildBuyersListWithSections(primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyersListWithSections(Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Buyer>('buyers').listenable(),
      builder: (context, Box<Buyer> box, _) {
        if (box.isEmpty) {
          return _buildEmptyState(primaryColor);
        }

        var allBuyers = box.values.toList();
        
        // Filtrer basert på søk
        if (_searchQuery.isNotEmpty) {
          allBuyers = allBuyers.where((buyer) {
            return buyer.name.toLowerCase().contains(_searchQuery) ||
                (buyer.email?.toLowerCase().contains(_searchQuery) ?? false) ||
                (buyer.phone?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();
        }

        // Filtrer basert på valgt kull
        if (_selectedLitterFilter != null) {
          allBuyers = allBuyers.where((b) => b.litterId == _selectedLitterFilter).toList();
        }

        // Get puppy box for status checking
        final puppyBox = Hive.box<Puppy>('puppies');
        
        // Helper function to check if a buyer's reserved puppy is delivered
        bool isDelivered(Buyer buyer) {
          if (buyer.puppyReserved == null || buyer.puppyReserved!.isEmpty) return false;
          final puppy = puppyBox.values.firstWhere(
            (p) => p.id == buyer.puppyReserved,
            orElse: () => Puppy(
              id: '',
              name: '',
              litterId: '',
              dateOfBirth: DateTime.now(),
              gender: '',
              color: '',
            ),
          );
          return puppy.status == 'Delivered';
        }
        
        // Del opp i tre kategorier: levert, reservert, interessenter
        final delivered = allBuyers
            .where((b) => b.puppyReserved != null && b.puppyReserved!.isNotEmpty && isDelivered(b))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        
        final withReservation = allBuyers
            .where((b) => b.puppyReserved != null && b.puppyReserved!.isNotEmpty && !isDelivered(b))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        
        final withoutReservation = allBuyers
            .where((b) => b.puppyReserved == null || b.puppyReserved!.isEmpty)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        if (allBuyers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty 
                      ? 'Ingen treff på "$_searchQuery"'
                      : _selectedLitterFilter != null
                          ? 'Ingen kjøpere for dette kullet'
                          : 'Ingen kjøpere registrert',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (_selectedLitterFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedLitterFilter = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Fjern filter'),
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 100),
          children: [
            // Kull-filter
            _buildLitterFilter(primaryColor),
            
            // Seksjon: Levert
            if (delivered.isNotEmpty) ...[
              _buildSectionHeader(
                'Levert',
                Icons.check_circle,
                Colors.blue,
                delivered.length,
              ),
              ...delivered.map((buyer) => _buildBuyerCard(buyer, primaryColor)),
            ],
            
            // Seksjon: Med reservasjon
            if (withReservation.isNotEmpty) ...[
              if (delivered.isNotEmpty) const SizedBox(height: 16),
              _buildSectionHeader(
                'Med reservasjon',
                Icons.bookmark,
                Colors.green,
                withReservation.length,
              ),
              ...withReservation.map((buyer) => _buildBuyerCard(buyer, primaryColor)),
            ],
            
            // Seksjon: Uten reservasjon (interessenter)
            if (withoutReservation.isNotEmpty) ...[
              if (delivered.isNotEmpty || withReservation.isNotEmpty) const SizedBox(height: 16),
              _buildSectionHeader(
                'Interessenter',
                Icons.person_outline,
                primaryColor,
                withoutReservation.length,
              ),
              ...withoutReservation.map((buyer) => _buildBuyerCard(buyer, primaryColor)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLitterFilter(Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Litter>('litters').listenable(),
      builder: (context, Box<Litter> litterBox, _) {
        final litters = litterBox.values.toList();
        
        if (litters.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedLitterFilter,
                isExpanded: true,
                hint: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Filtrer på kull',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Alle kull'),
                  ),
                  ...litters.map((litter) {
                    return DropdownMenuItem<String?>(
                      value: litter.id,
                      child: Text(
                        '${litter.damName} × ${litter.sireName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLitterFilter = value;
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localizations?.noBuyersRegistered ?? 'Ingen kjøpere registrert',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            localizations?.addPotentialBuyers ?? 'Legg til potensielle kjøpere',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addBuyer(context),
            icon: const Icon(Icons.add),
            label: Text(localizations?.newBuyer ?? 'Ny kjøper'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerCard(Buyer buyer, Color primaryColor) {
    final hasReservation = buyer.puppyReserved != null && buyer.puppyReserved!.isNotEmpty;
    
    // Check if the puppy is delivered
    bool isDelivered = false;
    if (hasReservation) {
      final puppyBox = Hive.box<Puppy>('puppies');
      final puppy = puppyBox.values.firstWhere(
        (p) => p.id == buyer.puppyReserved,
        orElse: () => Puppy(
          id: '',
          name: '',
          litterId: '',
          dateOfBirth: DateTime.now(),
          gender: '',
          color: '',
        ),
      );
      isDelivered = puppy.status == 'Delivered';
    }
    
    // Determine colors and icons based on status
    Color statusColor = isDelivered 
        ? Colors.blue 
        : (hasReservation ? Colors.green : primaryColor);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showBuyerDetails(context, buyer),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDelivered 
                  ? Icons.check_circle 
                  : (hasReservation ? Icons.person_pin : Icons.person_rounded),
              color: statusColor,
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  buyer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (hasReservation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered 
                        ? Colors.blue.withValues(alpha: ThemeOpacity.medium(context))
                        : Colors.green.withValues(alpha: ThemeOpacity.medium(context)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDelivered ? 'Levert' : 'Reservert',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDelivered ? Colors.blue : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              if (buyer.phone != null && buyer.phone!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      buyer.phone!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              if (buyer.email != null && buyer.email!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        buyer.email!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (buyer.litterId != null && buyer.litterId!.isNotEmpty)
                ValueListenableBuilder(
                  valueListenable: Hive.box<Litter>('litters').listenable(),
                  builder: (context, Box<Litter> litterBox, _) {
                    final litter = litterBox.values.firstWhere(
                      (l) => l.id == buyer.litterId,
                      orElse: () => Litter(
                        id: '',
                        damId: '',
                        sireId: '',
                        damName: '',
                        sireName: '',
                        dateOfBirth: DateTime.now(),
                        numberOfPuppies: 0,
                        breed: '',
                      ),
                    );
                    if (litter.id.isEmpty) return const SizedBox.shrink();
                    return Row(
                      children: [
                        Icon(Icons.pets, size: 14, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${litter.damName} × ${litter.sireName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              if (buyer.puppyReserved != null && buyer.puppyReserved!.isNotEmpty)
                ValueListenableBuilder(
                  valueListenable: Hive.box<Puppy>('puppies').listenable(),
                  builder: (context, Box<Puppy> puppyBox, _) {
                    final puppy = puppyBox.values.firstWhere(
                      (p) => p.id == buyer.puppyReserved,
                      orElse: () => Puppy(
                        id: '',
                        name: '',
                        litterId: '',
                        dateOfBirth: DateTime.now(),
                        gender: '',
                        color: '',
                      ),
                    );
                    if (puppy.id.isEmpty) return const SizedBox.shrink();
                    return Row(
                      children: [
                        FaIcon(FontAwesomeIcons.bone, size: 14, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Valp: ${puppy.name}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) {
              final hasReservation = buyer.puppyReserved != null && buyer.puppyReserved!.isNotEmpty;
              
              // Check if the reserved puppy is already delivered
              bool isDelivered = false;
              if (hasReservation) {
                final puppyBox = Hive.box<Puppy>('puppies');
                final puppy = puppyBox.values.firstWhere(
                  (p) => p.id == buyer.puppyReserved,
                  orElse: () => Puppy(
                    id: '',
                    name: '',
                    litterId: '',
                    dateOfBirth: DateTime.now(),
                    gender: '',
                    color: '',
                  ),
                );
                isDelivered = puppy.status == 'Delivered';
              }
              
              return [
                // Toggle reservation option
                if (hasReservation)
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.cancel, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Fjern reservasjon', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          _removeReservation(context, buyer);
                        }
                      });
                    },
                  )
                else if (buyer.litterId != null && buyer.litterId!.isNotEmpty)
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.bookmark_add, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Legg til reservasjon', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          _addReservation(context, buyer);
                        }
                      });
                    },
                  ),
                // Mark as delivered option (only if reservation exists and not yet delivered)
                if (hasReservation && !isDelivered)
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Marker som levert', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          _markAsDelivered(context, buyer);
                        }
                      });
                    },
                  ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Rediger'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (context.mounted) {
                        _editBuyer(context, buyer);
                      }
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Slett', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    _deleteBuyer(context, buyer);
                  },
                ),
              ];
            },
          ),
        ),
      ),
    );
  }

  void _removeReservation(BuildContext context, Buyer buyer) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.removeReservation ?? 'Fjern reservasjon'),
        content: Text(localizations?.confirmRemoveReservation ?? 'Er du sikker på at du vil fjerne reservasjonen for denne kjøperen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Get the puppy and reset its status
              if (buyer.puppyReserved != null) {
                final puppyBox = Hive.box<Puppy>('puppies');
                for (var puppy in puppyBox.values) {
                  if (puppy.id == buyer.puppyReserved) {
                    puppy.status = 'Available';
                    puppy.buyerName = null;
                    puppy.buyerContact = null;
                    await puppy.save();
                    
                    // Save puppy to Firebase
                    final userId = AuthService().currentUser?.uid;
                    if (userId != null) {
                      await CloudSyncService().savePuppy(
                        userId: userId,
                        litterId: puppy.litterId,
                        puppyId: puppy.id,
                        puppyData: puppy.toJson(),
                      );
                    }
                    break;
                  }
                }
              }
              
              // Update buyer
              buyer.puppyReserved = null;
              await buyer.save();
              
              // Save to Firebase
              final userId = AuthService().currentUser?.uid;
              if (userId != null) {
                await CloudSyncService().saveBuyer(
                  userId: userId,
                  buyerId: buyer.id,
                  buyerData: buyer.toJson(),
                );
              }
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reservasjon fjernet')),
                );
              }
            },
            child: const Text('Fjern'),
          ),
        ],
      ),
    );
  }

  void _addReservation(BuildContext context, Buyer buyer) {
    String? selectedPuppyId;
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations?.addReservation ?? 'Legg til reservasjon'),
          content: ValueListenableBuilder(
            valueListenable: Hive.box<Puppy>('puppies').listenable(),
            builder: (context, Box<Puppy> puppyBox, _) {
              // Get available puppies from the buyer's associated litter
              final availablePuppies = puppyBox.values
                  .where((p) => 
                      p.litterId == buyer.litterId && 
                      (p.status == 'Available' || p.status == null))
                  .toList();
              
              if (availablePuppies.isEmpty) {
                return Text(localizations?.noAvailablePuppiesInLitter ?? 'Ingen ledige valper i dette kullet.');
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(localizations?.selectPuppyToReserve ?? 'Velg en valp å reservere:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedPuppyId,
                    decoration: InputDecoration(
                      labelText: localizations?.selectPuppy ?? 'Velg valp',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    items: availablePuppies.map((puppy) {
                      return DropdownMenuItem(
                        value: puppy.id,
                        child: Text(
                          '${puppy.name} (${puppy.gender == 'Male' ? (localizations?.male ?? 'Hann') : (localizations?.female ?? 'Tispe')})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPuppyId = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations?.cancel ?? 'Avbryt'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedPuppyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vennligst velg en valp')),
                  );
                  return;
                }
                
                // Update the puppy
                final puppyBox = Hive.box<Puppy>('puppies');
                for (var puppy in puppyBox.values) {
                  if (puppy.id == selectedPuppyId) {
                    puppy.status = 'Reserved';
                    puppy.buyerName = buyer.name;
                    puppy.buyerContact = buyer.phone;
                    await puppy.save();
                    
                    // Save puppy to Firebase
                    final userId = AuthService().currentUser?.uid;
                    if (userId != null) {
                      await CloudSyncService().savePuppy(
                        userId: userId,
                        litterId: puppy.litterId,
                        puppyId: puppy.id,
                        puppyData: puppy.toJson(),
                      );
                    }
                    break;
                  }
                }
                
                // Update buyer
                buyer.puppyReserved = selectedPuppyId;
                await buyer.save();
                
                // Save to Firebase
                final userId = AuthService().currentUser?.uid;
                if (userId != null) {
                  await CloudSyncService().saveBuyer(
                    userId: userId,
                    buyerId: buyer.id,
                    buyerData: buyer.toJson(),
                  );
                }
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations?.reservationAdded ?? 'Reservasjon lagt til')),
                  );
                }
              },
              child: Text(localizations?.save ?? 'Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _markAsDelivered(BuildContext context, Buyer buyer) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.markAsDelivered ?? 'Marker som levert'),
        content: Text(localizations?.confirmDelivery ?? 'Bekreft at valpen er levert til kjøperen. Dette vil markere valpen som levert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Update the puppy status to Delivered
              if (buyer.puppyReserved != null) {
                final puppyBox = Hive.box<Puppy>('puppies');
                for (var puppy in puppyBox.values) {
                  if (puppy.id == buyer.puppyReserved) {
                    puppy.status = 'Delivered';
                    puppy.deliveredDate = DateTime.now();
                    puppy.soldDate = DateTime.now();
                    await puppy.save();
                    
                    // Save puppy to Firebase
                    final userId = AuthService().currentUser?.uid;
                    if (userId != null) {
                      await CloudSyncService().savePuppy(
                        userId: userId,
                        litterId: puppy.litterId,
                        puppyId: puppy.id,
                        puppyData: puppy.toJson(),
                      );
                    }
                    break;
                  }
                }
              }
              
              // Save buyer changes to Firebase (in case we want to track delivery)
              final userId = AuthService().currentUser?.uid;
              if (userId != null) {
                await CloudSyncService().saveBuyer(
                  userId: userId,
                  buyerId: buyer.id,
                  buyerData: buyer.toJson(),
                );
              }
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations?.puppyMarkedAsDelivered ?? 'Valp markert som levert!')),
                );
              }
            },
            child: Text(localizations?.confirmDeliveryButton ?? 'Bekreft levering'),
          ),
        ],
      ),
    );
  }

  void _showBuyerDetails(BuildContext context, Buyer buyer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(buyer.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (buyer.email != null && buyer.email!.isNotEmpty)
                UIHelpers.buildDetailRow('E-post', buyer.email!),
              if (buyer.phone != null && buyer.phone!.isNotEmpty)
                UIHelpers.buildDetailRow('Telefon', buyer.phone!),
              if (buyer.address != null && buyer.address!.isNotEmpty)
                UIHelpers.buildDetailRow('Adresse', buyer.address!),
              if (buyer.preferences != null && buyer.preferences!.isNotEmpty)
                UIHelpers.buildDetailRow('Preferanser', buyer.preferences!),
              if (buyer.puppyReserved != null &&
                  buyer.puppyReserved!.isNotEmpty) ...[
                const SizedBox(height: 12),
                UIHelpers.buildDetailRow('Reservert valp', buyer.puppyReserved!),
              ],
              if (buyer.notes != null && buyer.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                UIHelpers.buildDetailRow('Notater', buyer.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lukk'),
          ),
        ],
      ),
    );
  }

  void _addBuyer(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController preferencesController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    
    String? selectedLitterId;
    String? selectedPuppyId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations?.addBuyer ?? 'Legg til kjøper'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '${localizations?.name ?? 'Navn'} *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: localizations?.email ?? 'E-post',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: localizations?.phone ?? 'Telefon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: localizations?.address ?? 'Adresse',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: preferencesController,
                    decoration: InputDecoration(
                      labelText: localizations?.preferences ?? 'Preferanser (kjønn/lynne)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notater',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Knytt til kull og valp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Litter>('litters').listenable(),
                    builder: (context, Box<Litter> litterBox, _) {
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedLitterId,
                        decoration: InputDecoration(
                          labelText: 'Velg kull (valgfritt)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Ingen'),
                          ),
                          ...litterBox.values.map((litter) {
                            return DropdownMenuItem(
                              value: litter.id,
                              child: Text(
                                '${litter.damName} × ${litter.sireName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedLitterId = value;
                            selectedPuppyId = null; // Reset puppy when litter changes
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (selectedLitterId != null)
                    ValueListenableBuilder(
                      valueListenable: Hive.box<Puppy>('puppies').listenable(),
                      builder: (context, Box<Puppy> puppyBox, _) {
                        final litterPuppies = puppyBox.values
                            .where((p) => p.litterId == selectedLitterId)
                            .toList();
                        
                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedPuppyId,
                          decoration: InputDecoration(
                            labelText: 'Velg valp (valgfritt)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Ingen'),
                            ),
                            ...litterPuppies.map((puppy) {
                              return DropdownMenuItem(
                                value: puppy.id,
                                child: Text(
                                  '${puppy.name} (${puppy.gender == 'Male' ? 'Hann' : 'Tispe'})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPuppyId = value;
                            });
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navn er påkrevd')),
                  );
                  return;
                }

                final buyer = Buyer(
                  id: IdGenerator.generateId(),
                  name: nameController.text,
                  email: emailController.text.isEmpty ? null : emailController.text,
                  phone: phoneController.text.isEmpty ? null : phoneController.text,
                  address: addressController.text.isEmpty ? null : addressController.text,
                  preferences: preferencesController.text.isEmpty ? null : preferencesController.text,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  litterId: selectedLitterId,
                  puppyReserved: selectedPuppyId,
                  dateAdded: DateTime.now(),
                );

                final buyerBox = Hive.box<Buyer>('buyers');
                await buyerBox.put(buyer.id, buyer);

                // Save to Firebase
                final userId = AuthService().currentUser?.uid;
                if (userId != null) {
                  await CloudSyncService().saveBuyer(
                    userId: userId,
                    buyerId: buyer.id,
                    buyerData: buyer.toJson(),
                  );
                }

                // If a puppy was selected, update the puppy's buyer info
                if (selectedPuppyId != null) {
                  final puppyBox = Hive.box<Puppy>('puppies');
                  for (var puppy in puppyBox.values) {
                    if (puppy.id == selectedPuppyId) {
                      puppy.buyerName = nameController.text;
                      puppy.buyerContact = phoneController.text.isEmpty ? null : phoneController.text;
                      puppy.save();
                      break;
                    }
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kjøper lagt til')),
                  );
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _editBuyer(BuildContext context, Buyer buyer) {
    final localizations = AppLocalizations.of(context);
    TextEditingController nameController =
        TextEditingController(text: buyer.name);
    TextEditingController emailController =
        TextEditingController(text: buyer.email ?? '');
    TextEditingController phoneController =
        TextEditingController(text: buyer.phone ?? '');
    TextEditingController addressController =
        TextEditingController(text: buyer.address ?? '');
    TextEditingController preferencesController =
        TextEditingController(text: buyer.preferences ?? '');
    TextEditingController notesController =
        TextEditingController(text: buyer.notes ?? '');
    
    String? selectedLitterId = buyer.litterId;
    String? selectedPuppyId = buyer.puppyReserved;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations?.editBuyer ?? 'Rediger kjøper'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Navn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-post',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: preferencesController,
                    decoration: InputDecoration(
                      labelText: 'Preferanser (kjønn/lynne)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notater',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Knytt til kull og valp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Litter>('litters').listenable(),
                    builder: (context, Box<Litter> litterBox, _) {
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedLitterId,
                        decoration: InputDecoration(
                          labelText: 'Velg kull (valgfritt)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Ingen'),
                          ),
                          ...litterBox.values.map((litter) {
                            return DropdownMenuItem(
                              value: litter.id,
                              child: Text(
                                '${litter.damName} × ${litter.sireName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedLitterId = value;
                            selectedPuppyId = null; // Reset puppy when litter changes
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (selectedLitterId != null)
                    ValueListenableBuilder(
                      valueListenable: Hive.box<Puppy>('puppies').listenable(),
                      builder: (context, Box<Puppy> puppyBox, _) {
                        final litterPuppies = puppyBox.values
                            .where((p) => p.litterId == selectedLitterId)
                            .toList();
                        
                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedPuppyId,
                          decoration: InputDecoration(
                            labelText: 'Velg valp (valgfritt)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Ingen'),
                            ),
                            ...litterPuppies.map((puppy) {
                              return DropdownMenuItem(
                                value: puppy.id,
                                child: Text(
                                  '${puppy.name} (${puppy.gender == 'Male' ? 'Hann' : 'Tispe'})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPuppyId = value;
                            });
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () async {
                buyer.name = nameController.text;
                buyer.email =
                    emailController.text.isEmpty ? null : emailController.text;
                buyer.phone =
                    phoneController.text.isEmpty ? null : phoneController.text;
                buyer.address = addressController.text.isEmpty
                    ? null
                    : addressController.text;
                buyer.preferences = preferencesController.text.isEmpty
                    ? null
                    : preferencesController.text;
                buyer.notes = notesController.text.isEmpty ? null : notesController.text;
                buyer.litterId = selectedLitterId;
                buyer.puppyReserved = selectedPuppyId;
                buyer.save();
                
                // Save to Firebase
                final userId = AuthService().currentUser?.uid;
                if (userId != null) {
                  await CloudSyncService().saveBuyer(
                    userId: userId,
                    buyerId: buyer.id,
                    buyerData: buyer.toJson(),
                  );
                }
                
                // If a puppy was selected, update the puppy's buyer info
                if (selectedPuppyId != null) {
                  final puppyBox = Hive.box<Puppy>('puppies');
                  for (var puppy in puppyBox.values) {
                    if (puppy.id == selectedPuppyId) {
                      puppy.buyerName = nameController.text;
                      puppy.buyerContact = phoneController.text.isEmpty ? null : phoneController.text;
                      puppy.save();
                      break;
                    }
                  }
                }
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations?.buyerUpdated ?? 'Kjøper oppdatert')),
                  );
                }
              },
              child: Text(localizations?.save ?? 'Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBuyer(BuildContext context, Buyer buyer) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteBuyer ?? 'Slett kjøper?'),
        content: Text(localizations?.confirmDeleteBuyer(buyer.name) ?? 'Er du sikker på at du vil slette ${buyer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              // Delete from Firebase first
              final userId = AuthService().currentUser?.uid;
              if (userId != null) {
                await CloudSyncService().deleteBuyer(
                  userId: userId,
                  buyerId: buyer.id,
                );
              }
              // Then delete from Hive
              await buyer.delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations?.buyerDeleted ?? 'Kjøper slettet')),
                );
              }
            },
            child: Text(localizations?.delete ?? 'Slett'),
          ),
        ],
      ),
    );
  }
}
