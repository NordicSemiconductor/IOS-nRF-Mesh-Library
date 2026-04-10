//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTTemporaryChunkQueue.h"

@implementation MFLTTemporaryChunkQueue {
    NSMutableArray<NSData *> *_queue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = [NSMutableArray array];
    }
    return self;
}

- (BOOL)addChunks:(NSArray<NSData *>*)chunks {
    @synchronized (self) {
        [_queue addObjectsFromArray:chunks];
    }
    return YES;
}

- (NSArray<NSData *>*)peek:(NSUInteger)count {
    @synchronized (self) {
        return [_queue subarrayWithRange:NSMakeRange(0, MIN(_queue.count, count))];
    }
}

- (void)drop:(NSUInteger)count {
    @synchronized (self) {
        [_queue removeObjectsInRange:NSMakeRange(0, MIN(_queue.count, count))];
    }
}

- (NSUInteger)count {
    @synchronized (self) {
        return _queue.count;
    }
}

@end


@implementation MFLTTemporaryChunkQueueProvider
- (id<MemfaultChunkQueue>)queueWithDeviceSerial:(NSString *_Nonnull)deviceSerial {
    return [[MFLTTemporaryChunkQueue alloc] init];
}
@end
