//
//  CalibrationBeginViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/10/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class CalibrationBeginViewController : UITableViewController, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    var rangedRegions = [CLBeaconRegion]()
    var beacons = [String :[CLBeacon]]()
    var defaults = Defaults()
    
    var immediates = [CLBeacon]()
    var unknowns = [CLBeacon]()
    var fars = [CLBeacon]()
    var nears = [CLBeacon]()
    
    var calculator : CalibrationCalculator?
    var inProgress : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        for uuid in defaults.supportedProximityUUIDs {
            let region = CLBeaconRegion(proximityUUID: uuid , identifier: uuid.uuidString)
            rangedRegions.append(region)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startRangingAllRegions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.calculator?.cancelCalibration()
        self.stopRangingAllRegions()
    }
    
    // MARK: Ranging beacons
    
    func startRangingAllRegions() {
        for (region) in rangedRegions {
            locationManager.startRangingBeacons(in: region)
        }
    }
    
    func stopRangingAllRegions() {
        for (region) in rangedRegions {
            locationManager.stopRangingBeacons(in: region)
        }
    }
    
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
    
    func updateProgressViewWithProgress(percentComplete: Float) {
        if !inProgress {
            return
        }
        
        let indexPath = IndexPath(row: 0, section: 0)
        let progressCell = self.tableView.cellForRow(at: indexPath as IndexPath) as! ProgressTableViewCell
        progressCell.progressView.setProgress(percentComplete, animated: true)
    }
    
    // MARK: Table view data source/delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let i = inProgress ? beacons.count + 1 : beacons.count
        return i
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var adjustedSection = section
        
        if inProgress {
            if adjustedSection == 0 {
                return 1
            } else {
                adjustedSection -= 1
            }
        }
        
        let sectionValues = Array(beacons.values)
        return sectionValues[adjustedSection].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var adjustedSection = section
        
        if inProgress  {
            if adjustedSection == 0 {
                return nil
            } else {
                adjustedSection -= 1
            }
        }
        
        let sectionKeys = Array(beacons.keys)
        let sectionKey = sectionKeys[adjustedSection]
        
        return sectionKey
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let beaconCellIdentifier = "BeaconCell"
        let progressCellIdentifier = "ProgressCell"
        var section = indexPath.section
        let identifier = (inProgress && section == 0) ? progressCellIdentifier : beaconCellIdentifier
        let cell : UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: identifier)
        
        if identifier == progressCellIdentifier {
            return cell as UITableViewCell
        } else if inProgress {
            section -= 1
        }
        
        let sectionKey = Array(beacons.keys)[section]
        if let beacon = beacons[sectionKey]?[indexPath.row] {
            cell.textLabel?.text = beacon.proximityUUID.uuidString
            cell.detailTextLabel?.text = "Major: \(beacon.major), Minor: \(beacon.minor), Acc: \(beacon.accuracy)"
        }
        
        return cell
    }
    
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionKey = Array(beacons.keys)[indexPath.section]
        if let beacon = self.beacons[sectionKey]?[indexPath.section] {
            if !inProgress {
                
                let major = CLBeaconMajorValue(beacon.major.int16Value)
                let minor = CLBeaconMajorValue(beacon.minor.int16Value)
                let region = CLBeaconRegion(proximityUUID: beacon.proximityUUID, major: major, minor: minor, identifier: defaults.BeaconIdentifier)

                self.stopRangingAllRegions()
                
                calculator = CalibrationCalculator(region: region) { measuredPower, error in
                    if let error = error {
                        if (self.view.window != nil) {
                            let title = "Unable to calibrate device"
                            let cancelTitle = "OK"
                            let alert = UIAlertView(title: title, message: error.userInfo.description, delegate: nil, cancelButtonTitle: cancelTitle)
                            alert.show()
                            
                            self.startRangingAllRegions()
                        }
                    } else {
                        if let endViewController = self.storyboard?.instantiateViewController(withIdentifier: "EndViewController") as? CalibrationEndViewController {
                            endViewController.measuredPower = measuredPower
                            self.navigationController?.pushViewController(endViewController, animated: true)
                        }
                    }
                    
                    self.inProgress = false
                    self.calculator = nil
                    
                    tableView.reloadData()
                }
                
                calculator?.performCalibrationWithProgressHandler { [weak self] percentComplete in
                    if let weakSelf = self {
                        weakSelf.updateProgressViewWithProgress(percentComplete: percentComplete)
                    }
                }
                
                inProgress = true
                tableView.beginUpdates()
                tableView.insertSections(NSIndexSet(index: 0) as IndexSet, with: UITableViewRowAnimation.automatic)
                
                let indexPath = IndexPath(row: 0, section: 0)
                tableView.insertRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.automatic)
                tableView.endUpdates()
                self.updateProgressViewWithProgress(percentComplete: 0.0)
            }
        }

    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if inProgress && indexPath.section == 0 {
            return 66.0
        }
        
        return 44.0
    }
    
}
