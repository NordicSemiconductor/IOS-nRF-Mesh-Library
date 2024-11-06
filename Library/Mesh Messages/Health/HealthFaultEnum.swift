/*
* Copyright (c) 2024, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*
* Created by Jules DOMMARTIN on 04/11/2024.
*/

public enum HealthFault {
    case noFault
    case batteryLowWarning
    case batteryLowError
    case supplyVoltageToLowWarning
    case supplyVoltageToLowError
    case supplyVoltageToHighWarning
    case supplyVoltageToHighError
    case powerSupplyInterruptedWarning
    case powerSupplyInterrputedError
    case noLoadWarning
    case noLoadError
    case overloadWarning
    case overloadError
    case overheatWarning
    case overheatError
    case condensationWarning
    case condensationError
    case vibrationWarning
    case vibrationError
    case configurationWarning
    case configurationError
    case elementNotCalibratedWarning
    case elementNotCalibratedError
    case memoryWarning
    case memoryError
    case selfTestWarning
    case selfTestError
    case inputTooLowWarning
    case inputTooLowError
    case inputTooHighWarning
    case inputTooHighError
    case inputNoChangeWarning
    case inputNoChangeError
    case actuatorBlockedWarning
    case actuatorBlockedError
    case housingOpenedWarning
    case housingOpenedError
    case tamperWarning
    case tamperError
    case deviceMovedWarning
    case deviceMovedError
    case deviceDroppedWarning
    case deviceDroppedError
    case overflowWarning
    case overflowError
    case emptyWarning
    case emptyError
    case internalBusWarning
    case internalBUError
    case mechanismJammedWarning
    case mechanismJammedError
    case vendor(_ id: UInt8)
        
    var id : UInt8 {
        switch self {
        case .noFault:
            return 0x00;
        case .batteryLowWarning:
            return 0x01;
        case .batteryLowError:
            return 0x02;
        case .supplyVoltageToLowWarning:
            return 0x03;
        case .supplyVoltageToLowError:
            return 0x04;
        case .supplyVoltageToHighWarning:
            return 0x05;
        case .supplyVoltageToHighError:
            return 0x06;
        case .powerSupplyInterruptedWarning:
            return 0x07;
        case .powerSupplyInterrputedError:
            return 0x08;
        case .noLoadWarning:
            return 0x09;
        case .noLoadError:
            return 0x0A;
        case .overloadWarning:
            return 0x0B;
        case .overloadError:
            return 0x0C;
        case .overheatWarning:
            return 0x0D;
        case .overheatError:
            return 0x0E;
        case .condensationWarning:
            return 0x0F;
        case .condensationError:
            return 0x10;
        case .vibrationWarning:
            return 0x11;
        case .vibrationError:
            return 0x12;
        case .configurationWarning:
            return 0x13;
        case .configurationError:
            return 0x14;
        case .elementNotCalibratedWarning:
            return 0x15;
        case .elementNotCalibratedError:
            return 0x16;
        case .memoryWarning:
            return 0x17;
        case .memoryError:
            return 0x18;
        case .selfTestWarning:
            return 0x19;
        case .selfTestError:
            return 0x1A;
        case .inputTooLowWarning:
            return 0x1B;
        case .inputTooLowError:
            return 0x1C;
        case .inputTooHighWarning:
            return 0x1D;
        case .inputTooHighError:
            return 0x1E;
        case .inputNoChangeWarning:
            return 0x1F;
        case .inputNoChangeError:
            return 0x20;
        case .actuatorBlockedWarning:
            return 0x21;
        case .actuatorBlockedError:
            return 0x22;
        case .housingOpenedWarning:
            return 0x23;
        case .housingOpenedError:
            return 0x24;
        case .tamperWarning:
            return 0x25;
        case .tamperError:
            return 0x26;
        case .deviceMovedWarning:
            return 0x27;
        case .deviceMovedError:
            return 0x28;
        case .deviceDroppedWarning:
            return 0x29;
        case .deviceDroppedError:
            return 0x2A;
        case .overflowWarning:
            return 0x2B;
        case .overflowError:
            return 0x2C;
        case .emptyWarning:
            return 0x2D;
        case .emptyError:
            return 0x2E;
        case .internalBusWarning:
            return 0x2F;
        case .internalBUError:
            return 0x30;
        case .mechanismJammedWarning:
            return 0x31;
        case .mechanismJammedError:
            return 0x32;
        case .vendor(let id):
            return id
        }
    }
    
    static func fromId(_ id: UInt8) -> HealthFault? {
        switch id {
        case 0x00:
            return .noFault;
        case 0x01:
            return .batteryLowWarning;
        case 0x02:
            return .batteryLowError;
        case 0x03:
            return .supplyVoltageToLowWarning;
        case 0x04:
            return .supplyVoltageToLowError;
        case 0x05:
            return .supplyVoltageToHighWarning;
        case 0x06:
            return .supplyVoltageToHighError;
        case 0x07:
            return .powerSupplyInterruptedWarning;
        case 0x08:
            return .powerSupplyInterrputedError;
        case 0x09:
            return .noLoadWarning;
        case 0x0A:
            return .noLoadError;
        case 0x0B:
            return .overloadWarning;
        case 0x0C:
            return .overloadError;
        case 0x0D:
            return .overheatWarning;
        case 0x0E:
            return .overheatError;
        case 0x0F:
            return .condensationWarning;
        case 0x10:
            return .condensationError;
        case 0x11:
            return .vibrationWarning;
        case 0x12:
            return .vibrationError;
        case 0x13:
            return .configurationWarning;
        case 0x14:
            return .configurationError;
        case 0x15:
            return .elementNotCalibratedWarning;
        case 0x16:
            return .elementNotCalibratedError;
        case 0x17:
            return .memoryWarning;
        case 0x18:
            return .memoryError;
        case 0x19:
            return .selfTestWarning;
        case 0x1A:
            return .selfTestError;
        case 0x1B:
            return .inputTooLowWarning;
        case 0x1C:
            return .inputTooLowError;
        case 0x1D:
            return .inputTooHighWarning;
        case 0x1E:
            return .inputTooHighError;
        case 0x1F:
            return .inputNoChangeWarning;
        case 0x20:
            return .inputNoChangeError;
        case 0x21:
            return .actuatorBlockedWarning;
        case 0x22:
            return .actuatorBlockedError;
        case 0x23:
            return .housingOpenedWarning;
        case 0x24:
            return .housingOpenedError;
        case 0x25:
            return .tamperWarning;
        case 0x26:
            return .tamperError;
        case 0x27:
            return .deviceMovedWarning;
        case 0x28:
            return .deviceMovedError;
        case 0x29:
            return .deviceDroppedWarning;
        case 0x2A:
            return .deviceDroppedError;
        case 0x2B:
            return .overflowWarning;
        case 0x2C:
            return .overflowError;
        case 0x2D:
            return .emptyWarning;
        case 0x2E:
            return .emptyError;
        case 0x2F:
            return .internalBusWarning;
        case 0x30:
            return .internalBUError;
        case 0x31:
            return .mechanismJammedWarning;
        case 0x32:
            return .mechanismJammedError;
        case 0x80...0xFF:
            return .vendor(id)
        default:
            return nil
        }
    }
}
