import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/buyer.dart';

/// Result type for global search
enum SearchResultType { dog, litter, puppy, buyer }

/// A search result item
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final IconData icon;
  final dynamic data;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    this.data,
  });
}

/// Service for global search across all data types
class GlobalSearchService {
  static final GlobalSearchService _instance = GlobalSearchService._internal();
  factory GlobalSearchService() => _instance;
  GlobalSearchService._internal();

  /// Search across all data types
  Future<List<SearchResult>> search(String query, {String? userId}) async {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();
    final results = <SearchResult>[];

    // Search dogs - userId parameter kept for future multi-user support but not used currently
    results.addAll(await _searchDogs(normalizedQuery));

    // Search litters
    results.addAll(await _searchLitters(normalizedQuery));

    // Search puppies
    results.addAll(await _searchPuppies(normalizedQuery));

    // Search buyers
    results.addAll(await _searchBuyers(normalizedQuery));

    // Sort by relevance (exact matches first, then starts with, then contains)
    results.sort((a, b) {
      final aLower = a.title.toLowerCase();
      final bLower = b.title.toLowerCase();
      
      // Exact match
      final aExact = aLower == normalizedQuery;
      final bExact = bLower == normalizedQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      // Starts with query
      final aStartsWith = aLower.startsWith(normalizedQuery);
      final bStartsWith = bLower.startsWith(normalizedQuery);
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      
      return a.title.compareTo(b.title);
    });

    return results;
  }

  Future<List<SearchResult>> _searchDogs(String query) async {
    final results = <SearchResult>[];
    
    try {
      final box = Hive.box<Dog>('dogs');
      // Search all dogs in the local database
      for (final dog in box.values) {
        if (_matchesDog(dog, query)) {
          results.add(SearchResult(
            id: dog.id,
            title: dog.name,
            subtitle: '${dog.breed} • ${dog.gender == 'Female' ? 'Tispe' : 'Hannhund'}',
            type: SearchResultType.dog,
            icon: Icons.pets,
            data: dog,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error searching dogs: $e');
    }

    return results;
  }

  bool _matchesDog(Dog dog, String query) {
    return dog.name.toLowerCase().contains(query) ||
        dog.breed.toLowerCase().contains(query) ||
        (dog.registrationNumber?.toLowerCase().contains(query) ?? false) ||
        dog.color.toLowerCase().contains(query) ||
        (dog.notes?.toLowerCase().contains(query) ?? false);
  }

  Future<List<SearchResult>> _searchLitters(String query) async {
    final results = <SearchResult>[];

    try {
      final box = Hive.box<Litter>('litters');
      final dogBox = Hive.box<Dog>('dogs');
      // Search all litters in the local database
      for (final litter in box.values) {
        final mother = dogBox.values.where((d) => d.id == litter.damId).firstOrNull;
        final father = dogBox.values.where((d) => d.id == litter.sireId).firstOrNull;
        
        final motherName = mother?.name ?? 'Ukjent';
        final fatherName = father?.name ?? 'Ukjent';
        final litterName = '$motherName x $fatherName';

        if (litterName.toLowerCase().contains(query) ||
            (litter.notes?.toLowerCase().contains(query) ?? false)) {
          final puppyCount = Hive.box<Puppy>('puppies')
              .values
              .where((p) => p.litterId == litter.id)
              .length;

          results.add(SearchResult(
            id: litter.id,
            title: litterName,
            subtitle: 'Født • $puppyCount valper',
            type: SearchResultType.litter,
            icon: Icons.favorite_rounded,
            data: litter,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error searching litters: $e');
    }

    return results;
  }

  Future<List<SearchResult>> _searchPuppies(String query) async {
    final results = <SearchResult>[];

    try {
      final box = Hive.box<Puppy>('puppies');
      // Search all puppies in the local database
      for (final puppy in box.values) {
        if (_matchesPuppy(puppy, query)) {
          results.add(SearchResult(
            id: puppy.id,
            title: puppy.name,
            subtitle: '${puppy.color} • ${puppy.status ?? 'Tilgjengelig'}',
            type: SearchResultType.puppy,
            icon: Icons.pets_outlined,
            data: puppy,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error searching puppies: $e');
    }

    return results;
  }

  bool _matchesPuppy(Puppy puppy, String query) {
    return puppy.name.toLowerCase().contains(query) ||
        puppy.color.toLowerCase().contains(query) ||
        (puppy.notes?.toLowerCase().contains(query) ?? false);
  }

  Future<List<SearchResult>> _searchBuyers(String query) async {
    final results = <SearchResult>[];

    try {
      final box = Hive.box<Buyer>('buyers');
      // Search all buyers in the local database
      for (final buyer in box.values) {
        if (_matchesBuyer(buyer, query)) {
          results.add(SearchResult(
            id: buyer.id,
            title: buyer.name,
            subtitle: buyer.email ?? buyer.phone ?? 'Ingen kontaktinfo',
            type: SearchResultType.buyer,
            icon: Icons.person,
            data: buyer,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error searching buyers: $e');
    }

    return results;
  }

  bool _matchesBuyer(Buyer buyer, String query) {
    return buyer.name.toLowerCase().contains(query) ||
        (buyer.email?.toLowerCase().contains(query) ?? false) ||
        (buyer.phone?.toLowerCase().contains(query) ?? false) ||
        (buyer.address?.toLowerCase().contains(query) ?? false) ||
        (buyer.notes?.toLowerCase().contains(query) ?? false);
  }
}
