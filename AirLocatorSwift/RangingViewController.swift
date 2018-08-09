//
//  RangingViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class RangingViewController : UITableViewController, CLLocationManagerDelegate {
    var beacons = [String:[CLBeacon]]()
    var locationManager = CLLocationManager()
    var rangedRegions = [CLBeaconRegion]()
    var proximityBeacons : [AnyObject]?
    
    var immediates = [CLBeacon]()
    var unknowns = [CLBeacon]()
    var fars = [CLBeacon]()
    var nears = [CLBeacon]()
    
    let defaults = Defaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        for uuid in defaults.supportedProximityUUIDs {
            let region = CLBeaconRegion(proximityUUID: uuid , identifier: uuid.uuidString)
            
            rangedRegions.append(region)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        for (region) in rangedRegions {
            locationManager.startRangingBeacons(in: region)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        for (region) in rangedRegions {
            locationManager.stopRangingBeacons(in: region)
        }
    }
    
    // MARK: Location manager delegate

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        self.beacons.removeAll(keepingCapacity: false)
        
        for indBeacon in beacons {
            switch indBeacon.proximity.rawValue {
            case CLProximity.immediate.rawValue:
                immediates.append(indBeacon)
            case CLProximity.unknown.rawValue:
                unknowns.append(indBeacon)
            case CLProximity.far.rawValue:
                fars.append(indBeacon)
            case CLProximity.near.rawValue:
                nears.append(indBeacon)
            default:
                print("") // do nothing
            }
        }
        
        self.beacons["Immediate"] = immediates
        self.beacons["Unknown"] = unknowns
        self.beacons["Far"] = fars
        self.beacons["Near"] = nears
        
        tableView.reloadData()
    }

    // MARK: Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.beacons.count
    }
   
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionValues = Array(self.beacons.values)
        return sectionValues[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionKeys = Array(self.beacons.keys)
        let sectionKey : String = sectionKeys[section]
        
        return sectionKey
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "Cell"
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        let sectionKey = Array(self.beacons.keys)[indexPath.section]
        if let beacon = self.beacons[sectionKey]?[indexPath.section] {
            cell.textLabel?.text = beacon.proximityUUID.uuidString
            cell.detailTextLabel?.text = "Major: \(beacon.major), Minor: \(beacon.minor), Acc: \(beacon.accuracy)"
        }
        
        
        return cell as UITableViewCell
    }
    
    
}
