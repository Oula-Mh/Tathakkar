abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Tabs
  static const home = '/home';
  static const medications = '/medications';
  static const history = '/history';
  static const account = '/account';

  // Medications
  static const medicationNew = '/medications/new';
  static String medicationDetails(String id) => '/medications/$id';
  static String medicationEdit(String id) => '/medications/$id/edit';
  static String medicationStock(String id) => '/medications/$id/stock';

  // Family & care
  static const family = '/family';
  static const familyAdd = '/family/add';
  static const familyAddLocal = '/family/add/local';
  static const care = '/care';
  static const careQr = '/care/qr';
  static const careScan = '/care/scan';
  static const careResult = '/care/result';
  static const careLinkedElder = '/care/linked';
  static const careUnlinked = '/care/unlinked';

  // Misc
  static const inbox = '/inbox';
  static const reminderSettings = '/account/reminders';
  static const reminderHealth = '/account/reminders/health';
  static const notificationPermission = '/permissions/notifications';
  static const reminder = '/reminder';
  /// [alarm] = opened by an alarm notification: the screen is the ONLY thing shown
  /// (no splash, no home), and closing it leaves the app.
  static String reminderLocation(String payload, {String? action, bool alarm = false}) =>
      '$reminder?p=${Uri.encodeQueryComponent(payload)}'
      '${action == null ? '' : '&a=$action'}${alarm ? '&alarm=1' : ''}';

  static const authRoutes = {login, register, forgotPassword};
}
