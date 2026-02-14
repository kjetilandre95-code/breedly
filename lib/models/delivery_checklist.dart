import 'package:hive/hive.dart';

part 'delivery_checklist.g.dart';

/// Represents a checklist item for puppy delivery
@HiveType(typeId: 30)
class DeliveryChecklistItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String category; // 'health', 'documents', 'equipment', 'information'

  @HiveField(3)
  late bool isCompleted;

  @HiveField(4)
  DateTime? completedDate;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  late int sortOrder;

  DeliveryChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.completedDate,
    this.notes,
    this.sortOrder = 0,
  });

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
      'notes': notes,
      'sortOrder': sortOrder,
    };
  }

  /// Deserialize from Firebase JSON
  factory DeliveryChecklistItem.fromJson(Map<String, dynamic> json) {
    return DeliveryChecklistItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'health',
      isCompleted: json['isCompleted'] ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'])
          : null,
      notes: json['notes'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

/// Complete delivery checklist for a puppy
@HiveType(typeId: 31)
class DeliveryChecklist extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String puppyId;

  @HiveField(2)
  late List<DeliveryChecklistItem> items;

  @HiveField(3)
  late DateTime createdDate;

  @HiveField(4)
  DateTime? deliveryDate;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  late bool isComplete;

  DeliveryChecklist({
    required this.id,
    required this.puppyId,
    required this.items,
    required this.createdDate,
    this.deliveryDate,
    this.notes,
    this.isComplete = false,
  });

  /// Get completion percentage
  double get completionPercentage {
    if (items.isEmpty) return 0;
    final completed = items.where((item) => item.isCompleted).length;
    return completed / items.length;
  }

  /// Get items by category
  List<DeliveryChecklistItem> getItemsByCategory(String category) {
    return items.where((item) => item.category == category).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Check if all items are completed
  bool get allItemsCompleted {
    return items.every((item) => item.isCompleted);
  }

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puppyId': puppyId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'notes': notes,
      'isComplete': isComplete,
    };
  }

  /// Deserialize from Firebase JSON
  factory DeliveryChecklist.fromJson(Map<String, dynamic> json) {
    return DeliveryChecklist(
      id: json['id'] ?? '',
      puppyId: json['puppyId'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DeliveryChecklistItem.fromJson(item))
              .toList() ??
          [],
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      notes: json['notes'],
      isComplete: json['isComplete'] ?? false,
    );
  }

  /// Create a default checklist with standard items
  static DeliveryChecklist createDefault(String id, String puppyId) {
    return DeliveryChecklist(
      id: id,
      puppyId: puppyId,
      createdDate: DateTime.now(),
      items: _getDefaultItems(),
    );
  }

  /// Get default checklist items
  static List<DeliveryChecklistItem> _getDefaultItems() {
    int order = 0;
    return [
      // Health category
      DeliveryChecklistItem(
        id: 'h1',
        title: 'Vaksinert (første dose)',
        category: 'health',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'h2',
        title: 'Ormekur fullført',
        category: 'health',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'h3',
        title: 'ID-chip registrert',
        category: 'health',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'h4',
        title: 'Veterinærattest utstedt',
        category: 'health',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'h5',
        title: 'Helsesjekk utført',
        category: 'health',
        sortOrder: order++,
      ),

      // Documents category
      DeliveryChecklistItem(
        id: 'd1',
        title: 'Kjøpskontrakt signert',
        category: 'documents',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'd2',
        title: 'Stamtavle/registreringsbevis',
        category: 'documents',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'd3',
        title: 'Vaksinasjonskort',
        category: 'documents',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'd4',
        title: 'Forsikringsinformasjon',
        category: 'documents',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'd5',
        title: 'Fôringsguide',
        category: 'documents',
        sortOrder: order++,
      ),

      // Equipment category
      DeliveryChecklistItem(
        id: 'e1',
        title: 'Startpakke med fôr',
        category: 'equipment',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'e2',
        title: 'Teppe/duk med mors lukt',
        category: 'equipment',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'e3',
        title: 'Leke',
        category: 'equipment',
        sortOrder: order++,
      ),

      // Information category
      DeliveryChecklistItem(
        id: 'i1',
        title: 'Kontaktinfo oppdretter',
        category: 'information',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'i2',
        title: 'Gjennomgang av fôring og stell',
        category: 'information',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'i3',
        title: 'Informasjon om trening/sosialisering',
        category: 'information',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'i4',
        title: 'Neste vaksine- og ormekurdato',
        category: 'information',
        sortOrder: order++,
      ),
      DeliveryChecklistItem(
        id: 'i5',
        title: 'Veterinæranbefaling gitt',
        category: 'information',
        sortOrder: order++,
      ),
    ];
  }
}

/// Category labels and icons for the checklist
class DeliveryChecklistCategory {
  static const String health = 'health';
  static const String documents = 'documents';
  static const String equipment = 'equipment';
  static const String information = 'information';

  static String getLabel(String category, {bool norwegian = true}) {
    if (norwegian) {
      switch (category) {
        case health:
          return 'Helse';
        case documents:
          return 'Dokumenter';
        case equipment:
          return 'Utstyr';
        case information:
          return 'Informasjon';
        default:
          return category;
      }
    }
    switch (category) {
      case health:
        return 'Health';
      case documents:
        return 'Documents';
      case equipment:
        return 'Equipment';
      case information:
        return 'Information';
      default:
        return category;
    }
  }
}
