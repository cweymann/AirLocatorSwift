//
//  CalibrationEndViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/9/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit

class CalibrationEndViewController : UIViewController {
    @IBOutlet var measuredPowerLabel : UILabel!
    
    var measuredPower : Int?
    
    @objc func doneButtonTapped(sender: AnyObject?) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(doneButtonTapped(sender:)))
        self.navigationItem.rightBarButtonItem = doneButton
        measuredPowerLabel.text = "\(String(describing: self.measuredPower))"
    }
    
    func setMeasuredPower(measuredPower: Int) {
        self.measuredPower = measuredPower
        self.measuredPowerLabel.text = "\(measuredPower)"
    }
}
