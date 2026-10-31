/// Removes everything a signed-in user left on this device.
abstract interface class SessionCleaner {
  /// Called when a user signs in: wipes leftovers if a DIFFERENT user used the device.
  Future<void> prepareFor(String uid);

  /// Called before sign-out: stops alarms, unregisters push, wipes local health data.
  Future<void> clearForSignOut(String? uid);
}
