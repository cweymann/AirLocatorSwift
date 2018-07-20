//
//  UUIDViewController.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation
import UIKit


class UUIDViewController : UITableViewController {
    var uuid: UUID?
    let defaults = Defaults()
    
    // MARK: Table view data source
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return defaults.supportedProximityUUIDs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for:indexPath as IndexPath) as UITableViewCell
        
        if indexPath.row < defaults.supportedProximityUUIDs.count {
            cell.textLabel?.text = defaults.supportedProximityUUIDs[indexPath.row].uuidString
            
            if self.uuid == defaults.supportedProximityUUIDs[indexPath.row] {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }
        }
        
        return cell
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if let selectionIndexPath = tableView.indexPathForSelectedRow {
            var selection = 0
            
            if selectionIndexPath.row < defaults.supportedProximityUUIDs.count {
                selection = selectionIndexPath.row
            }
            
            uuid = defaults.supportedProximityUUIDs[selection]
        }
    }
}
