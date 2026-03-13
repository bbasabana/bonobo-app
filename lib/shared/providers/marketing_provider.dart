import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_storage.dart';

enum MarketingPromoType { journalist, media }

class MarketingState {
  final bool showPromo;
  final MarketingPromoType? activePromo;
  final int articleViews;
  final Duration sessionDuration;

  MarketingState({
    this.showPromo = false,
    this.activePromo,
    this.articleViews = 0,
    this.sessionDuration = Duration.zero,
  });

  MarketingState copyWith({
    bool? showPromo,
    MarketingPromoType? activePromo,
    int? articleViews,
    Duration? sessionDuration,
  }) {
    return MarketingState(
      showPromo: showPromo ?? this.showPromo,
      activePromo: activePromo ?? this.activePromo,
      articleViews: articleViews ?? this.articleViews,
      sessionDuration: sessionDuration ?? this.sessionDuration,
    );
  }
}

class MarketingNotifier extends StateNotifier<MarketingState> {
  Timer? _timer;
  static const int _viewThreshold = 5;
  static const Duration _timeThreshold = Duration(minutes: 10);

  MarketingNotifier() : super(MarketingState()) {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      state = state.copyWith(sessionDuration: state.sessionDuration + const Duration(seconds: 30));
      _checkTriggers();
    });
  }

  void incrementArticleViews() {
    state = state.copyWith(articleViews: state.articleViews + 1);
    _checkTriggers();
  }

  void _checkTriggers() {
    if (state.showPromo) return;

    final reachedTime = state.sessionDuration >= _timeThreshold;
    final reachedViews = state.articleViews >= _viewThreshold;

    if (reachedTime || reachedViews) {
      _tryShowPromo();
    }
  }

  void _tryShowPromo() {
    // Choisir un type aléatoirement
    final type = Random().nextBool() ? MarketingPromoType.journalist : MarketingPromoType.media;
    final promoId = type == MarketingPromoType.journalist ? 'journalist_promo' : 'media_promo';
    
    final status = LocalStorage.getMarketingStatus(promoId);
    
    // Ne pas afficher si déjà "dismissed" (fermé définitivement)
    if (status == 'dismissed') return;
    
    // Si "remind_me", vérifier le délai (ex: 24h)
    if (status == 'remind_me') {
      final lastTs = LocalStorage.getLastMarketingTimestamp(promoId);
      if (lastTs != null && DateTime.now().difference(lastTs) < const Duration(hours: 24)) {
        return;
      }
    }

    state = state.copyWith(showPromo: true, activePromo: type);
  }

  void dismissPromo(bool permanent) {
    if (state.activePromo == null) return;
    final promoId = state.activePromo == MarketingPromoType.journalist ? 'journalist_promo' : 'media_promo';
    
    LocalStorage.saveMarketingStatus(promoId, permanent ? 'dismissed' : 'remind_me');
    state = state.copyWith(showPromo: false, activePromo: null);
  }

  void resetSession() {
    state = state.copyWith(articleViews: 0, sessionDuration: Duration.zero);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final marketingProvider = StateNotifierProvider<MarketingNotifier, MarketingState>((ref) {
  return MarketingNotifier();
});
