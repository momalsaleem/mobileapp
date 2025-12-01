import 'package:flutter/material.dart';
// No direct dependency here; consumers will call VoiceManager/_tts directly.

/// A single RouteObserver instance to be registered with the app's
/// Navigator (via MaterialApp.navigatorObservers). Pages that speak
/// can subscribe to this observer and implement [stopTtsAndListening]
/// to automatically stop audio when another route is pushed above them.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// Mixin for State classes that want to stop TTS/STT when another
/// route is pushed on top of them.
mixin RouteAwareTtsStopper<T extends StatefulWidget> on State<T>
    implements RouteAware {
  /// Implementing State classes must provide this method which will be
  /// invoked (without awaiting) when another route is pushed on top.
  Future<void> stopTtsAndListening();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPopNext() {}

  @override
  void didPushNext() {
    // Fire-and-forget stop so navigation isn't blocked by audio teardown.
    stopTtsAndListening();
  }
}
