/// Represents the current state of the Traccar tracking service.
enum ServiceStatus {
  /// Service is completely stopped and not tracking
  stopped,

  /// Service is in the process of starting up
  starting,

  /// Service is running and actively tracking location
  running,

  /// Service is in the process of shutting down
  stopping,

  /// Service encountered an error
  error;

  /// Creates a ServiceStatus from a string name
  static ServiceStatus fromString(String name) {
    return ServiceStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => ServiceStatus.error,
    );
  }

  /// Returns a user-friendly display name for this status
  String get displayName {
    switch (this) {
      case ServiceStatus.stopped:
        return 'Stopped';
      case ServiceStatus.starting:
        return 'Starting...';
      case ServiceStatus.running:
        return 'Running';
      case ServiceStatus.stopping:
        return 'Stopping...';
      case ServiceStatus.error:
        return 'Error';
    }
  }

  /// Returns true if the service is in a transitional state
  bool get isTransitioning {
    return this == ServiceStatus.starting || this == ServiceStatus.stopping;
  }

  /// Returns true if the service is actively tracking
  bool get isActive {
    return this == ServiceStatus.running;
  }
}
