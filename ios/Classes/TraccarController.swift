//
// Copyright 2013 - 2021 Anton Tananaev (anton@traccar.org)
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

import UIKit
import CoreData

class TraccarController: PositionProviderDelegate {
    static let shared = TraccarController()
    
    private var window: UIWindow?
    
    var managedObjectContext: NSManagedObjectContext?
    var managedObjectModel: NSManagedObjectModel?
    var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    var trackingController: TrackingController?
    var positionProvider: PositionProvider?
    
    private init(){}
    
    func setup() {
        self.window = UIApplication.shared.windows.first
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        let userDefaults = UserDefaults.standard
        if userDefaults.string(forKey: PreferenceKeys.deviceId.rawValue) == nil {
            let identifier = "\(Int.random(in: 100000..<1000000))"
            userDefaults.setValue(identifier, forKey: PreferenceKeys.deviceId.rawValue)
        }
        
        registerDefaultsFromSettingsBundle()
        
        migrateLegacyDefaults()
        
        managedObjectModel = createManagedObjectModel()
        
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
        let storeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.appendingPathComponent("TraccarClient.sqlite")
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        try! persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
        
        managedObjectContext = NSManagedObjectContext.init(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext?.persistentStoreCoordinator = persistentStoreCoordinator
        
        if userDefaults.bool(forKey: PreferenceKeys.serviceStatus.rawValue) {
            TraccarController.addStatusLog(message: "Service created")
            startService()
        }
    }
    
    func setConfigs(
        deviceId: String?, serverUrl: String?,
        interval: Int?, distance: Int?, angle: Int?,
        accuracyLevel: AccuracyLevel?, offlineBuffering: Bool?
    ) {
        let userDefaults = UserDefaults.standard
        if let value = deviceId {
            userDefaults.setValue(value, forKey: PreferenceKeys.deviceId.rawValue)
        }
        if let value = serverUrl {
            userDefaults.setValue(value, forKey: PreferenceKeys.serverUrl.rawValue)
        }
        if let value = interval {
            userDefaults.setValue(value, forKey: PreferenceKeys.frequency.rawValue)
        }
        if let value = distance {
            userDefaults.setValue(value, forKey: PreferenceKeys.distance.rawValue)
        }
        if let value = angle {
            userDefaults.setValue(value, forKey: PreferenceKeys.angle.rawValue)
        }
        if let value = accuracyLevel {
            userDefaults.setValue(value.rawValue, forKey: PreferenceKeys.accuracyLevel.rawValue)
        }
        if let value = offlineBuffering {
            userDefaults.setValue(value, forKey: PreferenceKeys.offlineBuffering.rawValue)
        }
    }
    
    func startService() {
        let userDefaults = UserDefaults.standard
        let url = userDefaults.string(forKey: PreferenceKeys.serverUrl.rawValue)
        let frequency = userDefaults.integer(forKey: PreferenceKeys.frequency.rawValue)

        let candidateUrl = NSURL(string: url!)
        if candidateUrl == nil || candidateUrl?.host == nil || (candidateUrl?.scheme != "http" && candidateUrl?.scheme != "https") {
            TraccarController.addStatusLog(message: "Invalid server URL")
            return
        }
        if frequency <= 0 {
            TraccarController.addStatusLog(message: "Invalid frequency value")
            return
        }
        UserDefaults.standard.setValue(true, forKey: PreferenceKeys.serviceStatus.rawValue)
        trackingController = TrackingController()
        trackingController?.start()
        TraccarController.addStatusLog(message: "Service created")
    }
    
    func stopService(){
        UserDefaults.standard.setValue(false, forKey: PreferenceKeys.serviceStatus.rawValue)
        trackingController?.stop()
        trackingController = nil
        TraccarController.addStatusLog(message: "Service destroyed")
    }
    
    func sosService(){
        positionProvider = PositionProvider()
        positionProvider?.delegate = self
        positionProvider?.startUpdates()
    }
    
    static func addStatusLog(message: String, comment: String = ""){
        StatusViewController.addMessage(NSLocalizedString(message, comment: message))
    }
    
    //    func setupShortcuts() {
    //
    //        let userDefaults = UserDefaults.standard
    //
    //        switch shortcutItem.type {
    //        case "org.traccar.client.start":
    //            startService()
    //        case "org.traccar.client.stop":
    //            stopService()
    //        case "org.traccar.client.sos":
    //            sosService()
    //        default:
    //            break
    //        }
    //
    //        completionHandler(true)
    //    }
    
    func didUpdate(position: Position) {
        
        positionProvider?.stopUpdates()
        positionProvider = nil
        
        let userDefaults = UserDefaults.standard
        
        if let request = ProtocolFormatter.formatPostion(position, url: userDefaults.string(forKey: PreferenceKeys.serverUrl.rawValue)!, alarm: "sos") {
            RequestManager.sendRequest(request, completionHandler: {(_ success: Bool) -> Void in
                if success {
                    TraccarController.addStatusLog(message: "Send successfully")
                } else {
                    TraccarController.addStatusLog(message: "Send failed")
                }
            })
        }
    }
    
    func terminate() {
        if let context = managedObjectContext {
            if context.hasChanges {
                try! context.save()
            }
        }
    }
    
    private func createManagedObjectModel() -> NSManagedObjectModel {
        let managedObjectModel = NSManagedObjectModel()
    
        let positionEntity = NSEntityDescription()
        positionEntity.name = "Position"
        positionEntity.managedObjectClassName = "Position"
//        positionEntity.classForCoder = Position.classForCoder()
    
        let accuracyAttribute = NSAttributeDescription()
        accuracyAttribute.name = "accuracy"
        accuracyAttribute.attributeType = .doubleAttributeType
        accuracyAttribute.isOptional = true
        accuracyAttribute.defaultValue = 0.0

        let altitudeAttribute = NSAttributeDescription()
        altitudeAttribute.name = "altitude"
        altitudeAttribute.attributeType = .doubleAttributeType
        altitudeAttribute.isOptional = true
        altitudeAttribute.defaultValue = 0.0

        let batteryAttribute = NSAttributeDescription()
        batteryAttribute.name = "battery"
        batteryAttribute.attributeType = .doubleAttributeType
        batteryAttribute.isOptional = true
        batteryAttribute.defaultValue = 0.0

        let chargingAttribute = NSAttributeDescription()
        chargingAttribute.name = "charging"
        chargingAttribute.attributeType = .booleanAttributeType
        chargingAttribute.isOptional = true

        let courseAttribute = NSAttributeDescription()
        courseAttribute.name = "course"
        courseAttribute.attributeType = .doubleAttributeType
        courseAttribute.isOptional = true
        courseAttribute.defaultValue = 0.0

        let deviceIdAttribute = NSAttributeDescription()
        deviceIdAttribute.name = "deviceId"
        deviceIdAttribute.attributeType = .stringAttributeType
        deviceIdAttribute.isOptional = true

        let latitudeAttribute = NSAttributeDescription()
        latitudeAttribute.name = "latitude"
        latitudeAttribute.attributeType = .doubleAttributeType
        latitudeAttribute.isOptional = true
        latitudeAttribute.defaultValue = 0.0

        let longitudeAttribute = NSAttributeDescription()
        longitudeAttribute.name = "longitude"
        longitudeAttribute.attributeType = .doubleAttributeType
        longitudeAttribute.isOptional = true
        longitudeAttribute.defaultValue = 0.0

        let speedAttribute = NSAttributeDescription()
        speedAttribute.name = "speed"
        speedAttribute.attributeType = .doubleAttributeType
        speedAttribute.isOptional = true
        speedAttribute.defaultValue = 0.0

        let timeAttribute = NSAttributeDescription()
        timeAttribute.name = "time"
        timeAttribute.attributeType = .dateAttributeType
        timeAttribute.isOptional = true

        positionEntity.properties = [
            accuracyAttribute,
            altitudeAttribute,
            batteryAttribute,
            chargingAttribute,
            courseAttribute,
            deviceIdAttribute,
            latitudeAttribute,
            longitudeAttribute,
            speedAttribute,
            timeAttribute
        ]

        managedObjectModel.entities = [positionEntity]

        return managedObjectModel
    }
    
    
    private func registerDefaultsFromSettingsBundle() {
        let defaults = [
            PreferenceKeys.serviceStatus.rawValue: false,
            PreferenceKeys.serverUrl.rawValue: "http://demo.traccar.org:5055",
            PreferenceKeys.frequency.rawValue: 300,
            PreferenceKeys.accuracyLevel.rawValue: AccuracyLevel.medium.rawValue,
            PreferenceKeys.offlineBuffering.rawValue: true,
        ] as [String : Any]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    private func migrateLegacyDefaults() {
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "server_address_preference") != nil {
            var urlComponents = URLComponents()
            urlComponents.scheme = userDefaults.bool(forKey: "secure_preference") ? "https" : "http"
            urlComponents.host = userDefaults.string(forKey: "server_address_preference")
            urlComponents.port = userDefaults.integer(forKey: "server_port_preference")
            if urlComponents.port == 0 {
                urlComponents.port = 5055
            }
            
            userDefaults.set(urlComponents.string, forKey: PreferenceKeys.serverUrl.rawValue)
            
            userDefaults.removeObject(forKey: "server_port_preference")
            userDefaults.removeObject(forKey: "server_address_preference")
            userDefaults.removeObject(forKey: "secure_preference")
        }
    }
    
}
