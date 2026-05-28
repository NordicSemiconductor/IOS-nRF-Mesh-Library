//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTChunkSender.h"

#import "MemfaultApi.h"
#import "MFLTBackoff.h"
#import "MFLTScope.h"

#define kMFLTChunksMaxChunksPerRequest (100)

@implementation MFLTChunkSender {
    NSString *_deviceSerial;
    id<MemfaultChunkQueue> _chunkQueue;
    __weak MemfaultApi *_api;
    dispatch_queue_t _dispatchQueue;
    BOOL _isPosting;
    BOOL _stopped;
    MFLTBackoff *_backoff;
    NSInteger _consecutiveErrorCount;
    NSInteger _maxConsecutiveErrorCount;
}
@synthesize deviceSerial = _deviceSerial;
@synthesize isPosting = _isPosting;

- (instancetype)initWithDeviceSerial:(NSString *)deviceSerial
                          chunkQueue:(id<MemfaultChunkQueue>)chunkQueue
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
                                 api:(MemfaultApi *)api
                             backoff:(MFLTBackoff *)backoff
                maxConsecutiveErrorCount:(NSInteger)maxConsecutiveErrorCount {
    self = [super init];
    if (self) {
        _deviceSerial = deviceSerial;
        _chunkQueue = chunkQueue;
        _dispatchQueue = dispatchQueue;
        _api = api;
        _backoff = backoff;
        _maxConsecutiveErrorCount = maxConsecutiveErrorCount;
    }
    return self;
}

- (void)_postAndRestartIfNeeded:(BOOL)shouldRestart {
    NSArray<NSData *> *chunks = nil;

    @synchronized (self) {
        if (!shouldRestart && _stopped) {
            return;
        }

        _stopped = NO;
        if (_isPosting) {
            return;
        }

        chunks = [_chunkQueue peek:kMFLTChunksMaxChunksPerRequest];
        if (chunks.count == 0) {
            return;
        }
        _isPosting = YES;
    }

    @weakify(self);
    [_api postChunks:chunks deviceSerial:_deviceSerial completion:^(NSError * _Nullable error) {
        @strongify(self);
        [self _handlePostCompletion:error chunks:chunks];
    }];
}

- (void)_handlePostCompletion:(NSError * _Nullable)error chunks:(NSArray<NSData *> *)chunks {
    if (error) {
        @synchronized (self) {
            self->_isPosting = NO;
            if (self->_maxConsecutiveErrorCount != 0 && ++self->_consecutiveErrorCount >= self->_maxConsecutiveErrorCount) {
                // When reaching MAX_CONSECUTIVE_ERRORS, start dropping chunks from the queue, even
                // if they have not been sent, as a last resort measure, to avoid accumulating too
                // many chunks on the device:
                [_chunkQueue drop:chunks.count];
            }
        }

        // TODO: report error to error delegate
        const dispatch_time_t backoffTime =
        dispatch_time(DISPATCH_TIME_NOW, [self->_backoff bump] * NSEC_PER_SEC);

        @weakify(self);
        dispatch_after(backoffTime, _dispatchQueue, ^{
            @strongify(self);
            [self _postAndRestartIfNeeded:NO];
        });
        return;
    }

    [_backoff reset];

    @synchronized (self) {
        self->_isPosting = NO;
        self->_consecutiveErrorCount = 0;
        [_chunkQueue drop:chunks.count];
    }
    [self _postAndRestartIfNeeded:NO];
}

- (void)postChunks:(NSArray<NSData *>*)chunks {
    if (![_chunkQueue addChunks:chunks]) {
        // TODO: handle error
        return;
    }
    // TODO: wait a bit to allow more chunks to get added before kicking off a send
    [self _postAndRestartIfNeeded:YES];
}

- (void)postChunks {
    [self _postAndRestartIfNeeded:YES];
}

- (void)stop {
    @synchronized (self) {
        _stopped = YES;
    }
}

@end
