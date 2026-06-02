import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs BLoC lifecycle, events, and state changes in debug builds only.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _log('CREATE', bloc);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _log('EVENT', bloc, detail: event);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _log(
      'CHANGE',
      bloc,
      detail: '${change.currentState.runtimeType} → '
          '${change.nextState.runtimeType}',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _log(
      'TRANSITION',
      bloc,
      detail: '${transition.event.runtimeType}: '
          '${transition.currentState.runtimeType} → '
          '${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _log('ERROR', bloc, detail: error, stackTrace: stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _log('CLOSE', bloc);
  }

  void _log(
    String kind,
    BlocBase<dynamic> bloc, {
    Object? detail,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }

    final message = detail == null
        ? '[$kind] ${bloc.runtimeType}'
        : '[$kind] ${bloc.runtimeType} | $detail';

    developer.log(
      message,
      name: 'EcoWallet.Bloc',
      error: detail is Exception || detail is Error ? detail : null,
      stackTrace: stackTrace,
    );
  }
}
