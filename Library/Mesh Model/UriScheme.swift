/*
* Copyright (c) 2025, Nordic Semiconductor
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

/// An enum defining URI Schemes.
///
/// The values are defined by Bluetooth SIG.
///
/// Imported from:
/// [Assigned Numbers](https://www.bluetooth.com/specifications/assigned-numbers)
///  -> 2.7 URI Scheme Name String Mapping
public enum UriScheme: UInt8, Sendable {
    case emptySchemeName           = 0x01
    case aaa                       = 0x02
    case aaas                      = 0x03
    case about                     = 0x04
    case acap                      = 0x05
    case acct                      = 0x06
    case cap                       = 0x07
    case cid                       = 0x08
    case coap                      = 0x09
    case coaps                     = 0x0A
    case crid                      = 0x0B
    case data                      = 0x0C
    case dav                       = 0x0D
    case dict                      = 0x0E
    case dns                       = 0x0F
    case file                      = 0x10
    case ftp                       = 0x11
    case geo                       = 0x12
    case go                        = 0x13
    case gopher                    = 0x14
    case h323                      = 0x15
    case http                      = 0x16
    case https                     = 0x17
    case iax                       = 0x18
    case icap                      = 0x19
    case im                        = 0x1A
    case imap                      = 0x1B
    case info                      = 0x1C
    case ipp                       = 0x1D
    case ipps                      = 0x1E
    case iris                      = 0x1F
    case irisBeep                  = 0x20
    case irisXpc                   = 0x21
    case irisXpcs                  = 0x22
    case irisLwz                   = 0x23
    case jabber                    = 0x24
    case ldap                      = 0x25
    case mailto                    = 0x26
    case mid                       = 0x27
    case msrp                      = 0x28
    case msrps                     = 0x29
    case mtqp                      = 0x2A
    case mupdate                   = 0x2B
    case news                      = 0x2C
    case nfs                       = 0x2D
    case ni                        = 0x2E
    case nih                       = 0x2F
    case nntp                      = 0x30
    case opaquelocktoken           = 0x31
    case pop                       = 0x32
    case pres                      = 0x33
    case reload                    = 0x34
    case rtsp                      = 0x35
    case rtsps                     = 0x36
    case rtspu                     = 0x37
    case service                   = 0x38
    case session                   = 0x39
    case shttp                     = 0x3A
    case sieve                     = 0x3B
    case sip                       = 0x3C
    case sips                      = 0x3D
    case sms                       = 0x3E
    case snmp                      = 0x3F
    case soapBeep                  = 0x40
    case soapBeeps                 = 0x41
    case stun                      = 0x42
    case stuns                     = 0x43
    case tag                       = 0x44
    case tel                       = 0x45
    case telnet                    = 0x46
    case tftp                      = 0x47
    case thismessage               = 0x48
    case tn3270                    = 0x49
    case tip                       = 0x4A
    case turn                      = 0x4B
    case turns                     = 0x4C
    case tv                        = 0x4D
    case urn                       = 0x4E
    case vemmi                     = 0x4F
    case ws                        = 0x50
    case wss                       = 0x51
    case xcon                      = 0x52
    case xconUserid                = 0x53
    case xmlrpcBeep                = 0x54
    case xmlrpcBeeps               = 0x55
    case xmpp                      = 0x56
    case z39_50r                   = 0x57
    case z39_50s                   = 0x58
    case acr                       = 0x59
    case adiumxtra                 = 0x5A
    case afp                       = 0x5B
    case afs                       = 0x5C
    case aim                       = 0x5D
    case apt                       = 0x5E
    case attachment                = 0x5F
    case aw                        = 0x60
    case barion                    = 0x61
    case beshare                   = 0x62
    case bitcoin                   = 0x63
    case bolo                      = 0x64
    case callto                    = 0x65
    case chrome                    = 0x66
    case chromeExtension           = 0x67
    case comEventbriteAttendee     = 0x68
    case content                   = 0x69
    case cvs                       = 0x6A
    case dlnaPlaysingle            = 0x6B
    case dlnaPlaycontainer         = 0x6C
    case dtn                       = 0x6D
    case dvb                       = 0x6E
    case ed2k                      = 0x6F
    case facetime                  = 0x70
    case feed                      = 0x71
    case feedready                 = 0x72
    case finger                    = 0x73
    case fish                      = 0x74
    case gg                        = 0x75
    case git                       = 0x76
    case gizmoproject              = 0x77
    case gtalk                     = 0x78
    case ham                       = 0x79
    case hcp                       = 0x7A
    case icon                      = 0x7B
    case ipn                       = 0x7C
    case irc                       = 0x7D
    case irc6                      = 0x7E
    case ircs                      = 0x7F
    case itms                      = 0x80
    case jar                       = 0x81
    case jms                       = 0x82
    case keyparc                   = 0x83
    case lastfm                    = 0x84
    case ldaps                     = 0x85
    case magnet                    = 0x86
    case maps                      = 0x87
    case market                    = 0x88
    case message                   = 0x89
    case mms                       = 0x8A
    case msHelp                    = 0x8B
    case msSettingsPower           = 0x8C
    case msnim                     = 0x8D
    case mumble                    = 0x8E
    case mvn                       = 0x8F
    case notes                     = 0x90
    case oid                       = 0x91
    case palm                      = 0x92
    case paparazzi                 = 0x93
    case pkcs11                    = 0x94
    case platform                  = 0x95
    case proxy                     = 0x96
    case psyc                      = 0x97
    case query                     = 0x98
    case res                       = 0x99
    case resource                  = 0x9A
    case rmi                       = 0x9B
    case rsync                     = 0x9C
    case rtmfp                     = 0x9D
    case rtmp                      = 0x9E
    case secondlife                = 0x9F
    case sftp                      = 0xA0
    case sgn                       = 0xA1
    case skype                     = 0xA2
    case smb                       = 0xA3
    case smtp                      = 0xA4
    case soldat                    = 0xA5
    case spotify                   = 0xA6
    case ssh                       = 0xA7
    case steam                     = 0xA8
    case submit                    = 0xA9
    case svn                       = 0xAA
    case teamspeak                 = 0xAB
    case teliaeid                  = 0xAC
    case things                    = 0xAD
    case udp                       = 0xAE
    case unreal                    = 0xAF
    case ut2004                    = 0xB0
    case ventrilo                  = 0xB1
    case viewSource                = 0xB2
    case webcal                    = 0xB3
    case wtai                      = 0xB4
    case wyciwyg                   = 0xB5
    case xfire                     = 0xB6
    case xri                       = 0xB7
    case ymsgr                     = 0xB8
    case example                   = 0xB9
    case msSettingsCloudstorage    = 0xBA
}


extension UriScheme: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .emptySchemeName:        return "empty scheme name"
        case .aaa:                    return "aaa:"
        case .aaas:                   return "aaas:"
        case .about:                  return "about:"
        case .acap:                   return "acap:"
        case .acct:                   return "acct:"
        case .cap:                    return "cap:"
        case .cid:                    return "cid:"
        case .coap:                   return "coap:"
        case .coaps:                  return "coaps:"
        case .crid:                   return "crid:"
        case .data:                   return "data:"
        case .dav:                    return "dav:"
        case .dict:                   return "dict:"
        case .dns:                    return "dns:"
        case .file:                   return "file:"
        case .ftp:                    return "ftp:"
        case .geo:                    return "geo:"
        case .go:                     return "go:"
        case .gopher:                 return "gopher:"
        case .h323:                   return "h323:"
        case .http:                   return "http:"
        case .https:                  return "https:"
        case .iax:                    return "iax:"
        case .icap:                   return "icap:"
        case .im:                     return "im:"
        case .imap:                   return "imap:"
        case .info:                   return "info:"
        case .ipp:                    return "ipp:"
        case .ipps:                   return "ipps:"
        case .iris:                   return "iris:"
        case .irisBeep:               return "iris.beep:"
        case .irisXpc:                return "iris.xpc:"
        case .irisXpcs:               return "iris.xpcs:"
        case .irisLwz:                return "iris.lwz:"
        case .jabber:                 return "jabber:"
        case .ldap:                   return "ldap:"
        case .mailto:                 return "mailto:"
        case .mid:                    return "mid:"
        case .msrp:                   return "msrp:"
        case .msrps:                  return "msrps:"
        case .mtqp:                   return "mtqp:"
        case .mupdate:                return "mupdate:"
        case .news:                   return "news:"
        case .nfs:                    return "nfs:"
        case .ni:                     return "ni:"
        case .nih:                    return "nih:"
        case .nntp:                   return "nntp:"
        case .opaquelocktoken:        return "opaquelocktoken:"
        case .pop:                    return "pop:"
        case .pres:                   return "pres:"
        case .reload:                 return "reload:"
        case .rtsp:                   return "rtsp:"
        case .rtsps:                  return "rtsps:"
        case .rtspu:                  return "rtspu:"
        case .service:                return "service:"
        case .session:                return "session:"
        case .shttp:                  return "shttp:"
        case .sieve:                  return "sieve:"
        case .sip:                    return "sip:"
        case .sips:                   return "sips:"
        case .sms:                    return "sms:"
        case .snmp:                   return "snmp:"
        case .soapBeep:               return "soap.beep:"
        case .soapBeeps:              return "soap.beeps:"
        case .stun:                   return "stun:"
        case .stuns:                  return "stuns:"
        case .tag:                    return "tag:"
        case .tel:                    return "tel:"
        case .telnet:                 return "telnet:"
        case .tftp:                   return "tftp:"
        case .thismessage:            return "thismessage:"
        case .tn3270:                 return "tn3270:"
        case .tip:                    return "tip:"
        case .turn:                   return "turn:"
        case .turns:                  return "turns:"
        case .tv:                     return "tv:"
        case .urn:                    return "urn:"
        case .vemmi:                  return "vemmi:"
        case .ws:                     return "ws:"
        case .wss:                    return "wss:"
        case .xcon:                   return "xcon:"
        case .xconUserid:             return "xcon-userid:"
        case .xmlrpcBeep:             return "xmlrpc.beep:"
        case .xmlrpcBeeps:            return "xmlrpc.beeps:"
        case .xmpp:                   return "xmpp:"
        case .z39_50r:                return "z39.50r:"
        case .z39_50s:                return "z39.50s:"
        case .acr:                    return "acr:"
        case .adiumxtra:              return "adiumxtra:"
        case .afp:                    return "afp:"
        case .afs:                    return "afs:"
        case .aim:                    return "aim:"
        case .apt:                    return "apt:"
        case .attachment:             return "attachment:"
        case .aw:                     return "aw:"
        case .barion:                 return "barion:"
        case .beshare:                return "beshare:"
        case .bitcoin:                return "bitcoin:"
        case .bolo:                   return "bolo:"
        case .callto:                 return "callto:"
        case .chrome:                 return "chrome:"
        case .chromeExtension:        return "chrome-extension:"
        case .comEventbriteAttendee:  return "com-eventbrite-attendee:"
        case .content:                return "content:"
        case .cvs:                    return "cvs:"
        case .dlnaPlaysingle:         return "dlna-playsingle:"
        case .dlnaPlaycontainer:      return "dlna-playcontainer:"
        case .dtn:                    return "dtn:"
        case .dvb:                    return "dvb:"
        case .ed2k:                   return "ed2k:"
        case .facetime:               return "facetime:"
        case .feed:                   return "feed:"
        case .feedready:              return "feedready:"
        case .finger:                 return "finger:"
        case .fish:                   return "fish:"
        case .gg:                     return "gg:"
        case .git:                    return "git:"
        case .gizmoproject:           return "gizmoproject:"
        case .gtalk:                  return "gtalk:"
        case .ham:                    return "ham:"
        case .hcp:                    return "hcp:"
        case .icon:                   return "icon:"
        case .ipn:                    return "ipn:"
        case .irc:                    return "irc:"
        case .irc6:                   return "irc6:"
        case .ircs:                   return "ircs:"
        case .itms:                   return "itms:"
        case .jar:                    return "jar:"
        case .jms:                    return "jms:"
        case .keyparc:                return "keyparc:"
        case .lastfm:                 return "lastfm:"
        case .ldaps:                  return "ldaps:"
        case .magnet:                 return "magnet:"
        case .maps:                   return "maps:"
        case .market:                 return "market:"
        case .message:                return "message:"
        case .mms:                    return "mms:"
        case .msHelp:                 return "ms-help:"
        case .msSettingsPower:        return "ms-settings-power:"
        case .msnim:                  return "msnim:"
        case .mumble:                 return "mumble:"
        case .mvn:                    return "mvn:"
        case .notes:                  return "notes:"
        case .oid:                    return "oid:"
        case .palm:                   return "palm:"
        case .paparazzi:              return "paparazzi:"
        case .pkcs11:                 return "pkcs11:"
        case .platform:               return "platform:"
        case .proxy:                  return "proxy:"
        case .psyc:                   return "psyc:"
        case .query:                  return "query:"
        case .res:                    return "res:"
        case .resource:               return "resource:"
        case .rmi:                    return "rmi:"
        case .rsync:                  return "rsync:"
        case .rtmfp:                  return "rtmfp:"
        case .rtmp:                   return "rtmp:"
        case .secondlife:             return "secondlife:"
        case .sftp:                   return "sftp:"
        case .sgn:                    return "sgn:"
        case .skype:                  return "skype:"
        case .smb:                    return "smb:"
        case .smtp:                   return "smtp:"
        case .soldat:                 return "soldat:"
        case .spotify:                return "spotify:"
        case .ssh:                    return "ssh:"
        case .steam:                  return "steam:"
        case .submit:                 return "submit:"
        case .svn:                    return "svn:"
        case .teamspeak:              return "teamspeak:"
        case .teliaeid:               return "teliaeid:"
        case .things:                 return "things:"
        case .udp:                    return "udp:"
        case .unreal:                 return "unreal:"
        case .ut2004:                 return "ut2004:"
        case .ventrilo:               return "ventrilo:"
        case .viewSource:             return "view-source:"
        case .webcal:                 return "webcal:"
        case .wtai:                   return "wtai:"
        case .wyciwyg:                return "wyciwyg:"
        case .xfire:                  return "xfire:"
        case .xri:                    return "xri:"
        case .ymsgr:                  return "ymsgr:"
        case .example:                return "example:"
        case .msSettingsCloudstorage: return "ms-settings-cloudstorage:"
        }
    }
}
