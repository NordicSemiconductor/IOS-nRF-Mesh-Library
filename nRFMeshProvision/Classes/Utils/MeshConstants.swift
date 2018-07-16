//
//  MeshConstants.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 19/12/2017.
//

import Foundation
import CoreBluetooth

// MARK: - Mesh service identifires
//
public let MeshServiceProvisioningUUID             = CBUUID(string: "1827")
public let MeshServiceProxyUUID                    = CBUUID(string: "1828")

// MARK: - Mesh characteristics identifiers
public let MeshCharacteristicProvisionDataInUUID   = CBUUID(string: "2ADB")
public let MeshCharacteristicProvisionDataOutUUID  = CBUUID(string: "2ADC")
public let MeshCharacteristicProxyDataInUUID       = CBUUID(string: "2ADD")
public let MeshCharacteristicProxyDataOutUUID      = CBUUID(string: "2ADE")
