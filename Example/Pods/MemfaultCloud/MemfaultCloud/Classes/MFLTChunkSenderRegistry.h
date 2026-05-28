//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MemfaultCloud.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//! Registry that ensures that per device serial, the same MemfaultChunkSender is used.
@protocol MemfaultChunkSenderRegistry
//! Gets the chunk sender for the given device serial.
- (id<MemfaultChunkSender>)senderWithDeviceSerial:(NSString *_Nonnull)deviceSerial;

//! Attempt to upload all enqueued chunks for all devices.
- (void)postChunks;

//! Stop sending chunks for all devices.
- (void)stop;
@end

@protocol MFLTChunkSenderFactory
- (id<MemfaultChunkSender>)createSenderWithDeviceSerial:(NSString *)deviceSerial;
@end

@interface MFLTChunkSenderRegistry : NSObject <MemfaultChunkSenderRegistry>
+ (MFLTChunkSenderRegistry *)createRegistry:(id<MFLTChunkSenderFactory>)senderFactory;
@end

NS_ASSUME_NONNULL_END
