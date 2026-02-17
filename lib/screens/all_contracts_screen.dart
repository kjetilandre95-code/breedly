import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:breedly/models/purchase_contract.dart';
import 'package:breedly/models/breeding_contract.dart';
import 'package:breedly/models/co_ownership_contract.dart';
import 'package:breedly/models/foster_contract.dart';
import 'package:breedly/models/reservation_contract.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/page_info_helper.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/screens/purchase_contract_screen.dart';
import 'package:breedly/screens/reservation_contract_screen.dart';
import 'package:breedly/screens/breeding_contract_screen.dart';
import 'package:breedly/screens/co_ownership_contract_screen.dart';
import 'package:breedly/screens/foster_contract_screen.dart';

class AllContractsScreen extends StatefulWidget {
  const AllContractsScreen({super.key});

  @override
  State<AllContractsScreen> createState() => _AllContractsScreenState();
}

class _AllContractsScreenState extends State<AllContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getBuyerName(String buyerId) {
    final buyerBox = Hive.box<Buyer>('buyers');
    final buyer = buyerBox.values.where((b) => b.id == buyerId).firstOrNull;
    return buyer?.name ?? 'Ukjent kjøper';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrakter'),
        actions: [
          PageInfoHelper.buildInfoButton(
            context,
            title: PageInfoContent.contractsScreen.title,
            description: PageInfoContent.contractsScreen.description,
            features: PageInfoContent.contractsScreen.features,
            tip: PageInfoContent.contractsScreen.tip,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: themeColor,
          labelColor: themeColor,
          unselectedLabelColor: context.colors.textCaption,
          tabs: const [
            Tab(text: 'Kjøpskontrakter'),
            Tab(text: 'Reservasjoner'),
            Tab(text: 'Paringsavtaler'),
            Tab(text: 'Sameie'),
            Tab(text: 'Fôrvertsavtaler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchaseContractsList(),
          _buildReservationContractsList(),
          _buildBreedingContractsList(),
          _buildCoOwnershipContractsList(),
          _buildFosterContractsList(),
        ],
      ),
    );
  }

  Widget _buildPurchaseContractsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<PurchaseContract>('purchase_contracts').listenable(),
      builder: (context, Box<PurchaseContract> box, _) {
        final contracts = box.values.toList()
          ..sort((a, b) => b.contractDate.compareTo(a.contractDate));

        if (contracts.isEmpty) {
          return _buildEmptyState(
            'Ingen kjøpskontrakter',
            Icons.description_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            final puppyBox = Hive.box<Puppy>('puppies');
            final puppy = puppyBox.values.where((p) => p.id == contract.puppyId).firstOrNull;

            return _buildContractCard(
              title: puppy?.name ?? 'Ukjent valp',
              subtitle: _getBuyerName(contract.buyerId),
              date: contract.contractDate,
              status: contract.status ?? 'Draft',
              icon: Icons.shopping_cart_rounded,
              color: _getStatusColor(contract.status ?? 'Draft'),
              onEdit: puppy != null ? () => _editPurchaseContract(contract, puppy) : null,
              onDelete: () => _deletePurchaseContract(contract),
            );
          },
        );
      },
    );
  }

  Widget _buildReservationContractsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ReservationContract>('reservation_contracts').listenable(),
      builder: (context, Box<ReservationContract> box, _) {
        final contracts = box.values.toList()
          ..sort((a, b) => b.contractDate.compareTo(a.contractDate));

        if (contracts.isEmpty) {
          return _buildEmptyState(
            'Ingen reservasjoner',
            Icons.bookmark_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            final puppyBox = Hive.box<Puppy>('puppies');
            final puppy = puppyBox.values.where((p) => p.id == contract.puppyId).firstOrNull;

            return _buildContractCard(
              title: puppy?.name ?? 'Ukjent valp',
              subtitle: _getBuyerName(contract.buyerId),
              date: contract.contractDate,
              status: contract.status ?? 'Draft',
              icon: Icons.bookmark_rounded,
              color: _getStatusColor(contract.status ?? 'Draft'),
              onEdit: puppy != null ? () => _editReservationContract(contract, puppy) : null,
              onDelete: () => _deleteReservationContract(contract),
            );
          },
        );
      },
    );
  }

  Widget _buildBreedingContractsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<BreedingContract>('breeding_contracts').listenable(),
      builder: (context, Box<BreedingContract> box, _) {
        final contracts = box.values.toList()
          ..sort((a, b) => b.contractDate.compareTo(a.contractDate));

        if (contracts.isEmpty) {
          return _buildEmptyState(
            'Ingen paringsavtaler',
            Icons.favorite_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            final dogBox = Hive.box<Dog>('dogs');
            final stud = dogBox.values.where((d) => d.id == contract.studId).firstOrNull;
            final dam = dogBox.values.where((d) => d.id == contract.damId).firstOrNull;

            return _buildContractCard(
              title: '${stud?.name ?? "?"} × ${dam?.name ?? "?"}',
              subtitle: contract.studOwnerName,
              date: contract.contractDate,
              status: contract.status ?? 'Draft',
              icon: Icons.favorite_rounded,
              color: _getStatusColor(contract.status ?? 'Draft'),
              onEdit: () => _editBreedingContract(contract, stud, dam),
              onDelete: () => _deleteBreedingContract(contract),
            );
          },
        );
      },
    );
  }

  Widget _buildCoOwnershipContractsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<CoOwnershipContract>('co_ownership_contracts').listenable(),
      builder: (context, Box<CoOwnershipContract> box, _) {
        final contracts = box.values.toList()
          ..sort((a, b) => b.contractDate.compareTo(a.contractDate));

        if (contracts.isEmpty) {
          return _buildEmptyState(
            'Ingen sameieavtaler',
            Icons.people_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            final dogBox = Hive.box<Dog>('dogs');
            final dog = dogBox.values.where((d) => d.id == contract.dogId).firstOrNull;

            return _buildContractCard(
              title: dog?.name ?? 'Ukjent hund',
              subtitle: '${contract.owner1Name} & ${contract.owner2Name}',
              date: contract.contractDate,
              status: contract.status ?? 'Draft',
              icon: Icons.people_rounded,
              color: _getStatusColor(contract.status ?? 'Draft'),
              onEdit: () => _editCoOwnershipContract(contract, dog),
              onDelete: () => _deleteCoOwnershipContract(contract),
            );
          },
        );
      },
    );
  }

  Widget _buildFosterContractsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FosterContract>('foster_contracts').listenable(),
      builder: (context, Box<FosterContract> box, _) {
        final contracts = box.values.toList()
          ..sort((a, b) => b.contractDate.compareTo(a.contractDate));

        if (contracts.isEmpty) {
          return _buildEmptyState(
            'Ingen fôrvertsavtaler',
            Icons.home_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            final dogBox = Hive.box<Dog>('dogs');
            final dog = dogBox.values.where((d) => d.id == contract.dogId).firstOrNull;

            return _buildContractCard(
              title: dog?.name ?? 'Ukjent hund',
              subtitle: contract.fosterName,
              date: contract.contractDate,
              status: contract.status ?? 'Draft',
              icon: Icons.home_rounded,
              color: _getStatusColor(contract.status ?? 'Draft'),
              onEdit: () => _editFosterContract(contract, dog),
              onDelete: () => _deleteFosterContract(contract),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: context.colors.textDisabled,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard({
    required String title,
    required String subtitle,
    required DateTime date,
    required String status,
    required IconData icon,
    required Color color,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.colors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: ThemeOpacity.low(context)),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('dd.MM.yyyy').format(date),
                      style: AppTypography.caption.copyWith(
                        color: context.colors.textCaption,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: ThemeOpacity.low(context)),
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Rediger'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.textTertiary,
                    ),
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Slett'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============ EDIT METHODS ============

  void _editPurchaseContract(PurchaseContract contract, Puppy puppy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseContractScreen(
          puppy: puppy,
          existingContract: contract,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _editReservationContract(ReservationContract contract, Puppy puppy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationContractScreen(
          preselectedPuppy: puppy,
          existingContract: contract,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _editBreedingContract(BreedingContract contract, Dog? stud, Dog? dam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreedingContractScreen(
          existingContract: contract,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _editCoOwnershipContract(CoOwnershipContract contract, Dog? dog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoOwnershipContractScreen(
          existingContract: contract,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _editFosterContract(FosterContract contract, Dog? dog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FosterContractScreen(
          existingContract: contract,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  // ============ DELETE METHODS ============

  void _deletePurchaseContract(PurchaseContract contract) {
    _showDeleteConfirmation(
      title: 'Slett kjøpskontrakt',
      message: 'Er du sikker på at du vil slette denne kjøpskontrakten?',
      onConfirm: () async {
        final userId = AuthService().currentUser?.uid;
        if (userId != null) {
          await CloudSyncService().deletePurchaseContract(
            userId: userId,
            contractId: contract.id,
          );
        }
        await contract.delete();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kjøpskontrakt slettet')),
          );
        }
      },
    );
  }

  void _deleteReservationContract(ReservationContract contract) {
    _showDeleteConfirmation(
      title: 'Slett reservasjonsavtale',
      message: 'Er du sikker på at du vil slette denne reservasjonsavtalen?',
      onConfirm: () async {
        await contract.delete();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservasjonsavtale slettet')),
          );
        }
      },
    );
  }

  void _deleteBreedingContract(BreedingContract contract) {
    _showDeleteConfirmation(
      title: 'Slett paringsavtale',
      message: 'Er du sikker på at du vil slette denne paringsavtalen?',
      onConfirm: () async {
        await contract.delete();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paringsavtale slettet')),
          );
        }
      },
    );
  }

  void _deleteCoOwnershipContract(CoOwnershipContract contract) {
    _showDeleteConfirmation(
      title: 'Slett sameieavtale',
      message: 'Er du sikker på at du vil slette denne sameieavtalen?',
      onConfirm: () async {
        await contract.delete();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sameieavtale slettet')),
          );
        }
      },
    );
  }

  void _deleteFosterContract(FosterContract contract) {
    _showDeleteConfirmation(
      title: 'Slett fôrvertsavtale',
      message: 'Er du sikker på at du vil slette denne fôrvertsavtalen?',
      onConfirm: () async {
        await contract.delete();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fôrvertsavtale slettet')),
          );
        }
      },
    );
  }

  void _showDeleteConfirmation({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Slett', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktiv':
        return AppColors.success;
      case 'pending':
      case 'venter':
      case 'draft':
        return AppColors.warning;
      case 'completed':
      case 'fullført':
      case 'converted':
        return AppColors.info;
      case 'cancelled':
      case 'kansellert':
        return AppColors.error;
      default:
        return context.colors.textCaption;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktiv':
        return 'Aktiv';
      case 'draft':
        return 'Kladd';
      case 'pending':
      case 'venter':
        return 'Venter';
      case 'completed':
      case 'fullført':
        return 'Fullført';
      case 'converted':
        return 'Konvertert';
      case 'cancelled':
      case 'kansellert':
        return 'Kansellert';
      default:
        return status;
    }
  }
}
