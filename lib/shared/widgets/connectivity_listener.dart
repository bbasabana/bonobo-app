import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/connectivity_service.dart';
import 'bonobo_soft_toast.dart';

/// Écoute la connectivité : toasts quand connexion perdue ou retrouvée.
/// À la reconnexion, invalide les données pour actualisation automatique.
class ConnectivityListener extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityListener({super.key, required this.child});

  @override
  ConsumerState<ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends ConsumerState<ConnectivityListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      final prevOnline = previous?.valueOrNull ?? true;
      final nowOnline = next.valueOrNull ?? false;
      if (!mounted) return;
      if (prevOnline && !nowOnline) {
        BonoboSoftToast.showOffline(context);
      } else if (!prevOnline && nowOnline) {
        BonoboSoftToast.showBackOnline(context);
      }
    });
    return widget.child;
  }
}
