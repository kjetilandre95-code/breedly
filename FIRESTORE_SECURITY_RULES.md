// Firestore Security Rules for Multi-User Collaboration
// This allows users to share breeding groups and collaborate on data

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User profiles
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // Shared breeding groups
      match /shared_breeding_groups/{breedingGroupId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    // Breeding groups - main collection for shared data
    match /breeding_groups/{breedingGroupId} {
      // Check if user has access (owner or shared user)
      allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                            isBreedingGroupSharedUser(breedingGroupId);
      
      // Dogs subcollection
      match /dogs/{dogId} {
        allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                              isBreedingGroupSharedUser(breedingGroupId);
      }

      // Litters subcollection
      match /litters/{litterId} {
        allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                              isBreedingGroupSharedUser(breedingGroupId);
        
        // Puppies under litters
        match /puppies/{puppyId} {
          allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                                isBreedingGroupSharedUser(breedingGroupId);
        }
      }

      // Health info subcollection
      match /health_info/{healthId} {
        allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                              isBreedingGroupSharedUser(breedingGroupId);
      }

      // Vaccines subcollection
      match /vaccines/{vaccineId} {
        allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                              isBreedingGroupSharedUser(breedingGroupId);
      }

      // Expenses subcollection
      match /expenses/{expenseId} {
        allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                              isBreedingGroupSharedUser(breedingGroupId);
      }

      // Income subcollection
      match /income/{incomeId} {
        allow read, write: if isBreedingGroupOwner(breedingGroupId) || 
                              isBreedingGroupSharedUser(breedingGroupId);
      }

      // Shared users list
      match /shared_users/{sharedUserId} {
        allow read: if isBreedingGroupOwner(breedingGroupId);
        allow write: if isBreedingGroupOwner(breedingGroupId);
      }
    }

    // Legacy user-scoped collections (for backward compatibility)
    match /users/{userId}/dogs/{dogId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /users/{userId}/litters/{litterId} {
      allow read, write: if request.auth.uid == userId;
      
      match /puppies/{puppyId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    match /users/{userId}/puppies/{puppyId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /users/{userId}/health_info/{healthId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /users/{userId}/vaccines/{vaccineId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /users/{userId}/expenses/{expenseId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /users/{userId}/income/{incomeId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}

// Helper functions
function isBreedingGroupOwner(breedingGroupId) {
  return get(/databases/$(database)/documents/breeding_groups/$(breedingGroupId)).data.ownerId == request.auth.uid;
}

function isBreedingGroupSharedUser(breedingGroupId) {
  return exists(/databases/$(database)/documents/breeding_groups/$(breedingGroupId)/shared_users/$(request.auth.uid));
}
