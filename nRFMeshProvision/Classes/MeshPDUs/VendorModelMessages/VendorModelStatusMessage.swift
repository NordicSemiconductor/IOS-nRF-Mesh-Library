//
//  VendorModelStatusMessage
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct VendorModelStatusMessage {
    public var sourceAddress: Data
    public var payload: Data
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        payload = aPayload
    }
}
