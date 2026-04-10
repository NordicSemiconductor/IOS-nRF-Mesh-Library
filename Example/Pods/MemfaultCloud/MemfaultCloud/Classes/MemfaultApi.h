//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MemfaultCloud.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemfaultApi (Internal)
- (instancetype)initApiWithSession:(NSURLSession *)session
                        projectKey:(NSString *)projectKey
                        apiBaseURL:(NSURL *)apiBaseURL
                    ingressBaseURL:(NSURL *)ingressBaseURL
                     chunksBaseURL:(NSURL *)chunksBaseURL
                chunkQueueProvider:(id<MemfaultChunkQueueProvider>)chunkQueueProvider
    chunksMaxConsecutiveErrorCount:(NSInteger)chunksMaxConsecutiveErrorCount;

- (void)postStatusEvent:(NSString *)eventName deviceInfo:(MemfaultDeviceInfo *_Nullable)deviceInfo userInfo:(NSDictionary *_Nullable)userInfo;

- (NSURLSessionDownloadTask *)downloadFile:(NSURL *)url delegate:(nullable id<NSURLSessionDelegate>)delegate;

- (void)postChunks:(NSArray<NSData *> *_Nonnull)chunks
      deviceSerial:(NSString *_Nonnull)deviceSerial
        completion:(void(^)(NSError *_Nullable error))completion
          boundary:(NSString *_Nullable)boundary;

//! Low-level method to directly post chunks to Memfault.
//! It is recommended to enqueue chunks through the "chunk sender" APIs instead because it
//! handles enqueuing, batching and sequentially posting chunks.
//! @see -chunkSenderWithDeviceSerial: and -[MemfaultChunkSender postChunks:]
//! @note After calling -postChunks:deviceSerial:completion:, it is only allowed to call the method
//! again after the completion block has been called. If the completion block is called with an error,
//! the failed chunks must be sent again before sending the next set of chunks. Otherwise the
//! chunks will arrive out-of-order with data loss as result.
//! @param chunks An array of data objects, one for each chunk. The array must not be empty.
- (void)postChunks:(NSArray<NSData *> *)chunks
      deviceSerial:(NSString *)deviceSerial
        completion:(void(^)(NSError *_Nullable error))block;

- (void)postCoredump:(NSData *)coredumpData;

- (void)postWatchEvent:(id)jsonBlob;

@end

@interface MemfaultApi ()
// For testing:
@property NSTimeInterval minimumRetryDelaySecs;
@property NSTimeInterval minimumDelayBetweenCallsSecs;
@end

NS_ASSUME_NONNULL_END
