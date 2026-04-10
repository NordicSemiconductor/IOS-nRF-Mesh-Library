//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTDeviceInfo.h"

@interface MemfaultDeviceInfo ()
@property (readwrite, nonnull) NSString *softwareVersion;
@property (readwrite, nonnull) NSString *softwareType;
@property (readwrite, nonnull) NSString *deviceSerial;
@property (readwrite, nonnull) NSString *hardwareVersion;
@end

@implementation MemfaultDeviceInfo
+ (instancetype)infoWithDeviceSerial:(NSString *)deviceSerial
                     hardwareVersion:(NSString *)hardwareVersion
                     softwareVersion:(NSString *)softwareVersion
                     softwareType:(NSString *)softwareType
{
    MemfaultDeviceInfo *info = [[MemfaultDeviceInfo alloc] init];
    info.deviceSerial = deviceSerial;
    info.hardwareVersion = hardwareVersion;
    info.softwareVersion = softwareVersion;
    info.softwareType = softwareType;
    return info;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<MemfaultDeviceInfo: %p> softwareVersion: %@, softwareType: %@, hardwareVersion: %@, deviceSerial: %@",
            self, self.softwareVersion, self.softwareVersion, self.hardwareVersion, self.deviceSerial];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    if (![other isKindOfClass:[self class]]) {
        return NO;
    }
    MemfaultDeviceInfo *otherInfo = other;
    return ([self.deviceSerial isEqual:otherInfo.deviceSerial] &&
            [self.softwareVersion isEqual:otherInfo.softwareVersion] &&
            [self.softwareType isEqual:otherInfo.softwareType] &&
            [self.hardwareVersion isEqual:otherInfo.hardwareVersion]);
}

- (NSUInteger)hash
{
    return self.softwareVersion.hash ^ self.softwareType.hash ^ self.hardwareVersion.hash ^ self.deviceSerial.hash;
}
@end
