//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MemfaultCloud.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kMFLTChunkSenderDelayDefault (0.5)

@class MFLTBackoff;

@interface MFLTChunkSender : NSObject <MemfaultChunkSender>
@property (readonly) BOOL isPosting;
- (instancetype)initWithDeviceSerial:(NSString *)deviceSerial
                          chunkQueue:(id<MemfaultChunkQueue>)chunkQueue
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
                                 api:(MemfaultApi *)api
                               backoff:(MFLTBackoff *)backoff
              maxConsecutiveErrorCount:(NSInteger)maxConsecutiveErrorCount;

@end

NS_ASSUME_NONNULL_END
