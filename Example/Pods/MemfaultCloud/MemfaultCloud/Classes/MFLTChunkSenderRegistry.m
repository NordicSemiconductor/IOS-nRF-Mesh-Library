//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTChunkSenderRegistry.h"

@implementation MFLTChunkSenderRegistry {
    id<MFLTChunkSenderFactory> _senderFactory;
    NSMutableDictionary<NSString *, id<MemfaultChunkSender>> *_sendersByDeviceSerial;
}

- (instancetype)init:(id<MFLTChunkSenderFactory>)senderFactory
{
    self = [super init];
    if (self) {
        _senderFactory = senderFactory;
        _sendersByDeviceSerial = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (MFLTChunkSenderRegistry *)createRegistry:(id<MFLTChunkSenderFactory>)senderFactory {
    return [[MFLTChunkSenderRegistry alloc] init:senderFactory];
}

- (id<MemfaultChunkSender>)senderWithDeviceSerial:(NSString *_Nonnull)deviceSerial {
    id<MemfaultChunkSender> sender = _sendersByDeviceSerial[deviceSerial];
    if (sender == nil) {
        _sendersByDeviceSerial[deviceSerial] = sender = [_senderFactory
                                                         createSenderWithDeviceSerial:deviceSerial];
    }
    return sender;
}

- (void)postChunks {
    [_sendersByDeviceSerial enumerateKeysAndObjectsUsingBlock:
     ^(NSString * _Nonnull key, id<MemfaultChunkSender> _Nonnull sender, BOOL * _Nonnull stop) {
        [sender postChunks];
    }];
}

- (void)stop {
    [_sendersByDeviceSerial enumerateKeysAndObjectsUsingBlock:
     ^(NSString * _Nonnull key, id<MemfaultChunkSender> _Nonnull sender, BOOL * _Nonnull stop) {
        [sender stop];
    }];
}

@end
