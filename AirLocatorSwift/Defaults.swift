//
//  Defaults.swift
//  AirLocatorSwift
//
//  Created by Devin Young on 6/7/14.
//  Copyright (c) 2014 Devin Young. All rights reserved.
//

import Foundation

class Defaults : NSObject {
    let BeaconIdentifier = "com.ios.imdevin567.AirLocatorSwift"
//    let supportedProximityUUIDs = [NSUUID(UUIDString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!, NSUUID(UUIDString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!, NSUUID(UUIDString: "74278BDA-B644-4520-8F0C-720EAF059935")!]
    let supportedProximityUUIDs = [UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!, UUID(uuidString: "74278BDA-B644-4520-8F0C-720EAF059935")!]
    let defaultPower = -59

    func defaultProximityUUID() -> UUID {
        return supportedProximityUUIDs[0]
    }
}
