/// Which reminder screens are open right now (so the in-app due-dose watcher
/// never opens a second screen for a dose that is already ringing).
abstract final class ActiveReminderRegistry {
  static final Set<String> _open = <String>{};

  static String keyOf(String profileKey, String medicationId, int minutesOfDay) =>
      '$profileKey/$medicationId/$minutesOfDay';

  static void add(String key) => _open.add(key);
  static void remove(String key) => _open.remove(key);
  static bool get anyOpen => _open.isNotEmpty;
  static bool isOpen(String key) => _open.contains(key);
}
