/// Felles oversettelser for hele appen
class AppTranslations {
  /// Oversett puppy status fra engelsk til norsk
  static String translatePuppyStatus(String status) {
    switch (status) {
      case 'Available':
        return 'Ledig';
      case 'Sold':
        return 'Solgt';
      case 'Reserved':
        return 'Reservert';
      default:
        return status;
    }
  }

  /// Oversett kjønn fra engelsk til norsk
  static String translateGender(String gender) {
    switch (gender) {
      case 'Male':
        return 'Hann';
      case 'Female':
        return 'Tispe';
      default:
        return gender;
    }
  }

  /// Oversett utgift kategori
  static String translateExpenseCategory(String category) {
    switch (category) {
      case 'Fôr':
        return 'Fôr';
      case 'Veterinær':
        return 'Veterinær';
      case 'Registrering':
        return 'Registrering (NKK)';
      case 'Annet':
        return 'Annet';
      default:
        return category;
    }
  }
}
