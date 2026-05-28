//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MemfaultCloud.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFLTTemporaryChunkQueue : NSObject <MemfaultChunkQueue>
@end

@interface MFLTTemporaryChunkQueueProvider  : NSObject <MemfaultChunkQueueProvider>
@end

NS_ASSUME_NONNULL_END
