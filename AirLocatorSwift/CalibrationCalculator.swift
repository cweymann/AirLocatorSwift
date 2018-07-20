//
//  CalibrationCalculator.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/9/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import CoreLocation

class CalibrationCalculator : NSObject, CLLocationManagerDelegate {
    let CalibrationDwell = 20.0
    let AppErrorDomain = "com.ios.imdevin567.AirLocatorSwift"
    
    typealias CalibrationProgressHandler = (_ percentComplete: Float) -> Void
    typealias CalibrationCompletionHandler = (_ measuredPower: Int, _ error: NSError?) -> Void
    
    var progressHandler : CalibrationProgressHandler?
    var completionHandler : CalibrationCompletionHandler?
    
    var locationManager = CLLocationManager()
    var region : CLBeaconRegion?
    var calibrating = false
    var rangedBeacons = [[CLBeacon]]()
    var timer : Timer!
    var percentComplete : Float = 0
    
    init(region: CLBeaconRegion, completionHandler handler: @escaping CalibrationCompletionHandler) {
        super.init()
        self.locationManager.delegate = self
        self.region = region
        self.completionHandler = handler
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // Begin lock
        objc_sync_enter(self)
        
        rangedBeacons.append(beacons)
        
        if progressHandler != nil {
            DispatchQueue.main.async() {
                let addPercent = Float(1.0 / self.CalibrationDwell)
                self.percentComplete += addPercent
                self.progressHandler?(self.percentComplete)
            }
        }
        
        // End lock
        objc_sync_exit(self)
    }
    
    func performCalibrationWithProgressHandler(handler: @escaping CalibrationProgressHandler) {
        // Begin lock
        objc_sync_enter(self)
        
        if !calibrating {
            calibrating = true
            rangedBeacons.removeAll(keepingCapacity: false)
            percentComplete = 0
            progressHandler = handler
            
            if let region = self.region {
                locationManager.startRangingBeacons(in: region)
            }
            
            self.timer = Timer(fireAt: NSDate(timeIntervalSinceNow: CalibrationDwell) as Date, interval: 0, target: self, selector: #selector(CalibrationCalculator.timerElapsed(sender:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
            
        } else {
            let errorString = "Calibration is already in progress"
            let userInfo = ["Error string": errorString]
            let error = NSError(domain: AppErrorDomain, code: 4, userInfo: userInfo)
            
            DispatchQueue.main.async() {
                self.completionHandler!(0, error)
            }
        }
        
        // End lock
        objc_sync_exit(self)
    }
    
    func cancelCalibration() {
        // Begin lock
        objc_sync_enter(self)
        
        if calibrating  {
            calibrating = false
            timer?.fire()
        }
        
        // End lock
        objc_sync_exit(self)
    }
    
    @objc func timerElapsed(sender: Timer) {
        // Begin lock
        objc_sync_enter(self)
        
        if let region = self.region {
            locationManager.stopRangingBeacons(in: region)
        }
        
        DispatchQueue.global(qos: .background).async {
            // Begin more locks
            objc_sync_enter(self)
            
            var error : NSError? = nil
            var allBeacons = NSMutableArray()
            var measuredPower = 0
            
            if !self.calibrating {
                let errorString = "Calibration was cancelled"
                let userInfo = ["Error string": errorString]
                error = NSError(domain: self.AppErrorDomain, code: 2, userInfo: userInfo)
            } else {
                func enumBlock(index: Int, object: [CLBeacon], stop: inout Bool) -> Void {
                    if object.count > 1 {
                        let errorString = "More than one beacon of the specified type was found"
                        let userInfo = ["Error string": errorString]
                        error = NSError(domain: self.AppErrorDomain, code: 1, userInfo: userInfo)
                    } else {
                        allBeacons.addObjects(from: object)
                    }
                }
                
                for (index, object) in self.rangedBeacons.enumerated() {
                    var stop = false
                    enumBlock(index: index, object: object, stop: &stop)
                    
                    if stop {
                        break
                    }
                }
                
                if allBeacons.count <= 0 {
                    let errorString = "No beacon of the specified type was found"
                    let userInfo = ["Error string": errorString]
                    error = NSError(domain: self.AppErrorDomain, code: 3, userInfo: userInfo)
                } else {
                    let outlierPadding = Double(allBeacons.count) * 0.1
                    let sortDescriptor = [NSSortDescriptor(key: "rssi", ascending: true)]
                    allBeacons.sort(using: sortDescriptor)
                    let len = Double(allBeacons.count) - (outlierPadding * 2)
                    let range = NSMakeRange(Int(outlierPadding), Int(len))
                    let sample = allBeacons.subarray(with: range)
                    measuredPower = ((sample as NSArray).value(forKeyPath: "@avg.rssi")! as AnyObject).integerValue
                }
            }
            
            DispatchQueue.main.async() {
                self.completionHandler!(measuredPower, error!)
            }
            
            self.calibrating = false
            self.rangedBeacons.removeAll(keepingCapacity: false)
            self.progressHandler = nil
            
            objc_sync_exit(self)
        }
        
        // End lock
        objc_sync_exit(self)
    }
}
