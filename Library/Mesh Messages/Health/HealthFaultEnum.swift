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

public enum HealthFault: UInt8 {
    case noFault                        = 0x00
    case batteryLowWarning              = 0x01
    case batteryLowError                = 0x02
    case supplyVoltageToLowWarning      = 0x03
    case supplyVoltageToLowError        = 0x04
    case supplyVoltageToHighWarning     = 0x05
    case supplyVoltageToHighError       = 0x06
    case powerSupplyInterruptedWarning  = 0x07
    case powerSupplyInterrputedError    = 0x08
    case noLoadWarning                  = 0x09
    case noLoadError                    = 0x0A
    case overloadWarning                = 0x0B
    case overloadError                  = 0x0C
    case overheatWarning                = 0x0D
    case overheatError                  = 0x0E
    case condensationWarning            = 0x0F
    case condensationError              = 0x10
    case vibrationWarning               = 0x11
    case vibrationError                 = 0x12
    case configurationWarning           = 0x13
    case configurationError             = 0x14
    case elementNotCalibratedWarning    = 0x15
    case elementNotCalibratedError      = 0x16
    case memoryWarning                  = 0x17
    case memoryError                    = 0x18
    case selfTestWarning                = 0x19
    case selfTestError                  = 0x1A
    case inputTooLowWarning             = 0x1B
    case inputTooLowError               = 0x1C
    case inputTooHighWarning            = 0x1D
    case inputTooHighError              = 0x1E
    case inputNoChangeWarning           = 0x1F
    case inputNoChangeError             = 0x20
    case actuatorBlockedWarning         = 0x21
    case actuatorBlockedError           = 0x22
    case housingOpenedWarning           = 0x23
    case housingOpenedError             = 0x24
    case tamperWarning                  = 0x25
    case tamperError                    = 0x26
    case deviceMovedWarning             = 0x27
    case deviceMovedError               = 0x28
    case deviceDroppedWarning           = 0x29
    case deviceDroppedError             = 0x2A
    case overflowWarning                = 0x2B
    case overflowError                  = 0x2C
    case emptyWarning                   = 0x2D
    case emptyError                     = 0x2E
    case internalBusWarning             = 0x2F
    case internalBUError                = 0x30
    case mechanismJammedWarning         = 0x31
    case mechanismJammedError           = 0x32
}
