import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_storage.dart';

class SubscriptionNotifier extends StateNotifier<List<String>> {
  SubscriptionNotifier() : super(LocalStorage.getSubscriptions());

  bool isSubscribed(String sourceId) => state.contains(sourceId);

  Future<void> toggle(String sourceId) async {
    if (state.contains(sourceId)) {
      state = state.where((id) => id != sourceId).toList();
    } else {
      state = [...state, sourceId];
    }
    await LocalStorage.saveSubscriptions(state);
  }

  Future<void> subscribe(String sourceId) async {
    if (!state.contains(sourceId)) {
      state = [...state, sourceId];
      await LocalStorage.saveSubscriptions(state);
    }
  }

  Future<void> unsubscribe(String sourceId) async {
    state = state.where((id) => id != sourceId).toList();
    await LocalStorage.saveSubscriptions(state);
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, List<String>>(
  (ref) => SubscriptionNotifier(),
);
