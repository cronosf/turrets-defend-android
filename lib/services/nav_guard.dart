/// Debounces rapid repeat taps on navigation buttons. Without this, tapping
/// a footer/menu item twice in quick succession (easy to do while waiting
/// on a screen that's still loading its data) pushes the same screen twice,
/// stacking up duplicate routes that each do their own network fetch.
class NavGuard {
  NavGuard._();

  static DateTime? _lastNavigation;

  /// Call right before a `Navigator.push`. Returns false (and does nothing)
  /// if another navigation just happened within the debounce window.
  static bool allow({Duration within = const Duration(milliseconds: 700)}) {
    final now = DateTime.now();
    if (_lastNavigation != null && now.difference(_lastNavigation!) < within) {
      return false;
    }
    _lastNavigation = now;
    return true;
  }
}
