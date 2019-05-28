//
//  OpenSSLHelper.h
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/12/2017.
//

#import <Foundation/Foundation.h>

@interface OpenSSLHelper : NSObject
/// Generates 128-bit random data.
- (NSData*) generateRandom;

/// Calculates salt over given data.
/// @param someData A non-zero length octet array or ASCII encoded string.
- (NSData*) calculateSalt: (NSData*) someData;

/// Calculates Cipher-based Message Authentication Code (CMAC) that uses
/// AES-128 as the block cipher function, also known as AES-CMAC.
/// @param someData Data to be authenticated.
/// @param key The 128-bit key.
/// @return The 128-bit authentication code (MAC).
- (NSData*) calculateCMAC: (NSData*) someData andKey: (NSData*) key;

/// RFC3610 defines teh AES Counted with CBC-MAC (CCM).
/// This method generates ciphertext and MIC (Message Integrity Check).
/// @param someData The data to be encrypted and authenticated, also known as plaintext.
/// @param key The 128-bit key.
/// @param nonce A 104-bit nonce.
/// @param micSize Length of the MIC to be generated, in bytes.
/// @return Encrypted data concatenated with MIC of given size.
- (NSData*) calculateCCM: (NSData*) someData withKey: (NSData*) key nonce: (NSData *) nonce andMICSize: (UInt8) micSize;

/// Decrypts data encrypted with CCM.
/// @param someData Encrypted data.
/// @param key The 128-bit key.
/// @param nonce A 104-bit nonce.
/// @param mic Message Integrity Check data.
/// @return Decrypted data, if decryption is successful and MIC is valid, otherwise `nil`.
- (NSData*) calculateDecryptedCCM: (NSData*) someData withKey: (NSData*) key nonce: (NSData*) nonce andMIC: (NSData*) mic;

/// Obfuscates given data by XORing it with PECB, which is caluclated by encrypting
/// Privacy Plaintext (encrypted data (used as Privacy Random) and IV Index)
/// using the given key.
/// @param data The data to obfuscate.
/// @param privacyRandom Data used as Privacy Random.
- (NSData*) obfuscate: (NSData*) data usingPrivacyRandom: (NSData*) privacyRandom ivIndex: (UInt32) ivIndex andPrivacyKey: (NSData*) privacyKey;
- (NSData*) deobfuscate: (NSData*) data ivIndex: (UInt32) ivIndex privacyKey: (NSData*) privacyKey;

// MARK: - Helpers

- (NSData*) calculateK1WithN: (NSData*) N salt: (NSData*) salt andP: (NSData*) P;
- (NSData*) calculateK2WithN: (NSData*) N andP: (NSData*) aPValue;
- (NSData*) calculateK3WithN: (NSData*) N;
- (NSData*) calculateK4WithN: (NSData*) N;

/// Encrypts given data using the key.
/// @param someData Data to be encrypted.
/// @param key The 128-bit key.
- (NSData*) calculateEvalueWithData: (NSData*) someData andKey: (NSData*) key;
@end
