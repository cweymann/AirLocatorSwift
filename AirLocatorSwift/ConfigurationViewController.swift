//
//  ConfigurationViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/9/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

class ConfigurationViewController : UITableViewController, CBPeripheralManagerDelegate, UIAlertViewDelegate, UITextFieldDelegate {
    @IBOutlet var enabledSwitch : UISwitch!
    @IBOutlet var uuidTextField : UITextField!
    @IBOutlet var majorTextField : UITextField!
    @IBOutlet var minorTextField : UITextField!
    @IBOutlet var powerTextField : UITextField!
    
    var peripheralManager:CBPeripheralManager!
    var region : CLBeaconRegion?
    var power : Int = 0
    
    var enabled : Bool?
    var uuid : UUID?
    var major : NSNumber?
    var minor : NSNumber?
    var doneButton : UIBarButtonItem?
    var numberFormatter = NumberFormatter()
    
    let defaults = Defaults()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: UITableViewStyle.plain)
        peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(ConfigurationViewController.doneEditing(sender:)))
        
        if region != nil {
            uuid = region?.proximityUUID
            major = region?.major
            minor = region?.minor
        } else {
            uuid = defaults.defaultProximityUUID()
            major = NSNumber(value: 0)
            minor = NSNumber(value: 0)
        }
        
        power = defaults.defaultPower
        
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
        } else {
            peripheralManager.delegate = self
        }
        
        self.enabledSwitch.isOn = peripheralManager.isAdvertising
        enabled = enabledSwitch.isOn
        
        uuidTextField.text = uuid?.uuidString
        majorTextField.text = major?.stringValue
        minorTextField.text = minor?.stringValue
        powerTextField.text = String(power)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        peripheralManager.delegate = nil
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
    
    // MARK: Text editing
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == uuidTextField {
            self.performSegue(withIdentifier: "selectUUID", sender: self)
            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            if textField == majorTextField {
                major = numberFormatter.number(from: text)
            } else if textField == minorTextField {
                minor = numberFormatter.number(from: text)
            } else if textField == powerTextField {
                power = numberFormatter.number(from: text)!.intValue
                if power > 0 {
                    let negativePower = power - (power * 2)
                    power = negativePower
                    textField.text = String(power)
                }
            }
        }
        
        self.navigationItem.rightBarButtonItem = nil
        
        self.updateAdvertisedRegion()
    }
    
    @IBAction func toggleEnabled(sender: UISwitch) {
        enabled = sender.isOn
        self.updateAdvertisedRegion()
    }
    
    @IBAction func doneEditing(sender: AnyObject?) {
        majorTextField.resignFirstResponder()
        minorTextField.resignFirstResponder()
        powerTextField.resignFirstResponder()
        
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "selectUUID" {
            let uuidSelector : UUIDViewController = segue.destination as! UUIDViewController
            uuidSelector.uuid = self.uuid
        }
    }
    
    @IBAction func unwindUUIDSelector(sender: UIStoryboardSegue) {
        let uuidSelector : UUIDViewController = sender.source as! UUIDViewController
        self.uuid = uuidSelector.uuid
        self.updateAdvertisedRegion()
    }
    
    func updateAdvertisedRegion() {
        if (peripheralManager.state.rawValue < CBPeripheralManagerState.poweredOn.rawValue) {
            let title = "Bluetooth must be enabled"
            let message = "To configure your device as a beacon"
            let cancelButtonTitle = "OK"
            let errorAlert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle)
            errorAlert.show()
            
            return
        }
        
        peripheralManager.stopAdvertising()
        
        if (enabled != nil) {
            var majorShortValue: UInt16 = 0
            var minorShortValue: UInt16 = 0
            
            let majorInt = major?.intValue
            let minorInt = minor?.intValue
            
            majorShortValue = UInt16(majorInt!)
            minorShortValue = UInt16(minorInt!)
            
            region = CLBeaconRegion(proximityUUID: uuid! , major: majorShortValue, minor: minorShortValue, identifier: defaults.BeaconIdentifier)
            
            let peripheralData = NSDictionary(dictionary: (region?.peripheralData(withMeasuredPower: power as NSNumber))!) as! [String: AnyObject]
            peripheralManager.startAdvertising(peripheralData)

        }
    }
}
