//
//  AppDelegate.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
                            
    var window: UIWindow?
    var locationManager = CLLocationManager()

    private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        locationManager.delegate = self
        
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) -> Void {
        let notification = UILocalNotification()
        
        if state == .inside {
            notification.alertBody = "You're inside the region"
        } else if state == .outside {
            notification.alertBody = "You're outside the region"
        } else {
            return
        }
        
        UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) -> Void {
        let cancelButtonTitle = "OK"
        let alert = UIAlertView(title: notification.alertBody, message: nil, delegate: nil, cancelButtonTitle: cancelButtonTitle)
        alert.show()
    }

}

