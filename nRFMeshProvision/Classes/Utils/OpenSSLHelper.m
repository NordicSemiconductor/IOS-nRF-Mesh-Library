//
//  OpenSSLHelper.m
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/12/2017.
//

#import "OpenSSLHelper.h"
#import "openssl/cmac.h"
#import "openssl/evp.h"
#import "openssl/rand.h"

@implementation OpenSSLHelper

- (NSData*) generateRandom {
    Byte buffer[16];
    int rc = RAND_bytes(buffer, sizeof(buffer));
    if (rc != 1) {
        NSLog(@"Failed to generate random bytes");
        return NULL;
    }
   return [[NSData alloc] initWithBytes: buffer length: sizeof(buffer)];
}

- (NSData*) calculateSalt: (NSData*) someData {
    //For S1, the key is constant
    unsigned char key[16] = {0x00};

    NSData* keyData = [[NSData alloc] initWithBytes: key length: 16];
    return [self calculateCMAC: someData andKey: keyData];
}

- (NSData*) calculateCMAC: (NSData*) someData andKey: (NSData*) key {
    unsigned char mact[16] = {0x00};
    size_t mactlen;

    CMAC_CTX *ctx = CMAC_CTX_new();
    CMAC_Init(ctx, (unsigned char*) [key bytes], [key length] / sizeof(unsigned char), EVP_aes_128_cbc(), NULL);
    CMAC_Update(ctx, (unsigned char*) [someData bytes], [someData length] / sizeof(unsigned char));
    CMAC_Final(ctx, mact, &mactlen);
    NSData *output = [[NSData alloc] initWithBytes: (const void*) mact length: sizeof(unsigned char) * mactlen];
    CMAC_CTX_free(ctx);
    return output;
}

- (NSData*) calculateECB: (NSData*) someData andKey: (NSData*) key {
    EVP_CIPHER_CTX *ctx;
    unsigned char iv[16] = {0x00};
    int len;
    int ciphertext_len;
    unsigned char outbuf[16] = {0x00};
    ctx = EVP_CIPHER_CTX_new();
    EVP_EncryptInit_ex(ctx, EVP_aes_128_ecb(), NULL, [key bytes], iv);
    EVP_EncryptUpdate(ctx, outbuf, &len, [someData bytes], (int) [someData length] / sizeof(unsigned char));
    ciphertext_len = len;
    EVP_EncryptFinal_ex(ctx, outbuf + len, &len);
    ciphertext_len += len;
    EVP_CIPHER_CTX_free(ctx);
    return [[NSData alloc] initWithBytes: outbuf length: 16];
}

- (NSData*) calculateCCM: (NSData*) someData withKey:(NSData*) key nonce:(NSData *) nonce andMICSize:(UInt8) size {
    int outlen = 0;
    int messageLength = (int) [someData length] / sizeof(unsigned char);
    int nonceLength = (int) [nonce length] / sizeof(unsigned char);
    int micLength = size;
    unsigned char outbuf[messageLength + micLength]; //octets for Encrypted data + octets for TAG (MIC)

    unsigned char* keyBytes = (unsigned char*) [key bytes];
    unsigned char* nonceBytes = (unsigned char*) [nonce bytes];
    unsigned char* messageBytes = (unsigned char*) [someData bytes];
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    EVP_EncryptInit_ex(ctx, EVP_aes_128_ccm(), NULL, NULL, NULL);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_IVLEN, nonceLength, NULL);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_TAG, micLength, NULL);
    EVP_EncryptInit_ex(ctx, NULL, NULL, keyBytes, nonceBytes);
    EVP_EncryptUpdate(ctx, NULL, &outlen, NULL, messageLength);
    EVP_EncryptUpdate(ctx, outbuf, &outlen, messageBytes, messageLength);
    EVP_EncryptFinal_ex(ctx, &outbuf[outlen], &outlen);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_GET_TAG, micLength, &outbuf[messageLength]);
    NSData* outputData = [[NSData alloc] initWithBytes: outbuf length: sizeof(outbuf)];
    EVP_CIPHER_CTX_free(ctx);
    return outputData;
}

- (NSData*) obfuscate: (NSData*) data usingPrivacyRandom: (NSData*) random ivIndex: (UInt32) ivIndex andPrivacyKey: (NSData*) privacyKey {
    NSMutableData* privacyRandomSource = [[NSMutableData alloc] init];
    [privacyRandomSource appendData: random];
    NSData* privacyRandom = [privacyRandomSource subdataWithRange: NSMakeRange(0, 7)];
    NSMutableData* pecbInputs = [[NSMutableData alloc] init];
    const unsigned ivIndexBigEndian = CFSwapInt32HostToBig(ivIndex);
    
    //Pad
    const char byteArray[] = { 0x00, 0x00, 0x00, 0x00, 0x00 };
    NSData* padding = [[NSData alloc] initWithBytes:byteArray length: 5];
    [pecbInputs appendData: padding];
    [pecbInputs appendData: [[NSData alloc] initWithBytes: &ivIndexBigEndian length: 4]];
    [pecbInputs appendData: privacyRandom];
    
    NSData* pecb = [[self calculateECB: pecbInputs andKey: privacyKey] subdataWithRange:NSMakeRange(0, 6)];
    
    NSData* obfuscatedData = [self xor: data withData: pecb];
    return obfuscatedData;
}

- (NSData*) deobfuscate: (NSData*) data ivIndex: (UInt32) ivIndex privacyKey: (NSData*) privacyKey {
    //Privacy random = EncDST || ENCTransportPDU || NetMIC [0-6]
    NSData* obfuscatedData = [data subdataWithRange: NSMakeRange(1, 6)];
    NSData* privacyRandom = [data subdataWithRange: NSMakeRange(7, 7)];
    const unsigned ivIndexBigEndian = CFSwapInt32HostToBig(ivIndex);
    
    //Pad
    const char byteArray[] = { 0x00, 0x00, 0x00, 0x00, 0x00 };
    NSData* padding = [[NSData alloc] initWithBytes: byteArray length: 5];
    NSMutableData* pecbInputs = [[NSMutableData alloc] init];
    [pecbInputs appendData: padding];
    [pecbInputs appendData: [[NSData alloc] initWithBytes: &ivIndexBigEndian length: 4]];
    [pecbInputs appendData: privacyRandom];
    
    NSData* pecb = [[self calculateECB:pecbInputs andKey: privacyKey] subdataWithRange: NSMakeRange(0, 6)];
    
    //DeobfuscatedData = CTL, TTL, SEQ, SRC
    NSData* deobfuscatedData = [self xor: obfuscatedData withData: pecb];
    return deobfuscatedData;
}

- (NSData*) calculateDecryptedCCM: (NSData*) someData withKey: (NSData*) key nonce: (NSData*) nonce andMIC: (NSData*) mic {
    int outlen;
    unsigned char outbuf[1024];
    
    int micLength = (int)[mic length] / sizeof(unsigned char);
    int messageLength = (int)[someData length] / sizeof(unsigned char);
    int nonceLength = (int) [nonce length] / sizeof(unsigned char);
    
    unsigned char* keyBytes     = (unsigned char*)[key bytes];
    unsigned char* nonceBytes   = (unsigned char*)[nonce bytes];
    unsigned char* messageBytes = (unsigned char*)[someData bytes];
    unsigned char* micBytes     = (unsigned char*)[mic bytes];
    
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    EVP_DecryptInit_ex(ctx, EVP_aes_128_ccm(), NULL, NULL, NULL);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_IVLEN, nonceLength, NULL);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_TAG, micLength, micBytes);
    EVP_DecryptInit_ex(ctx, NULL, NULL, keyBytes, nonceBytes);
    EVP_DecryptUpdate(ctx, NULL, &outlen, NULL, messageLength);
    int ret = EVP_DecryptUpdate(ctx, outbuf, &outlen, messageBytes, messageLength);
    EVP_CIPHER_CTX_free(ctx);
    if (ret > 0) {
        NSData* outputData = [[NSData alloc] initWithBytes:outbuf length:outlen];
        return outputData;
    } else {
        return nil;
    }
}

// MARK:- Helpers
- (NSData*) calculateK1WithN: (NSData*) N salt: (NSData*) salt andP: (NSData*) P {
    // Calculace K1 (outputs the confirmationKey).
    // T is calculated first using AES-CMAC N with SALT.
    NSData* t = [self calculateCMAC: N andKey: salt];
    // Then calculating AES-CMAC P with salt T.
    NSData* output = [self calculateCMAC: P andKey: t];
    return output;
}

- (NSData*) calculateK2WithN: (NSData*) N andP: (NSData*) P {
    const char byteArray[] = { 0x73, 0x6D, 0x6B, 0x32 }; //smk2 string.
    NSData* smk2String = [[NSData alloc] initWithBytes: byteArray length: 4];
    NSData* s1 = [self calculateSalt: smk2String];
    NSData* t = [self calculateCMAC: N andKey:s1];
    
    const unsigned char* pBytes = [P bytes];
    // Create T1 => (T0 || P || 0x01).
    NSMutableData *t1Inputs = [[NSMutableData alloc] init];
    [t1Inputs appendBytes:pBytes length:1];
    uint8_t one = 1;
    [t1Inputs appendBytes:&one length:1];
    
    NSData* t1 = [self calculateCMAC:t1Inputs andKey:t];
    
    // Create T2 => (T1 || P || 0x02).
    NSMutableData *t2Inputs = [[NSMutableData alloc] init];
    [t2Inputs appendData: t1];
    [t2Inputs appendBytes: pBytes length: P.length];
    uint8_t two = 0x02;
    [t2Inputs appendBytes: &two length:1];
    
    NSData* t2 = [self calculateCMAC: t2Inputs andKey: t];
    
    // Create T3 => (T2 || P || 0x03).
    NSMutableData *t3Inputs = [[NSMutableData alloc] init];
    [t3Inputs appendData: t2];
    [t3Inputs appendBytes: pBytes length: P.length];
    uint8_t three = 0x03;
    [t3Inputs appendBytes: &three length: 1];
    
    NSData* t3 = [self calculateCMAC:t3Inputs andKey:t];
    
    NSMutableData* finalData = [[NSMutableData alloc] init];
    [finalData appendData: t1];
    [finalData appendData: t2];
    [finalData appendData: t3];
    
    // data mod 2^264 (keeps last 14 bytes + 7 bits), as per K2 spec.
    const unsigned char* dataPtr = [finalData bytes];
    // We need only the first 7 bits from first octet, bitmask bit0 off.
    unsigned char firstOffset = dataPtr[15] & 0x7F;
    // Then get the rest of the data up to the 16th octet.
    finalData = (NSMutableData*)[finalData subdataWithRange: NSMakeRange(16, [finalData length] - 16)];
    // and concat the first octet with the chunked data, this is equivalent to removing first 15 octets - 7 bits).
    NSMutableData* output = [[NSMutableData alloc] init];
    [output appendBytes: &firstOffset length:1];
    [output appendData: finalData];
    
    return output;
}

- (NSData*) calculateK3WithN: (NSData*) N {
    // Calculace K3 (outputs public value).
    // SALT is clculated using S1 with smk3 in ascii.
    const char saltInput[] = { 0x73, 0x6D, 0x6B, 0x33 }; // smk3 string.
    NSData* saltInputData = [[NSData alloc] initWithBytes: saltInput length:4];
    NSData* salt = [self calculateSalt: saltInputData];
    // T is calculated first using AES-CMAC N with SALT.
    NSData* t = [self calculateCMAC: N andKey: salt];
    
    // id64 ascii => 0x69 0x64 0x36 0x34 || 0x01.
    const char cmacInput[] = { 0x69, 0x64, 0x36, 0x34, 0x01 }; // id64 string. || 0x01
    NSData* cmacInputData = [[NSData alloc] initWithBytes: cmacInput length: 5];
    NSData* finalData = [self calculateCMAC: cmacInputData andKey: t];
    
    // data mod 2^64 (keeps last 64 bits), as per K3 spec.
    NSData *output = (NSMutableData*) [finalData subdataWithRange: NSMakeRange(8, [finalData length] - 8)];
    return output;
}

- (NSData*) calculateK4WithN: (NSData*) N {
    // Calculace K4 (outputs 6 bit public value)
    // SALT is clculated using S1 with smk3 in ascii.
    const char saltInput[] = { 0x73, 0x6D, 0x6B, 0x34 }; // smk4 string.
    NSData* saltInputData = [[NSData alloc] initWithBytes: saltInput length:4];
    NSData* salt = [self calculateSalt: saltInputData];
    // T is calculated first using AES-CMAC N with SALT.
    NSData* t = [self calculateCMAC: N andKey: salt];
    
    // id64 ascii => 0x69 0x64 0x36 || 0x01
    const char cmacInput[] = { 0x69, 0x64, 0x36, 0x01 }; // id64 string || 0x01
    NSData* cmacInputData = [[NSData alloc] initWithBytes: cmacInput length: 4];
    NSData* finalData = [self calculateCMAC: cmacInputData andKey: t];
    
    // data mod 2^6 (keeps last 6 bits), as per K4 spec.
    const unsigned char* dataPtr = [finalData bytes];
    // We need only the last 6 bits from the octet, bitmask bit0 and bit1 off.
    const unsigned char outputBytes = dataPtr[15] & 0x3F;
    NSData *output = [[NSData alloc] initWithBytes: &outputBytes length: sizeof(outputBytes)];
    return output;
}

- (NSData*) calculateEvalueWithData: (NSData*) someData andKey: (NSData*) key {
    return [self calculateECB: someData andKey: key];
}

- (NSData*) xor: (NSData*) someData withData: (NSData*) otherData {
    const char *someDataBytes   = [someData bytes];
    const char *otherDataBytes  = [otherData bytes];
    NSMutableData *result = [[NSMutableData alloc] init];
    for (int i = 0; i < someData.length; i++){
        const char resultByte = someDataBytes[i] ^ otherDataBytes[i % otherData.length];
        [result appendBytes: &resultByte length: 1];
    }
   return result;
}
@end
