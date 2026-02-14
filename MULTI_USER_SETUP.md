# Multi-User Collaboration Setup for Breedly

## Overview
Breedly now supports multi-user collaboration, allowing multiple people (e.g., breeders and assistants) to access and manage the same breeding group together.

## Architecture

### Data Structure
```
breeding_groups/
├── {breedingGroupId}/
│   ├── name: String
│   ├── ownerId: String
│   ├── createdAt: Timestamp
│   ├── dogs/
│   │   └── {dogId}/ (shared among all members)
│   ├── litters/
│   │   ├── {litterId}/
│   │   │   └── puppies/
│   │   │       └── {puppyId}/
│   ├── health_info/
│   │   └── {healthId}/
│   ├── vaccines/
│   │   └── {vaccineId}/
│   ├── expenses/
│   │   └── {expenseId}/
│   ├── income/
│   │   └── {incomeId}/
│   └── shared_users/
│       └── {userId}/
│           ├── role: 'owner' | 'collaborator'
│           ├── permissions: ['read', 'write']
│           └── sharedAt: Timestamp

users/{userId}/
├── email: String
├── name: String
└── shared_breeding_groups/
    └── {breedingGroupId}/
        ├── ownerId: String
        ├── role: String
        └── sharedAt: Timestamp
```

## Implementation Steps

### 1. Setup Firestore Security Rules
Copy the security rules from `FIRESTORE_SECURITY_RULES.md` and apply them in Firebase Console:

1. Go to Firebase Console → Firestore Database → Rules
2. Replace existing rules with the multi-user rules
3. Click "Publish"

### 2. Create Breeding Group
```dart
// When user creates a breeding group for the first time
final breedingGroupId = 'breeding_group_${DateTime.now().millisecondsSinceEpoch}';
await _firestore.collection('breeding_groups').doc(breedingGroupId).set({
  'id': breedingGroupId,
  'ownerId': userId,
  'name': 'My Breeding Group',
  'createdAt': FieldValue.serverTimestamp(),
});

// Add current user as owner
await _firestore
    .collection('breeding_groups')
    .doc(breedingGroupId)
    .collection('shared_users')
    .doc(userId)
    .set({
      'userId': userId,
      'email': userEmail,
      'role': 'owner',
      'permissions': ['read', 'write'],
      'sharedAt': FieldValue.serverTimestamp(),
    });
```

### 3. Share with Another User
```dart
final userSharingService = UserSharingService();
await userSharingService.shareBreedingGroupWithUser(
  breedingGroupId,
  'partner@example.com',
  role: 'collaborator',
);
```

### 4. Migrate Existing Data
For users with existing single-user data, run a migration:

```dart
Future<void> migrateUserDataToBreedingGroup(String userId) async {
  // Create a breeding group for this user
  final breedingGroupId = 'breeding_group_${userId}_migration';
  
  await _firestore.collection('breeding_groups').doc(breedingGroupId).set({
    'id': breedingGroupId,
    'ownerId': userId,
    'name': 'My Breeding Group',
    'createdAt': FieldValue.serverTimestamp(),
  });
  
  // Move all user's data to the breeding group
  // - Copy dogs from users/{userId}/dogs to breeding_groups/{breedingGroupId}/dogs
  // - Copy litters from users/{userId}/litters to breeding_groups/{breedingGroupId}/litters
  // - etc.
  
  // Add user as owner of the breeding group
  await _firestore
      .collection('breeding_groups')
      .doc(breedingGroupId)
      .collection('shared_users')
      .doc(userId)
      .set({
        'userId': userId,
        'email': userEmail,
        'role': 'owner',
        'permissions': ['read', 'write'],
        'sharedAt': FieldValue.serverTimestamp(),
      });
}
```

## Usage Example

### For Owner (Primary Breeder)
```dart
// Owner invites assistant
final userSharingService = UserSharingService();
await userSharingService.shareBreedingGroupWithUser(
  'my-breeding-group-id',
  'assistant@example.com',
  role: 'collaborator',
);
```

### For Collaborator (Assistant)
```dart
// Assistant sees shared breeding groups
final sharedGroups = await userSharingService.getSharedBreedingGroups(userId);

// Assistant can access and modify data in shared breeding group
// (subject to permissions and Firestore security rules)
```

## Roles and Permissions

### Owner
- Full access: read, write, delete
- Can manage sharing (add/remove collaborators, change roles)
- Can delete breeding group
- Can transfer ownership

### Collaborator
- Read and write access to data
- Cannot manage sharing
- Cannot delete breeding group

## Security Considerations

1. **Data Isolation**: Each breeding group is completely isolated from others
2. **User Verification**: Email-based user discovery prevents accidental sharing
3. **Audit Trail**: `sharedAt` and `sharedBy` fields track all sharing history
4. **Role-Based Access**: Security rules enforce role-based permissions
5. **Backward Compatibility**: Legacy user-scoped data remains accessible

## Real-Time Sync

When collaborators are using the app simultaneously:

1. User A adds a new dog to the breeding group
2. User B's app sees the new dog in real-time (if listening to stream)
3. Both have local Hive copies that sync with Firebase

## Offline Usage

- Collaborators can work offline
- Changes sync to Firebase when connection returns
- Conflict resolution: Last write wins (timestamps)

## Future Enhancements

1. **Granular Permissions**: 
   - Can read but not write
   - Can manage only dogs, not finances
   - Can manage only health data

2. **Activity Log**: Track who made what changes and when

3. **Comments/Annotations**: Collaborators can leave notes on dogs/litters

4. **Approval Workflow**: Changes require approval before saving to shared data

5. **Teams**: Group multiple breeding groups under a team

## Troubleshooting

### "User not found" when sharing
- Confirm the email address is correct
- User must have an existing Breedly account with that email
- Email must be verified in their user profile

### Collaborator can't see shared data
- Verify security rules are published
- Check that user is added to `shared_users` collection
- Refresh app or force data sync

### Permission denied errors
- Check that user has `read` or `write` in permissions array
- Verify user ID matches the logged-in user
- Check Firestore security rules for syntax errors
