/*
* Copyright (c) 2019, Nordic Semiconductor
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
*/

import Foundation

/// An enum defining options for a location of an ``Element``.
///
/// The values are defined by Bluetooth SIG.
///
/// Imported from:
/// https://www.bluetooth.com/specifications/assigned-numbers -> GATT Namespace Descriptors
public enum Location: UInt16, Codable {
    case auxiliary                    = 0x0108
    case back                         = 0x0101
    case backup                       = 0x0107
    case bottom                       = 0x0103
    case eighteenth                   = 0x0012
    case eighth                       = 0x0008
    case eightieth                    = 0x0050
    case eightyEighth                 = 0x0058
    case eightyFifth                  = 0x0055
    case eightyFirst                  = 0x0051
    case eightyFourth                 = 0x0054
    case eightyNineth                 = 0x0059
    case eightySecond                 = 0x0052
    case eightySeventh                = 0x0057
    case eightySixth                  = 0x0056
    case eightyThird                  = 0x0053
    case eleventh                     = 0x000b
    case external                     = 0x0110
    case fifteenth                    = 0x000f
    case fifth                        = 0x0005
    case fiftieth                     = 0x0032
    case fiftyEighth                  = 0x003a
    case fiftyFifth                   = 0x0037
    case fiftyFirst                   = 0x0033
    case fiftyFourth                  = 0x0036
    case fiftyNineth                  = 0x003b
    case fiftySecond                  = 0x0034
    case fiftySeventh                 = 0x0039
    case fiftySixth                   = 0x0038
    case fiftyThird                   = 0x0035
    case first                        = 0x0001
    case flash                        = 0x010A
    case fortieth                     = 0x0028
    case fourteenth                   = 0x000e
    case fourth                       = 0x0004
    case fourtyEighth                 = 0x0030
    case fourtyFifth                  = 0x002d
    case fourtyFirst                  = 0x0029
    case fourtyFourth                 = 0x002c
    case fourtyNineth                 = 0x0031
    case fourtySecond                 = 0x002a
    case fourtySeventh                = 0x002f
    case fourtySixth                  = 0x002e
    case fourtyThird                  = 0x002b
    case front                        = 0x0100
    case inside                       = 0x010B
    case `internal`                   = 0x010F
    case left                         = 0x010D
    case lower                        = 0x0105
    case main                         = 0x0106
    case nineteenth                   = 0x0013
    case nineth                       = 0x0009
    case ninetieth                    = 0x005a
    case ninetyEighth                 = 0x0062
    case ninetyFifth                  = 0x005f
    case ninetyFirst                  = 0x005b
    case ninetyFourth                 = 0x005e
    case ninetyNineth                 = 0x0063
    case ninetySecond                 = 0x005c
    case ninetySeventh                = 0x0061
    case ninetySixth                  = 0x0060
    case ninetyThird                  = 0x005d
    case oneHundredAndEighteenth      = 0x0076
    case oneHundredAndEighth          = 0x006c
    case oneHundredAndEightyEighth    = 0x00bc
    case oneHundredAndEightyFifth     = 0x00b9
    case oneHundredAndEightyFirst     = 0x00b5
    case oneHundredAndEightyFourth    = 0x00b8
    case oneHundredAndEightyNineth    = 0x00bd
    case oneHundredAndEightySecond    = 0x00b6
    case oneHundredAndEightySeventh   = 0x00bb
    case oneHundredAndEightySixth     = 0x00ba
    case oneHundredAndEightyThird     = 0x00b7
    case oneHundredAndEleventh        = 0x006f
    case oneHundredAndFifteenth       = 0x0073
    case oneHundredAndFifth           = 0x0069
    case oneHundredAndFiftyEighth     = 0x009e
    case oneHundredAndFiftyFifth      = 0x009b
    case oneHundredAndFiftyFirst      = 0x0097
    case oneHundredAndFiftyFourth     = 0x009a
    case oneHundredAndFiftyNineth     = 0x009f
    case oneHundredAndFiftySecond     = 0x0098
    case oneHundredAndFiftySeventh    = 0x009d
    case oneHundredAndFiftySixth      = 0x009c
    case oneHundredAndFiftyThird      = 0x0099
    case oneHundredAndFirst           = 0x0065
    case oneHundredAndFourteenth      = 0x0072
    case oneHundredAndFourth          = 0x0068
    case oneHundredAndFourtyEighth    = 0x0094
    case oneHundredAndFourtyFifth     = 0x0091
    case oneHundredAndFourtyFirst     = 0x008d
    case oneHundredAndFourtyFourth    = 0x0090
    case oneHundredAndFourtyNineth    = 0x0095
    case oneHundredAndFourtySecond    = 0x008e
    case oneHundredAndFourtySeventh   = 0x0093
    case oneHundredAndFourtySixth     = 0x0092
    case oneHundredAndFourtyThird     = 0x008f
    case oneHundredAndNineteenth      = 0x0077
    case oneHundredAndNineth          = 0x006d
    case oneHundredAndNinetyEighth    = 0x00c6
    case oneHundredAndNinetyFifth     = 0x00c3
    case oneHundredAndNinetyFirst     = 0x00bf
    case oneHundredAndNinetyFourth    = 0x00c2
    case oneHundredAndNinetyNineth    = 0x00c7
    case oneHundredAndNinetySecond    = 0x00c0
    case oneHundredAndNinetySeventh   = 0x00c5
    case oneHundredAndNinetySixth     = 0x00c4
    case oneHundredAndNinetyThird     = 0x00c1
    case oneHundredAndSecond          = 0x0066
    case oneHundredAndSeventeenth     = 0x0075
    case oneHundredAndSeventh         = 0x006b
    case oneHundredAndSeventyEighth   = 0x00b2
    case oneHundredAndSeventyFifth    = 0x00af
    case oneHundredAndSeventyFirst    = 0x00ab
    case oneHundredAndSeventyFourth   = 0x00ae
    case oneHundredAndSeventyNineth   = 0x00b3
    case oneHundredAndSeventySecond   = 0x00ac
    case oneHundredAndSeventySeventh  = 0x00b1
    case oneHundredAndSeventySixth    = 0x00b0
    case oneHundredAndSeventyThird    = 0x00ad
    case oneHundredAndSixteenth       = 0x0074
    case oneHundredAndSixth           = 0x006a
    case oneHundredAndSixtyEighth     = 0x00a8
    case oneHundredAndSixtyFifth      = 0x00a5
    case oneHundredAndSixtyFirst      = 0x00a1
    case oneHundredAndSixtyFourth     = 0x00a4
    case oneHundredAndSixtyNineth     = 0x00a9
    case oneHundredAndSixtySecond     = 0x00a2
    case oneHundredAndSixtySeventh    = 0x00a7
    case oneHundredAndSixtySixth      = 0x00a6
    case oneHundredAndSixtyThird      = 0x00a3
    case oneHundredAndTenth           = 0x006e
    case oneHundredAndThird           = 0x0067
    case oneHundredAndThirteenth      = 0x0071
    case oneHundredAndThirtyEighth    = 0x008a
    case oneHundredAndThirtyFifth     = 0x0087
    case oneHundredAndThirtyFirst     = 0x0083
    case oneHundredAndThirtyFourth    = 0x0086
    case oneHundredAndThirtyNineth    = 0x008b
    case oneHundredAndThirtySecond    = 0x0084
    case oneHundredAndThirtySeventh   = 0x0089
    case oneHundredAndThirtySixth     = 0x0088
    case oneHundredAndThirtyThird     = 0x0085
    case oneHundredAndTwelveth        = 0x0070
    case oneHundredAndTwentyEighth    = 0x0080
    case oneHundredAndTwentyFifth     = 0x007d
    case oneHundredAndTwentyFirst     = 0x0079
    case oneHundredAndTwentyFourth    = 0x007c
    case oneHundredAndTwentyNineth    = 0x0081
    case oneHundredAndTwentySecond    = 0x007a
    case oneHundredAndTwentySeventh   = 0x007f
    case oneHundredAndTwentySixth     = 0x007e
    case oneHundredAndTwentyThird     = 0x007b
    case oneHundredEightieth          = 0x00b4
    case oneHundredFiftieth           = 0x0096
    case oneHundredFortieth           = 0x008c
    case oneHundredNinetieth          = 0x00be
    case oneHundredSeventieth         = 0x00aa
    case oneHundredSixtieth           = 0x00a0
    case oneHundredThirtieth          = 0x0082
    case oneHundredTwentieth          = 0x0078
    case oneHundredth                 = 0x0064
    case outside                      = 0x010C
    case right                        = 0x010E
    case second                       = 0x0002
    case seventeenth                  = 0x0011
    case seventh                      = 0x0007
    case seventieth                   = 0x0046
    case seventyEighth                = 0x004e
    case seventyFifth                 = 0x004b
    case seventyFirst                 = 0x0047
    case seventyFourth                = 0x004a
    case seventyNineth                = 0x004f
    case seventySecond                = 0x0048
    case seventySeventh               = 0x004d
    case seventySixth                 = 0x004c
    case seventyThird                 = 0x0049
    case sixteenth                    = 0x0010
    case sixth                        = 0x0006
    case sixtieth                     = 0x003c
    case sixtyEighth                  = 0x0044
    case sixtyFifth                   = 0x0041
    case sixtyFirst                   = 0x003d
    case sixtyFourth                  = 0x0040
    case sixtyNineth                  = 0x0045
    case sixtySecond                  = 0x003e
    case sixtySeventh                 = 0x0043
    case sixtySixth                   = 0x0042
    case sixtyThird                   = 0x003f
    case supplementary                = 0x0109
    case tenth                        = 0x000a
    case third                        = 0x0003
    case thirteenth                   = 0x000d
    case thirtieth                    = 0x001e
    case thirtyEighth                 = 0x0026
    case thirtyFifth                  = 0x0023
    case thirtyFirst                  = 0x001f
    case thirtyFourth                 = 0x0022
    case thirtyNineth                 = 0x0027
    case thirtySecond                 = 0x0020
    case thirtySeventh                = 0x0025
    case thirtySixth                  = 0x0024
    case thirtyThird                  = 0x0021
    case top                          = 0x0102
    case twelveth                     = 0x000c
    case twentieth                    = 0x0014
    case twentyEighth                 = 0x001c
    case twentyFifth                  = 0x0019
    case twentyFirst                  = 0x0015
    case twentyFourth                 = 0x0018
    case twentyNineth                 = 0x001d
    case twentySecond                 = 0x0016
    case twentySeventh                = 0x001b
    case twentySixth                  = 0x001a
    case twentyThird                  = 0x0017
    case twoHundredAndEighteenth      = 0x00da
    case twoHundredAndEighth          = 0x00d0
    case twoHundredAndEleventh        = 0x00d3
    case twoHundredAndFifteenth       = 0x00d7
    case twoHundredAndFifth           = 0x00cd
    case twoHundredAndFiftyFifth      = 0x00ff
    case twoHundredAndFiftyFirst      = 0x00fb
    case twoHundredAndFiftyFourth     = 0x00fe
    case twoHundredAndFiftySecond     = 0x00fc
    case twoHundredAndFiftyThird      = 0x00fd
    case twoHundredAndFirst           = 0x00c9
    case twoHundredAndFourteenth      = 0x00d6
    case twoHundredAndFourth          = 0x00cc
    case twoHundredAndFourtyEighth    = 0x00f8
    case twoHundredAndFourtyFifth     = 0x00f5
    case twoHundredAndFourtyFirst     = 0x00f1
    case twoHundredAndFourtyFourth    = 0x00f4
    case twoHundredAndFourtyNineth    = 0x00f9
    case twoHundredAndFourtySecond    = 0x00f2
    case twoHundredAndFourtySeventh   = 0x00f7
    case twoHundredAndFourtySixth     = 0x00f6
    case twoHundredAndFourtyThird     = 0x00f3
    case twoHundredAndNineteenth      = 0x00db
    case twoHundredAndNineth          = 0x00d1
    case twoHundredAndSecond          = 0x00ca
    case twoHundredAndSeventeenth     = 0x00d9
    case twoHundredAndSeventh         = 0x00cf
    case twoHundredAndSixteenth       = 0x00d8
    case twoHundredAndSixth           = 0x00ce
    case twoHundredAndTenth           = 0x00d2
    case twoHundredAndThird           = 0x00cb
    case twoHundredAndThirteenth      = 0x00d5
    case twoHundredAndThirtyEighth    = 0x00ee
    case twoHundredAndThirtyFifth     = 0x00eb
    case twoHundredAndThirtyFirst     = 0x00e7
    case twoHundredAndThirtyFourth    = 0x00ea
    case twoHundredAndThirtyNineth    = 0x00ef
    case twoHundredAndThirtySecond    = 0x00e8
    case twoHundredAndThirtySeventh   = 0x00ed
    case twoHundredAndThirtySixth     = 0x00ec
    case twoHundredAndThirtyThird     = 0x00e9
    case twoHundredAndTwelveth        = 0x00d4
    case twoHundredAndTwentyEighth    = 0x00e4
    case twoHundredAndTwentyFifth     = 0x00e1
    case twoHundredAndTwentyFirst     = 0x00dd
    case twoHundredAndTwentyFourth    = 0x00e0
    case twoHundredAndTwentyNineth    = 0x00e5
    case twoHundredAndTwentySecond    = 0x00de
    case twoHundredAndTwentySeventh   = 0x00e3
    case twoHundredAndTwentySixth     = 0x00e2
    case twoHundredAndTwentyThird     = 0x00df
    case twoHundredFiftieth           = 0x00fa
    case twoHundredFortieth           = 0x00f0
    case twoHundredThirtieth          = 0x00e6
    case twoHundredTwentieth          = 0x00dc
    case twoHundredth                 = 0x00c8
    case unknown                      = 0x0000
    case upper                        = 0x0104
}

internal extension Location {
    
    var hex: String {
        return rawValue.hex
    }
    
}

extension Location: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .auxiliary                   : return "Auxiliary"
        case .back                        : return "Back"
        case .backup                      : return "Backup"
        case .bottom                      : return "Bottom"
        case .eighteenth                  : return "Eighteenth"
        case .eighth                      : return "Eighth"
        case .eightieth                   : return "Eightieth"
        case .eightyEighth                : return "Eighty-eighth"
        case .eightyFifth                 : return "Eighty-fifth"
        case .eightyFirst                 : return "Eighty-first"
        case .eightyFourth                : return "Eighty-fourth"
        case .eightyNineth                : return "Eighty-nineth"
        case .eightySecond                : return "Eighty-second"
        case .eightySeventh               : return "Eighty-seventh"
        case .eightySixth                 : return "Eighty-sixth"
        case .eightyThird                 : return "Eighty-third"
        case .eleventh                    : return "Eleventh"
        case .external                    : return "External"
        case .fifteenth                   : return "Fifteenth"
        case .fifth                       : return "Fifth"
        case .fiftieth                    : return "Fiftieth"
        case .fiftyEighth                 : return "Fifty-eighth"
        case .fiftyFifth                  : return "Fifty-fifth"
        case .fiftyFirst                  : return "Fifty-first"
        case .fiftyFourth                 : return "Fifty-fourth"
        case .fiftyNineth                 : return "Fifty-nineth"
        case .fiftySecond                 : return "Fifty-second"
        case .fiftySeventh                : return "Fifty-seventh"
        case .fiftySixth                  : return "Fifty-sixth"
        case .fiftyThird                  : return "Fifty-third"
        case .first                       : return "First"
        case .flash                       : return "Flash"
        case .fortieth                    : return "Fortieth"
        case .fourteenth                  : return "Fourteenth"
        case .fourth                      : return "Fourth"
        case .fourtyEighth                : return "Fourty-eighth"
        case .fourtyFifth                 : return "Fourty-fifth"
        case .fourtyFirst                 : return "Fourty-first"
        case .fourtyFourth                : return "Fourty-fourth"
        case .fourtyNineth                : return "Fourty-nineth"
        case .fourtySecond                : return "Fourty-second"
        case .fourtySeventh               : return "Fourty-seventh"
        case .fourtySixth                 : return "Fourty-sixth"
        case .fourtyThird                 : return "Fourty-third"
        case .front                       : return "Front"
        case .inside                      : return "Inside"
        case .`internal`                  : return "Internal"
        case .left                        : return "Left"
        case .lower                       : return "Lower"
        case .main                        : return "Main"
        case .nineteenth                  : return "Nineteenth"
        case .nineth                      : return "Nineth"
        case .ninetieth                   : return "Ninetieth"
        case .ninetyEighth                : return "Ninety-eighth"
        case .ninetyFifth                 : return "Ninety-fifth"
        case .ninetyFirst                 : return "Ninety-first"
        case .ninetyFourth                : return "Ninety-fourth"
        case .ninetyNineth                : return "Ninety-nineth"
        case .ninetySecond                : return "Ninety-second"
        case .ninetySeventh               : return "Ninety-seventh"
        case .ninetySixth                 : return "Ninety-sixth"
        case .ninetyThird                 : return "Ninety-third"
        case .oneHundredAndEighteenth     : return "One-hundred-and-eighteenth"
        case .oneHundredAndEighth         : return "One-hundred-and-eighth"
        case .oneHundredAndEightyEighth   : return "One-hundred-and-eighty-eighth"
        case .oneHundredAndEightyFifth    : return "One-hundred-and-eighty-fifth"
        case .oneHundredAndEightyFirst    : return "One-hundred-and-eighty-first"
        case .oneHundredAndEightyFourth   : return "One-hundred-and-eighty-fourth"
        case .oneHundredAndEightyNineth   : return "One-hundred-and-eighty-nineth"
        case .oneHundredAndEightySecond   : return "One-hundred-and-eighty-second"
        case .oneHundredAndEightySeventh  : return "One-hundred-and-eighty-seventh"
        case .oneHundredAndEightySixth    : return "One-hundred-and-eighty-sixth"
        case .oneHundredAndEightyThird    : return "One-hundred-and-eighty-third"
        case .oneHundredAndEleventh       : return "One-hundred-and-eleventh"
        case .oneHundredAndFifteenth      : return "One-hundred-and-fifteenth"
        case .oneHundredAndFifth          : return "One-hundred-and-fifth"
        case .oneHundredAndFiftyEighth    : return "One-hundred-and-fifty-eighth"
        case .oneHundredAndFiftyFifth     : return "One-hundred-and-fifty-fifth"
        case .oneHundredAndFiftyFirst     : return "One-hundred-and-fifty-first"
        case .oneHundredAndFiftyFourth    : return "One-hundred-and-fifty-fourth"
        case .oneHundredAndFiftyNineth    : return "One-hundred-and-fifty-nineth"
        case .oneHundredAndFiftySecond    : return "One-hundred-and-fifty-second"
        case .oneHundredAndFiftySeventh   : return "One-hundred-and-fifty-seventh"
        case .oneHundredAndFiftySixth     : return "One-hundred-and-fifty-sixth"
        case .oneHundredAndFiftyThird     : return "One-hundred-and-fifty-third"
        case .oneHundredAndFirst          : return "One-hundred-and-first"
        case .oneHundredAndFourteenth     : return "One-hundred-and-fourteenth"
        case .oneHundredAndFourth         : return "One-hundred-and-fourth"
        case .oneHundredAndFourtyEighth   : return "One-hundred-and-fourty-eighth"
        case .oneHundredAndFourtyFifth    : return "One-hundred-and-fourty-fifth"
        case .oneHundredAndFourtyFirst    : return "One-hundred-and-fourty-first"
        case .oneHundredAndFourtyFourth   : return "One-hundred-and-fourty-fourth"
        case .oneHundredAndFourtyNineth   : return "One-hundred-and-fourty-nineth"
        case .oneHundredAndFourtySecond   : return "One-hundred-and-fourty-second"
        case .oneHundredAndFourtySeventh  : return "One-hundred-and-fourty-seventh"
        case .oneHundredAndFourtySixth    : return "One-hundred-and-fourty-sixth"
        case .oneHundredAndFourtyThird    : return "One-hundred-and-fourty-third"
        case .oneHundredAndNineteenth     : return "One-hundred-and-nineteenth"
        case .oneHundredAndNineth         : return "One-hundred-and-nineth"
        case .oneHundredAndNinetyEighth   : return "One-hundred-and-ninety-eighth"
        case .oneHundredAndNinetyFifth    : return "One-hundred-and-ninety-fifth"
        case .oneHundredAndNinetyFirst    : return "One-hundred-and-ninety-first"
        case .oneHundredAndNinetyFourth   : return "One-hundred-and-ninety-fourth"
        case .oneHundredAndNinetyNineth   : return "One-hundred-and-ninety-nineth"
        case .oneHundredAndNinetySecond   : return "One-hundred-and-ninety-second"
        case .oneHundredAndNinetySeventh  : return "One-hundred-and-ninety-seventh"
        case .oneHundredAndNinetySixth    : return "One-hundred-and-ninety-sixth"
        case .oneHundredAndNinetyThird    : return "One-hundred-and-ninety-third"
        case .oneHundredAndSecond         : return "One-hundred-and-second"
        case .oneHundredAndSeventeenth    : return "One-hundred-and-seventeenth"
        case .oneHundredAndSeventh        : return "One-hundred-and-seventh"
        case .oneHundredAndSeventyEighth  : return "One-hundred-and-seventy-eighth"
        case .oneHundredAndSeventyFifth   : return "One-hundred-and-seventy-fifth"
        case .oneHundredAndSeventyFirst   : return "One-hundred-and-seventy-first"
        case .oneHundredAndSeventyFourth  : return "One-hundred-and-seventy-fourth"
        case .oneHundredAndSeventyNineth  : return "One-hundred-and-seventy-nineth"
        case .oneHundredAndSeventySecond  : return "One-hundred-and-seventy-second"
        case .oneHundredAndSeventySeventh : return "One-hundred-and-seventy-seventh"
        case .oneHundredAndSeventySixth   : return "One-hundred-and-seventy-sixth"
        case .oneHundredAndSeventyThird   : return "One-hundred-and-seventy-third"
        case .oneHundredAndSixteenth      : return "One-hundred-and-sixteenth"
        case .oneHundredAndSixth          : return "One-hundred-and-sixth"
        case .oneHundredAndSixtyEighth    : return "One-hundred-and-sixty-eighth"
        case .oneHundredAndSixtyFifth     : return "One-hundred-and-sixty-fifth"
        case .oneHundredAndSixtyFirst     : return "One-hundred-and-sixty-first"
        case .oneHundredAndSixtyFourth    : return "One-hundred-and-sixty-fourth"
        case .oneHundredAndSixtyNineth    : return "One-hundred-and-sixty-nineth"
        case .oneHundredAndSixtySecond    : return "One-hundred-and-sixty-second"
        case .oneHundredAndSixtySeventh   : return "One-hundred-and-sixty-seventh"
        case .oneHundredAndSixtySixth     : return "One-hundred-and-sixty-sixth"
        case .oneHundredAndSixtyThird     : return "One-hundred-and-sixty-third"
        case .oneHundredAndTenth          : return "One-hundred-and-tenth"
        case .oneHundredAndThird          : return "One-hundred-and-third"
        case .oneHundredAndThirteenth     : return "One-hundred-and-thirteenth"
        case .oneHundredAndThirtyEighth   : return "One-hundred-and-thirty-eighth"
        case .oneHundredAndThirtyFifth    : return "One-hundred-and-thirty-fifth"
        case .oneHundredAndThirtyFirst    : return "One-hundred-and-thirty-first"
        case .oneHundredAndThirtyFourth   : return "One-hundred-and-thirty-fourth"
        case .oneHundredAndThirtyNineth   : return "One-hundred-and-thirty-nineth"
        case .oneHundredAndThirtySecond   : return "One-hundred-and-thirty-second"
        case .oneHundredAndThirtySeventh  : return "One-hundred-and-thirty-seventh"
        case .oneHundredAndThirtySixth    : return "One-hundred-and-thirty-sixth"
        case .oneHundredAndThirtyThird    : return "One-hundred-and-thirty-third"
        case .oneHundredAndTwelveth       : return "One-hundred-and-twelveth"
        case .oneHundredAndTwentyEighth   : return "One-hundred-and-twenty-eighth"
        case .oneHundredAndTwentyFifth    : return "One-hundred-and-twenty-fifth"
        case .oneHundredAndTwentyFirst    : return "One-hundred-and-twenty-first"
        case .oneHundredAndTwentyFourth   : return "One-hundred-and-twenty-fourth"
        case .oneHundredAndTwentyNineth   : return "One-hundred-and-twenty-nineth"
        case .oneHundredAndTwentySecond   : return "One-hundred-and-twenty-second"
        case .oneHundredAndTwentySeventh  : return "One-hundred-and-twenty-seventh"
        case .oneHundredAndTwentySixth    : return "One-hundred-and-twenty-sixth"
        case .oneHundredAndTwentyThird    : return "One-hundred-and-twenty-third"
        case .oneHundredEightieth         : return "One-hundred-eightieth"
        case .oneHundredFiftieth          : return "One-hundred-fiftieth"
        case .oneHundredFortieth          : return "One-hundred-fortieth"
        case .oneHundredNinetieth         : return "One-hundred-ninetieth"
        case .oneHundredSeventieth        : return "One-hundred-seventieth"
        case .oneHundredSixtieth          : return "One-hundred-sixtieth"
        case .oneHundredThirtieth         : return "One-hundred-thirtieth"
        case .oneHundredTwentieth         : return "One-hundred-twentieth"
        case .oneHundredth                : return "One-hundredth"
        case .outside                     : return "Outside"
        case .right                       : return "Right"
        case .second                      : return "Second"
        case .seventeenth                 : return "Seventeenth"
        case .seventh                     : return "Seventh"
        case .seventieth                  : return "Seventieth"
        case .seventyEighth               : return "Seventy-eighth"
        case .seventyFifth                : return "Seventy-fifth"
        case .seventyFirst                : return "Seventy-first"
        case .seventyFourth               : return "Seventy-fourth"
        case .seventyNineth               : return "Seventy-nineth"
        case .seventySecond               : return "Seventy-second"
        case .seventySeventh              : return "Seventy-seventh"
        case .seventySixth                : return "Seventy-sixth"
        case .seventyThird                : return "Seventy-third"
        case .sixteenth                   : return "Sixteenth"
        case .sixth                       : return "Sixth"
        case .sixtieth                    : return "Sixtieth"
        case .sixtyEighth                 : return "Sixty-eighth"
        case .sixtyFifth                  : return "Sixty-fifth"
        case .sixtyFirst                  : return "Sixty-first"
        case .sixtyFourth                 : return "Sixty-fourth"
        case .sixtyNineth                 : return "Sixty-nineth"
        case .sixtySecond                 : return "Sixty-second"
        case .sixtySeventh                : return "Sixty-seventh"
        case .sixtySixth                  : return "Sixty-sixth"
        case .sixtyThird                  : return "Sixty-third"
        case .supplementary               : return "Supplementary"
        case .tenth                       : return "Tenth"
        case .third                       : return "Third"
        case .thirteenth                  : return "Thirteenth"
        case .thirtieth                   : return "Thirtieth"
        case .thirtyEighth                : return "Thirty-eighth"
        case .thirtyFifth                 : return "Thirty-fifth"
        case .thirtyFirst                 : return "Thirty-first"
        case .thirtyFourth                : return "Thirty-fourth"
        case .thirtyNineth                : return "Thirty-nineth"
        case .thirtySecond                : return "Thirty-second"
        case .thirtySeventh               : return "Thirty-seventh"
        case .thirtySixth                 : return "Thirty-sixth"
        case .thirtyThird                 : return "Thirty-third"
        case .top                         : return "Top"
        case .twelveth                    : return "Twelveth"
        case .twentieth                   : return "Twentieth"
        case .twentyEighth                : return "Twenty-eighth"
        case .twentyFifth                 : return "Twenty-fifth"
        case .twentyFirst                 : return "Twenty-first"
        case .twentyFourth                : return "Twenty-fourth"
        case .twentyNineth                : return "Twenty-nineth"
        case .twentySecond                : return "Twenty-second"
        case .twentySeventh               : return "Twenty-seventh"
        case .twentySixth                 : return "Twenty-sixth"
        case .twentyThird                 : return "Twenty-third"
        case .twoHundredAndEighteenth     : return "Two-hundred-and-eighteenth"
        case .twoHundredAndEighth         : return "Two-hundred-and-eighth"
        case .twoHundredAndEleventh       : return "Two-hundred-and-eleventh"
        case .twoHundredAndFifteenth      : return "Two-hundred-and-fifteenth"
        case .twoHundredAndFifth          : return "Two-hundred-and-fifth"
        case .twoHundredAndFiftyFifth     : return "Two-hundred-and-fifty-fifth"
        case .twoHundredAndFiftyFirst     : return "Two-hundred-and-fifty-first"
        case .twoHundredAndFiftyFourth    : return "Two-hundred-and-fifty-fourth"
        case .twoHundredAndFiftySecond    : return "Two-hundred-and-fifty-second"
        case .twoHundredAndFiftyThird     : return "Two-hundred-and-fifty-third"
        case .twoHundredAndFirst          : return "Two-hundred-and-first"
        case .twoHundredAndFourteenth     : return "Two-hundred-and-fourteenth"
        case .twoHundredAndFourth         : return "Two-hundred-and-fourth"
        case .twoHundredAndFourtyEighth   : return "Two-hundred-and-fourty-eighth"
        case .twoHundredAndFourtyFifth    : return "Two-hundred-and-fourty-fifth"
        case .twoHundredAndFourtyFirst    : return "Two-hundred-and-fourty-first"
        case .twoHundredAndFourtyFourth   : return "Two-hundred-and-fourty-fourth"
        case .twoHundredAndFourtyNineth   : return "Two-hundred-and-fourty-nineth"
        case .twoHundredAndFourtySecond   : return "Two-hundred-and-fourty-second"
        case .twoHundredAndFourtySeventh  : return "Two-hundred-and-fourty-seventh"
        case .twoHundredAndFourtySixth    : return "Two-hundred-and-fourty-sixth"
        case .twoHundredAndFourtyThird    : return "Two-hundred-and-fourty-third"
        case .twoHundredAndNineteenth     : return "Two-hundred-and-nineteenth"
        case .twoHundredAndNineth         : return "Two-hundred-and-nineth"
        case .twoHundredAndSecond         : return "Two-hundred-and-second"
        case .twoHundredAndSeventeenth    : return "Two-hundred-and-seventeenth"
        case .twoHundredAndSeventh        : return "Two-hundred-and-seventh"
        case .twoHundredAndSixteenth      : return "Two-hundred-and-sixteenth"
        case .twoHundredAndSixth          : return "Two-hundred-and-sixth"
        case .twoHundredAndTenth          : return "Two-hundred-and-tenth"
        case .twoHundredAndThird          : return "Two-hundred-and-third"
        case .twoHundredAndThirteenth     : return "Two-hundred-and-thirteenth"
        case .twoHundredAndThirtyEighth   : return "Two-hundred-and-thirty-eighth"
        case .twoHundredAndThirtyFifth    : return "Two-hundred-and-thirty-fifth"
        case .twoHundredAndThirtyFirst    : return "Two-hundred-and-thirty-first"
        case .twoHundredAndThirtyFourth   : return "Two-hundred-and-thirty-fourth"
        case .twoHundredAndThirtyNineth   : return "Two-hundred-and-thirty-nineth"
        case .twoHundredAndThirtySecond   : return "Two-hundred-and-thirty-second"
        case .twoHundredAndThirtySeventh  : return "Two-hundred-and-thirty-seventh"
        case .twoHundredAndThirtySixth    : return "Two-hundred-and-thirty-sixth"
        case .twoHundredAndThirtyThird    : return "Two-hundred-and-thirty-third"
        case .twoHundredAndTwelveth       : return "Two-hundred-and-twelveth"
        case .twoHundredAndTwentyEighth   : return "Two-hundred-and-twenty-eighth"
        case .twoHundredAndTwentyFifth    : return "Two-hundred-and-twenty-fifth"
        case .twoHundredAndTwentyFirst    : return "Two-hundred-and-twenty-first"
        case .twoHundredAndTwentyFourth   : return "Two-hundred-and-twenty-fourth"
        case .twoHundredAndTwentyNineth   : return "Two-hundred-and-twenty-nineth"
        case .twoHundredAndTwentySecond   : return "Two-hundred-and-twenty-second"
        case .twoHundredAndTwentySeventh  : return "Two-hundred-and-twenty-seventh"
        case .twoHundredAndTwentySixth    : return "Two-hundred-and-twenty-sixth"
        case .twoHundredAndTwentyThird    : return "Two-hundred-and-twenty-third"
        case .twoHundredFiftieth          : return "Two-hundred-fiftieth"
        case .twoHundredFortieth          : return "Two-hundred-fortieth"
        case .twoHundredThirtieth         : return "Two-hundred-thirtieth"
        case .twoHundredTwentieth         : return "Two-hundred-twentieth"
        case .twoHundredth                : return "Two-hundredth"
        case .unknown                     : return "Unknown"
        case .upper                       : return "Upper"
        }
    }
    
}
