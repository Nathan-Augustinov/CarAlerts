/// Local entry is explicit during a session. load() restores it only if a car
/// exists and the user has not explicitly signed out.
enum SessionRoute { signIn, local, account, transfer }

SessionRoute sessionRoute(
    {required String? user,
    required bool localActive,
    required bool hasLocalCar}) {
  if (user != null) {
    return hasLocalCar ? SessionRoute.transfer : SessionRoute.account;
  }
  return localActive ? SessionRoute.local : SessionRoute.signIn;
}
