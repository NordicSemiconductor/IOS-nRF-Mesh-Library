//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MemfaultCloud.h"

@implementation MemfaultOtaPackage
- (NSString *)description
{
    return [NSString stringWithFormat:@"<MemfaultOtaPackage %p> softwareVersion: %@, location: %@", self, self.softwareVersion, self.location];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    MemfaultOtaPackage *otherPackage = object;
    return ([self.softwareVersion isEqual:otherPackage.softwareVersion] &&
            [self.location isEqual:otherPackage.location] &&
            [self.releaseNotes isEqual:otherPackage.releaseNotes]);
}

- (NSUInteger)hash
{
    return self.softwareVersion.hash ^ self.location.hash ^ self.releaseNotes.hash;
}
@end
