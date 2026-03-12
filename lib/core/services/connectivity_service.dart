import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionQuality { none, poor, moderate, good }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  String connectionTypeLabel(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (results.contains(ConnectivityResult.mobile)) return 'Données mobiles';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Aucune';
  }

  /// Ping réel pour mesurer la qualité de la connexion.
  Future<ConnectionQuality> checkQuality() async {
    final results = await _connectivity.checkConnectivity();
    if (!_isConnected(results)) return ConnectionQuality.none;

    try {
      final sw = Stopwatch()..start();
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      sw.stop();
      if (lookup.isEmpty || lookup[0].rawAddress.isEmpty) {
        return ConnectionQuality.none;
      }
      final ms = sw.elapsedMilliseconds;
      if (ms < 200) return ConnectionQuality.good;
      if (ms < 800) return ConnectionQuality.moderate;
      return ConnectionQuality.poor;
    } catch (_) {
      return ConnectionQuality.none;
    }
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream.map((results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  });
});

/// Type de connexion actuel (label lisible).
final connectionTypeProvider = StreamProvider<String>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream.map((results) => service.connectionTypeLabel(results));
});
