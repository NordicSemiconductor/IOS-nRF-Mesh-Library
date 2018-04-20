//
//  MeshAddressTypes.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/02/2018.
//

import Foundation

enum MeshAddressTypes {
    case Unassigned
    case Unicast
    case Virtual
    case Group
    case Broadcast
    
    typealias RawValue = Data
    
    init?(rawValue: Data?) {
        guard let rawValue = rawValue else { return nil }

        //Fast checks first against Unassigned and Broadcast
        if rawValue == Data([0xFF, 0xFF]) {
            self = .Broadcast
        } else if rawValue == Data([0x00, 0x00]) {
            self = .Unassigned
        } else {
            //Not Broadcast nor Unassigned, check mask (first two bits)
            let mask = (rawValue.first! & 0xC0) // 0xC0 == 1100 0000
            switch mask {
                case 0xC0 : self = .Group     //11xx xxxx
                case 0x80 : self = .Virtual   //10xx xxxx
                default   : self = .Unicast //0xxx xxxx
            }
    }
   }
}
