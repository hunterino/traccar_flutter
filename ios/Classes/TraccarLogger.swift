/*
 * Copyright 2025 Traccar Flutter Plugin Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Foundation
import os.log

/// Centralized logging for Traccar Flutter plugin using OSLog
///
/// Provides categorized logs for different subsystems:
/// - positioning: Location updates and GPS-related events
/// - network: HTTP requests and network connectivity
/// - database: Core Data operations and persistence
/// - service: Tracking service lifecycle events
/// - plugin: Flutter plugin bridge events
///
/// Example usage:
/// ```swift
/// os_log("Location updated: %{public}@", log: TraccarLogger.positioning, type: .debug, location.description)
/// os_log("Network error: %{public}@", log: TraccarLogger.network, type: .error, error.localizedDescription)
/// ```
@available(iOS 10.0, *)
class TraccarLogger {
    static let subsystem = "dev.mostafamovahhed.traccar_flutter"

    /// Log category for position/location-related events
    static let positioning = OSLog(subsystem: subsystem, category: "positioning")

    /// Log category for network requests and connectivity
    static let network = OSLog(subsystem: subsystem, category: "network")

    /// Log category for database operations
    static let database = OSLog(subsystem: subsystem, category: "database")

    /// Log category for tracking service lifecycle
    static let service = OSLog(subsystem: subsystem, category: "service")

    /// Log category for Flutter plugin bridge
    static let plugin = OSLog(subsystem: subsystem, category: "plugin")

    /// Fallback logger for iOS < 10.0
    @available(iOS, deprecated: 10.0, message: "Use OSLog categories instead")
    static func log(_ message: String, category: String = "general") {
        print("[\(category)] \(message)")
    }
}
