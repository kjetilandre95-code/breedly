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
import 'package:breedly/utils/theme_colors.dart';
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
      backgroundColor: context.colors.background,
      appBar: widget.showAppBar ? AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: localizations?.searchBuyer ?? 'Search buyer...',
                  hintStyle: TextStyle(color: context.colors.textCaption),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text(
                localizations?.buyers ?? 'Buyers',
                style: AppTypography.headlineLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: true,
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
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
            tooltip: localizations?.addBuyer ?? 'Add buyer',
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
                color: context.colors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: _showSearch
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: TextStyle(color: context.colors.textPrimary),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)?.searchBuyer ?? 'Search buyer...',
                                hintStyle: TextStyle(color: context.colors.textCaption),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                            )
                          : Text(
                              AppLocalizations.of(context)?.buyers ?? 'Buyers',
                              style: AppTypography.headlineLarge.copyWith(
                                color: context.colors.textPrimary,
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
                            color: context.colors.textMuted,
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
                          icon: Icon(Icons.person_add, color: context.colors.textMuted),
                          onPressed: () => _addBuyer(context),
                          tooltip: AppLocalizations.of(context)?.newBuyer ?? 'New buyer',
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
                Icon(Icons.search_off, size: 64, color: context.colors.textDisabled),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _searchQuery.isNotEmpty 
                      ? AppLocalizations.of(context)!.noMatchesForQuery(_searchQuery)
                      : _selectedLitterFilter != null
                          ? AppLocalizations.of(context)!.noBuyersForLitter
                          : AppLocalizations.of(context)!.noBuyersRegistered,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.textMuted,
                  ),
                ),
                if (_selectedLitterFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedLitterFilter = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: Text(AppLocalizations.of(context)!.removeFilter),
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm, top: AppSpacing.sm, bottom: 100),
            children: [
              // Kull-filter
              _buildLitterFilter(primaryColor),
              
              // Seksjon: Levert
              if (delivered.isNotEmpty) ...[
              _buildSectionHeader(
                AppLocalizations.of(context)!.deliveredStatus,
                Icons.check_circle,
                AppColors.info,
                delivered.length,
              ),
              ...delivered.map((buyer) => _buildBuyerCard(buyer, primaryColor)),
            ],
            
            // Seksjon: Med reservasjon
            if (withReservation.isNotEmpty) ...[
              if (delivered.isNotEmpty) const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(
                AppLocalizations.of(context)!.withReservationSection,
                Icons.bookmark,
                AppColors.success,
                withReservation.length,
              ),
              ...withReservation.map((buyer) => _buildBuyerCard(buyer, primaryColor)),
            ],
            
            // Seksjon: Uten reservasjon (interessenter)
            if (withoutReservation.isNotEmpty) ...[
              if (delivered.isNotEmpty || withReservation.isNotEmpty) const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(
                AppLocalizations.of(context)!.interestedParties,
                Icons.person_outline,
                primaryColor,
                withoutReservation.length,
              ),
              ...withoutReservation.map((buyer) => _buildBuyerCard(buyer, primaryColor)),
              ],
            ],
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: context.colors.neutral100,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: context.colors.neutral300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedLitterFilter,
                isExpanded: true,
                hint: Row(
                  children: [
                    Icon(Icons.filter_list, color: context.colors.textMuted, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppLocalizations.of(context)!.filterByLitter,
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  ],
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.allLitters),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: AppRadius.mdAll,
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: AppRadius.lgAll,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: context.colors.textDisabled,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            localizations?.noBuyersRegistered ?? 'No buyers registered',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            localizations?.addPotentialBuyers ?? 'Add potential buyers',
            style: TextStyle(color: context.colors.textCaption, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton.icon(
            onPressed: () => _addBuyer(context),
            icon: const Icon(Icons.add),
            label: Text(localizations?.newBuyer ?? 'New buyer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xxl),
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
        ? AppColors.info 
        : (hasReservation ? AppColors.success : primaryColor);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
      ),
      child: InkWell(
        onTap: () => _showBuyerDetails(context, buyer),
        borderRadius: AppRadius.mdAll,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: AppRadius.mdAll,
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isDelivered 
                        ? AppColors.info.withValues(alpha: ThemeOpacity.medium(context))
                        : AppColors.success.withValues(alpha: ThemeOpacity.medium(context)),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    isDelivered ? AppLocalizations.of(context)!.deliveredStatus : AppLocalizations.of(context)!.reserved,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDelivered ? AppColors.info : AppColors.success,
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
                    Icon(Icons.phone, size: 14, color: context.colors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      buyer.phone!,
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              if (buyer.email != null && buyer.email!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: context.colors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        buyer.email!,
                        style: TextStyle(
                          color: context.colors.textMuted,
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
                        Icon(Icons.pets, size: 14, color: AppColors.info),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            '${litter.damName} × ${litter.sireName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
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
                        FaIcon(FontAwesomeIcons.bone, size: 14, color: AppColors.success),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          AppLocalizations.of(context)!.puppyLabelWithName(puppy.name),
                          style: TextStyle(
                            color: AppColors.success,
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
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, size: 20, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Text(AppLocalizations.of(context)!.removeReservation, style: const TextStyle(color: AppColors.warning)),
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
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_add, size: 20, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Text(AppLocalizations.of(context)!.addReservation, style: const TextStyle(color: AppColors.success)),
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
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 20, color: AppColors.info),
                        const SizedBox(width: AppSpacing.sm),
                        Text(AppLocalizations.of(context)!.markAsDelivered, style: const TextStyle(color: AppColors.info)),
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
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(AppLocalizations.of(context)!.edit),
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
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: AppColors.error)),
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
        title: Text(localizations?.removeReservation ?? 'Remove reservation'),
        content: Text(localizations?.confirmRemoveReservation ?? 'Are you sure you want to remove the reservation for this buyer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Cancel'),
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
                  SnackBar(content: Text(localizations?.reservationRemoved ?? 'Reservation removed')),
                );
              }
            },
            child: Text(localizations?.remove ?? 'Remove'),
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
          title: Text(localizations?.addReservation ?? 'Add reservation'),
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
                return Text(localizations?.noAvailablePuppiesInLitter ?? 'No available puppies in this litter.');
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(localizations?.selectPuppyToReserve ?? 'Select a puppy to reserve:'),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedPuppyId,
                    decoration: InputDecoration(
                      labelText: localizations?.selectPuppy ?? 'Select puppy',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    items: availablePuppies.map((puppy) {
                      return DropdownMenuItem(
                        value: puppy.id,
                        child: Text(
                          '${puppy.name} (${puppy.gender == 'Male' ? (localizations?.male ?? 'Male') : (localizations?.female ?? 'Female')})',
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
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedPuppyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations?.pleaseSelectPuppy ?? 'Please select a puppy')),
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
                    SnackBar(content: Text(localizations?.reservationAdded ?? 'Reservation added')),
                  );
                }
              },
              child: Text(localizations?.save ?? 'Save'),
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
        title: Text(localizations?.markAsDelivered ?? 'Mark as delivered'),
        content: Text(localizations?.confirmDelivery ?? 'Confirm that the puppy has been delivered to the buyer. This will mark the puppy as delivered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Cancel'),
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
                  SnackBar(content: Text(localizations?.puppyMarkedAsDelivered ?? 'Puppy marked as delivered!')),
                );
              }
            },
            child: Text(localizations?.confirmDeliveryButton ?? 'Confirm delivery'),
          ),
        ],
      ),
    );
  }

  void _showBuyerDetails(BuildContext context, Buyer buyer) {
    final l10n = AppLocalizations.of(context)!;
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
                UIHelpers.buildDetailRow(l10n.email, buyer.email!),
              if (buyer.phone != null && buyer.phone!.isNotEmpty)
                UIHelpers.buildDetailRow(l10n.phone, buyer.phone!),
              if (buyer.address != null && buyer.address!.isNotEmpty)
                UIHelpers.buildDetailRow(l10n.address, buyer.address!),
              if (buyer.preferences != null && buyer.preferences!.isNotEmpty)
                UIHelpers.buildDetailRow(l10n.preferences, buyer.preferences!),
              if (buyer.puppyReserved != null &&
                  buyer.puppyReserved!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                UIHelpers.buildDetailRow(l10n.reservedPuppy, buyer.puppyReserved!),
              ],
              if (buyer.notes != null && buyer.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                UIHelpers.buildDetailRow(l10n.notes, buyer.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
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
          title: Text(localizations?.addBuyer ?? 'Add buyer'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '${localizations?.name ?? 'Name'} *',
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
                      labelText: localizations?.email ?? 'Email',
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
                      labelText: localizations?.phone ?? 'Phone',
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
                      labelText: localizations?.address ?? 'Address',
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
                      labelText: localizations?.preferences ?? 'Preferences (gender/temperament)',
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
                      labelText: localizations?.notes ?? 'Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    localizations?.linkToLitterAndPuppy ?? 'Link to litter and puppy',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Litter>('litters').listenable(),
                    builder: (context, Box<Litter> litterBox, _) {
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedLitterId,
                        decoration: InputDecoration(
                          labelText: localizations?.selectLitterOptional ?? 'Select litter (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(localizations?.none ?? 'None'),
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
                            labelText: localizations?.selectPuppyOptional ?? 'Select puppy (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(localizations?.none ?? 'None'),
                            ),
                            ...litterPuppies.map((puppy) {
                              return DropdownMenuItem(
                                value: puppy.id,
                                child: Text(
                                  '${puppy.name} (${puppy.gender == 'Male' ? (localizations?.male ?? 'Male') : (localizations?.female ?? 'Female')})',
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
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations?.nameRequired ?? 'Name is required')),
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
                    SnackBar(content: Text(localizations?.buyerAdded ?? 'Buyer added')),
                  );
                }
              },
              child: Text(localizations?.save ?? 'Save'),
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
          title: Text(localizations?.editBuyer ?? 'Edit buyer'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: localizations?.name ?? 'Name',
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
                      labelText: localizations?.email ?? 'Email',
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
                      labelText: localizations?.phone ?? 'Phone',
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
                      labelText: localizations?.address ?? 'Address',
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
                      labelText: localizations?.preferences ?? 'Preferences (gender/temperament)',
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
                      labelText: localizations?.notes ?? 'Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    localizations?.linkToLitterAndPuppy ?? 'Link to litter and puppy',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<Litter>('litters').listenable(),
                    builder: (context, Box<Litter> litterBox, _) {
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedLitterId,
                        decoration: InputDecoration(
                          labelText: localizations?.selectLitterOptional ?? 'Select litter (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(localizations?.none ?? 'None'),
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
                            labelText: localizations?.selectPuppyOptional ?? 'Select puppy (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(localizations?.none ?? 'None'),
                            ),
                            ...litterPuppies.map((puppy) {
                              return DropdownMenuItem(
                                value: puppy.id,
                                child: Text(
                                  '${puppy.name} (${puppy.gender == 'Male' ? (localizations?.male ?? 'Male') : (localizations?.female ?? 'Female')})',
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
              child: Text(localizations?.cancel ?? 'Cancel'),
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
                    SnackBar(content: Text(localizations?.buyerUpdated ?? 'Buyer updated')),
                  );
                }
              },
              child: Text(localizations?.save ?? 'Save'),
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
        title: Text(localizations?.deleteBuyer ?? 'Delete buyer?'),
        content: Text(localizations?.confirmDeleteBuyer(buyer.name) ?? 'Are you sure you want to delete ${buyer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Cancel'),
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
                  SnackBar(content: Text(localizations?.buyerDeleted ?? 'Buyer deleted')),
                );
              }
            },
            child: Text(localizations?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}
