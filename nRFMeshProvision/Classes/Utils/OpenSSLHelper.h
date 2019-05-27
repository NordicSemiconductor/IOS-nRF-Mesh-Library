//
//  OpenSSLHelper.h
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/12/2017.
//

#import <Foundation/Foundation.h>

@interface OpenSSLHelper : NSObject
- (NSData*) generateRandom;
- (NSData*) calculateSalt: (NSData*) someData;
- (NSData*) calculateCMAC: (NSData*) someData andKey: (NSData*) aKey;
- (NSData*) calculateCCM: (NSData*) someData withKey: (NSData*) aKey nonce: (NSData *) aNonce dataSize: (UInt8) aSize andMICSize: (UInt8) aMICSize;
- (NSData*) obfuscateNetworkPdu: (NSData*) encryptedData ctlTtlValue: (NSData*) aCtlTtlValue sequenceNumber: (NSData*) aSeq ivIndex: (NSData*) anIVIndex privacyKey: (NSData*) aPrivacyKey andSrcAddr: (NSData*) aSrc;
- (NSData*) deobfuscateNetworkPdu: (NSData*) data ivIndex: (UInt32) anIVIndex privacyKey: (NSData*) aPrivacyKey;
- (NSData*) calculateDecryptedCCM:(NSData *) someData withKey: (NSData *)aKey nonce: (NSData *)aNonce andMIC: (NSData*) aMIC;

//MARK: - Helpers
- (NSData*) calculateK1WithN: (NSData*) anNValue salt: (NSData*) aSaltValue andP: (NSData*) aPValue;
- (NSData*) calculateK2WithN: (NSData*) anNValue andP: (NSData*) aPValue;
- (NSData*) calculateK3WithN: (NSData*) anNValue;
- (NSData*) calculateK4WithN: (NSData*) anNValue;
- (NSData*) calculateEvalueWithData: (NSData*) someData andKey: (NSData*) aKey;
@end
