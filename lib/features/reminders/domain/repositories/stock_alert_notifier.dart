import '../../../medications/domain/entities/medication.dart';
import '../../../profiles/domain/entities/person_profile.dart';

/// Raises a LOCAL notification when a medication's stock crosses its alert level.
abstract interface class StockAlertNotifier {
  Future<void> evaluate(PersonProfile profile, List<Medication> medications,
      {required String languageCode});
}
