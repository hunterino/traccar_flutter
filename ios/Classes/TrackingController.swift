//
// Copyright 2013 - 2017 Anton Tananaev (anton@traccar.org)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import CoreLocation

class TrackingController: NSObject, PositionProviderDelegate, NetworkManagerDelegate, CLLocationManagerDelegate {
    
    static let RETRY_DELAY: UInt64 = 30 * 1000;
    
    var online = false
    var waiting = false
    var stopped = false
    
    let positionProvider = PositionProvider()
    let locationManager = CLLocationManager()
    let databaseHelper = DatabaseHelper()
    let networkManager = NetworkManager()
    let userDefaults = UserDefaults.standard
    
    let url: String
    let buffer: Bool
    
    override init() {
        online = networkManager.online()
        url = userDefaults.string(forKey: PreferenceKeys.serverUrl.rawValue)!
        buffer = userDefaults.bool(forKey: PreferenceKeys.offlineBuffering.rawValue)
        
        super.init()
        
        positionProvider.delegate = self
        locationManager.delegate = self
        networkManager.delegate = self
    }
    
//    func scheduleNotification() {
//        
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            guard granted else { print("Notification authorization denied"); return }
//            
//            let content = UNMutableNotificationContent()
//            content.title = "Service Running ..."
//            //        content.body = "Don't forget to check your tasks!"
//            content.sound = UNNotificationSound.default
//            
//            let stopAction = UNNotificationAction(identifier: "STOP_SERVICE", title: "Stop", options: [.foreground])
//            
//            let category = UNNotificationCategory(identifier: "SERVICE_CATEGORY",
//                                                          actions: [stopAction],
//                                                          intentIdentifiers: [],
//                                                          options: [])
//                    
//            UNUserNotificationCenter.current().setNotificationCategories([category])
//
//            content.categoryIdentifier = "SERVICE_CATEGORY"
//            
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
//            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//            UNUserNotificationCenter.current().add(request) { error in
//                if let error = error {
//                    print("Error scheduling notification: \(error.localizedDescription)")
//                } else {
//                    print("Notification scheduled successfully")
//                }
//            }
//        }
//    }
//    
//    func removeNotifications(){
//        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["traccarNotification"])
//        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["traccarNotification"])
//    }
    
    func start() {
        self.stopped = false
        if self.online {
            read()
        }
        positionProvider.startUpdates()
        locationManager.startMonitoringSignificantLocationChanges()
//        scheduleNotification()
        networkManager.start()
    }
    
    func stop() {
        networkManager.stop()
        locationManager.stopMonitoringSignificantLocationChanges()
        positionProvider.stopUpdates()
//        removeNotifications()
        self.stopped = true
    }
    
    func didUpdate(position: Position) {
        TraccarController.addStatusLog(message: "Location update")
        if buffer {
            write(position)
        } else {
            send(position)
        }
    }
    
    func didUpdateNetwork(online: Bool) {
        TraccarController.addStatusLog(message: "Connectivity change")
        if !self.online && online {
            read()
        }
        self.online = online
    }
    
    //
    // State transition examples:
    //
    // write -> read -> send -> delete -> read
    //
    // read -> send -> retry -> read -> send
    //
    
    func write(_ position: Position) {
        let context = DatabaseHelper().managedObjectContext
        if context.hasChanges {
            try? context.save()
        }
        if self.online && self.waiting {
            read()
            self.waiting = false
        }
    }
    
    func read() {
        if let position = databaseHelper.selectPosition() {
            if (position.deviceId == userDefaults.string(forKey: PreferenceKeys.deviceId.rawValue)) {
                send(position)
            } else {
                delete(position)
            }
        } else {
            self.waiting = true
        }
    }
    
    func delete(_ position: Position) {
        databaseHelper.delete(position: position)
        read()
    }
    
    func send(_ position: Position) {
        if let request = ProtocolFormatter.formatPostion(position, url: url) {
            RequestManager.sendRequest(request, completionHandler: {(_ success: Bool) -> Void in
                if success {
                    TraccarController.addStatusLog(message: "Send successfully")
                    if self.buffer {
                        self.delete(position)
                    }
                } else {
                    TraccarController.addStatusLog(message: "Send failed")
                    if self.buffer {
                        self.retry()
                    }
                }
            })
        } else {
            TraccarController.addStatusLog(message: "Send failed")
            if buffer {
                self.retry()
            }
        }
    }
    
    func retry() {
        let deadline = DispatchTime.now() + Double(TrackingController.RETRY_DELAY * NSEC_PER_MSEC) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: deadline, execute: {() -> Void in
            if !self.stopped && self.online {
                self.read()
            }
        })
    }
    
}
