import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bump after concierge actions so Activity / Orders tabs reload.
final activityRefreshProvider = StateProvider<int>((ref) => 0);

void bumpActivity(WidgetRef ref) {
  ref.read(activityRefreshProvider.notifier).state++;
}

/// Bump to refresh home announcement / up-next cards.
final homeRefreshProvider = StateProvider<int>((ref) => 0);

void bumpHome(WidgetRef ref) {
  ref.read(homeRefreshProvider.notifier).state++;
}
