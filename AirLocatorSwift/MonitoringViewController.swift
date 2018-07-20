//
//  MonitoringViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class MonitoringViewController : UITableViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    @IBOutlet var enabledSwitch: UISwitch!
    @IBOutlet var uuidTextField: UITextField!
    @IBOutlet var majorTextField: UITextField!
    @IBOutlet var minorTextField: UITextField!
    @IBOutlet var notifyOnEntrySwitch: UISwitch!
    @IBOutlet var notifyOnExitSwitch: UISwitch!
    @IBOutlet var notifyOnDisplaySwitch: UISwitch!
    
    var enabled: Bool?
    var uuid: UUID?
    var major: NSNumber?
    var minor: NSNumber?
    var notifyOnEntry: Bool?
    var notifyOnExit: Bool?
    var notifyOnDisplay: Bool?
    
    var doneButton: UIBarButtonItem?
    var numberFormatter = NumberFormatter()
    var locationManager = CLLocationManager()
    
    let defaults = Defaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        
        let region = CLBeaconRegion(proximityUUID: UUID() , identifier: defaults.BeaconIdentifier)
        if locationManager.monitoredRegions.contains(region) {
            enabled = true
            uuid = region.proximityUUID
            major = region.major
            majorTextField.text = major?.stringValue
            minor = region.minor
            minorTextField.text = minor?.stringValue
            notifyOnEntry = region.notifyOnEntry
            notifyOnExit = region.notifyOnExit
            notifyOnDisplay = region.notifyEntryStateOnDisplay
        } else {
            enabled = false
            uuid = defaults.defaultProximityUUID()
            notifyOnEntry = true
            notifyOnExit = true
            notifyOnDisplay = false
        }
        
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(doneEditing(sender:)))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        uuidTextField.text = uuid?.uuidString
        enabledSwitch.isOn = enabled!
        notifyOnEntrySwitch.isOn = notifyOnEntry!
        notifyOnExitSwitch.isOn = notifyOnExit!
        notifyOnDisplaySwitch.isOn = notifyOnDisplay!
    }
    
    // MARK: Toggling state
    
    @IBAction func toggleEnabled(sender: UISwitch) {
        enabled = sender.isOn
        updateMonitoredRegion()
    }
    
    @IBAction func toggleNotifyOnEntry(sender: UISwitch) {
        notifyOnEntry = sender.isOn
        updateMonitoredRegion()
    }
    
    @IBAction func toggleNotifyOnExit(sender: UISwitch) {
        notifyOnExit = sender.isOn
        updateMonitoredRegion()
    }
    
    @IBAction func toggleNotifyOnDisplay(sender: UISwitch) {
        notifyOnDisplay = sender.isOn
        updateMonitoredRegion()
    }
    
    // MARK: Text editing
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == uuidTextField {
            performSegue(withIdentifier: "selectUUID", sender: self)
            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        navigationItem.rightBarButtonItem = doneButton
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            if textField == majorTextField {
                major = numberFormatter.number(from: text)
            } else if textField == minorTextField {
                minor = numberFormatter.number(from: text)
            }
        }
        
        navigationItem.rightBarButtonItem = nil
        updateMonitoredRegion()
    }
    
    // MARK: Managing editing
    
    @IBAction func doneEditing(sender: AnyObject) {
        majorTextField.resignFirstResponder()
        minorTextField.resignFirstResponder()
        
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "selectUUID" {
            let uuidSelector = segue.destination as! UUIDViewController
            uuidSelector.uuid = uuid
        }
    }
    
    @IBAction func unwindUUIDSelector(sender: UIStoryboardSegue) {
        let uuidSelector = sender.source as! UUIDViewController
        
        uuid = uuidSelector.uuid
        updateMonitoredRegion()
    }
    
    func updateMonitoredRegion() {
        var region:CLBeaconRegion? = CLBeaconRegion(proximityUUID: UUID(), identifier: defaults.BeaconIdentifier)
        if let region = region {
            locationManager.stopMonitoring(for: region)
        }
        
        if (enabled != nil) {
            var majorShortValue: UInt16 = 0
            var minorShortValue: UInt16 = 0
            
            let majorInt = major?.int16Value
            let minorInt = minor?.int16Value
            
            majorShortValue = UInt16(majorInt!)
            minorShortValue = UInt16(minorInt!)
            
            if uuid != nil && major != nil && minor != nil {
                region = CLBeaconRegion(proximityUUID: uuid! , major: majorShortValue, minor: minorShortValue, identifier: defaults.BeaconIdentifier)
            } else if uuid != nil && major != nil {
                region = CLBeaconRegion(proximityUUID: uuid! , major: majorShortValue, identifier: defaults.BeaconIdentifier)
            } else if uuid != nil {
                region = CLBeaconRegion(proximityUUID: uuid! , identifier: defaults.BeaconIdentifier)
            }
            
            if let region = region {
                region.notifyOnEntry = notifyOnEntry!
                region.notifyOnExit = notifyOnExit!
                region.notifyEntryStateOnDisplay = notifyOnDisplay!
                
                locationManager.startMonitoring(for: region)
            }
            
        } else {
            region = CLBeaconRegion(proximityUUID: UUID() , identifier: defaults.BeaconIdentifier)
            if let region = region {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
}
 
