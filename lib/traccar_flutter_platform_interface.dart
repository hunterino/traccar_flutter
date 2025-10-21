import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'entity/traccar_configs.dart';
import 'traccar_flutter_method_channel.dart';

abstract class TraccarFlutterPlatform extends PlatformInterface {
  /// Constructs a TraccarFlutterPlatform.
  TraccarFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static TraccarFlutterPlatform _instance = MethodChannelTraccarFlutter();

  /// The default instance of [TraccarFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelTraccarFlutter].
  static TraccarFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TraccarFlutterPlatform] when
  /// they register themselves.
  static set instance(TraccarFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> initTraccar() {
    throw UnimplementedError('initTraccar() has not been implemented.');
  }

  Future<String?> setConfigs(TraccarConfigs configs) {
    throw UnimplementedError('setConfigs() has not been implemented.');
  }

  Future<String?> startService() {
    throw UnimplementedError('startService() has not been implemented.');
  }

  Future<String?> stopService() {
    throw UnimplementedError('stopService() has not been implemented.');
  }

  Future<String?> showStatusLogs() {
    throw UnimplementedError('showStatusLogs() has not been implemented.');
  }

  Future<String?> getServiceStatus() {
    throw UnimplementedError('getServiceStatus() has not been implemented.');
  }

  /// Sets a handler for method calls from native platforms
  void setMethodCallHandler(Future<void> Function(String method, dynamic arguments)? handler) {
    throw UnimplementedError('setMethodCallHandler() has not been implemented.');
  }
}
