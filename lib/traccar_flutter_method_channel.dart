import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'entity/traccar_configs.dart';
import 'traccar_flutter_platform_interface.dart';

/// An implementation of [TraccarFlutterPlatform] that uses method channels.
class MethodChannelTraccarFlutter extends TraccarFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('traccar_flutter');


  @override
  Future<String?> initTraccar() {
    return methodChannel.invokeMethod<String>('init');
  }

  @override
  Future<String?> setConfigs(TraccarConfigs configs) {
    return methodChannel.invokeMethod<String>('setConfigs', configs.toMap());
  }

  @override
  Future<String?> startService() {
    return methodChannel.invokeMethod<String>('startService');
  }

  @override
  Future<String?> stopService() {
    return methodChannel.invokeMethod<String>('stopService');
  }

  @override
  Future<String?> showStatusLogs() {
    return methodChannel.invokeMethod<String>('statusActivity');
  }
}
