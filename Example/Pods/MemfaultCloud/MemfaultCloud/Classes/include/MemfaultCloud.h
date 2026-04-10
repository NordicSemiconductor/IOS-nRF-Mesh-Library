//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@class MemfaultDeviceInfo;
@class MemfaultOtaPackage;
@protocol MemfaultChunkQueue;
@protocol MemfaultChunkQueueProvider;
@protocol MemfaultChunkSender;

typedef NS_ENUM(NSUInteger, MemfaultLogLevel);

//! Configuration dictionary key to specify your Memfault Project Key.
extern NSString *const kMFLTProjectKey;

//! Configuration dictionary key to specify Memfault API url to use
//! (Not needed by default)
extern NSString *const kMFLTApiBaseURL;

//! Configuration dictionary key to specify Memfault Ingress API url to use
//! (Not needed by default)
extern NSString *const kMFLTApiIngressBaseURL;

//! Configuration dictionary key to specify Memfault Chunks API url to use
//! (Not needed by default)
extern NSString *const kMFLTApiChunksBaseURL;

//! Configuration dictionary key to specify NSURLSession to use.
//! (sharedSession is used by default)
extern NSString *const kMFLTApiUrlSession;

//! Configuration dictionary key to specify a custom queue provider.
//! By default, a memory-backed queuing implementation is used. A custom
//! implementation can also be provided by implementing the
//! MemfaultChunkQueueProvider interface.
//! @see MemfaultChunkQueueProvider
extern NSString *const kMFLTChunkQueueProvider;

//! Configuration dictionary key to specify the maximum number of consecutive
//! upload errors before dropping chunks. Defaults to 100 when not specified.
//! When implementing a disk-backed custom queue, we recommend setting this
//! to 0 to never drop chunks when consecutive errors occur.
//! @see MemfaultChunkSender
extern NSString *const kMFLTChunksMaxConsecutiveErrorCount;


@interface MemfaultApi : NSObject
//! Configures the sharedApi singleton instance. See kMFLT... constants for
//! possible configuration options.
//! @note You must only call method once. Calling it a second time will throw an error.
+ (void)configureSharedApi:(NSDictionary *)configuration;

//! The shared singleton instance.
//! @note You must call +configuredSharedApi: first before calling this method or else an error will be thrown.
@property(class, readonly) MemfaultApi *sharedApi;

//! Creates a new MemfaultApi instance with given configuration. See kMFLT... constants for
//! possible configuration options.
//! @note You should only create one instance in the entire application.
//! @see +sharedApi for a convenience singleton API.
+ (instancetype)apiWithConfiguration:(NSDictionary *)configuration;

//! Get the latest OTA package release for a given device.
//! @param deviceInfo Device for which to retrieve the latest release.
//! @param block Completion block that will be called when the request has completed.
- (void)getLatestReleaseForDeviceInfo:(MemfaultDeviceInfo *)deviceInfo
                           completion:(nullable void(^)(MemfaultOtaPackage *_Nullable latestRelease, BOOL isDeviceUpToDate,
                                                        NSError *_Nullable error))block;

//! Gets the chunk sender for the given device serial.
- (id<MemfaultChunkSender>)chunkSenderWithDeviceSerial:(NSString *_Nonnull)deviceSerial;

@end


//! Interface of an object that sequentially uploads enqueued chunks
//! from a given device to Memfault for processing.
@protocol MemfaultChunkSender
//! The serial number of the device for which this sender sends chunks.
@property (readonly) NSString *deviceSerial;

//! Enqueue the chunks and and attempt to upload all enqueued chunks for the given device.
//! The chunks are to be obtained by the device through the Memfault Firmware SDK
//! (https://github.com/memfault/memfault-firmware-sdk)
//! It provides a streamlined way of getting arbitrary data (coredumps, events,
//! heartbeats, etc.) out of devices and into Memfault.
//! Check out the conceptual documentation (https://mflt.io/2MGMoIl) to learn more.
//! @param chunks An array of data objects, one for each chunk. The array must not be empty.
- (void)postChunks:(NSArray<NSData *>*)chunks;

//! Attempt to upload all enqueued chunks for the given device.
- (void)postChunks;

//! Stop sending chunks for this device.
//! This can be used to pause sending chunks. To resume sending, call -postChunks.
- (void)stop;
@end


//! Interface of a chunk queue.
//! @see MemfaultChunkQueueProvider and kMFLTChunkQueueProvider
@protocol MemfaultChunkQueue
//! Number of chunks in the queue.
@property (readonly) NSUInteger count;

//! Enqueue the chunks; return NO if not successful.
- (BOOL)addChunks:(NSArray<NSData *>*)chunks;

//! Return a list with at most the first `count` items from the head of the queue.
- (NSArray<NSData *>*)peek:(NSUInteger)count;

//! Remove at most the first `count` items from head of the queue.
- (void)drop:(NSUInteger)count;
@end


//! Interface of an object that provides chunk queues.
//! @see kMFLTChunkQueueProvider
@protocol MemfaultChunkQueueProvider
//! Gets the queue for a given device serial.
- (id<MemfaultChunkQueue>)queueWithDeviceSerial:(NSString *)deviceSerial;
@end


//! Information describing a device
@interface MemfaultDeviceInfo : NSObject
+ (instancetype)infoWithDeviceSerial:(NSString *)deviceSerial
                     hardwareVersion:(NSString *)hardwareVersion
                     softwareVersion:(NSString *)softwareVersion
                        softwareType:(NSString *)softwareType;
@property (readonly) NSString *softwareVersion;
@property (readonly) NSString *softwareType;
@property (readonly) NSString *deviceSerial;
@property (readonly) NSString *hardwareVersion;
@end


//! An OTA package.
//! @see MemfaultBluetoothDevice.checkForUpdate
@interface MemfaultOtaPackage : NSObject
@property NSURL *location;
@property NSString *releaseNotes;
@property NSString *softwareVersion;
@end

//! Global logging level for the Memfault iOS SDK as a whole.
extern MemfaultLogLevel gMFLTLogLevel;

typedef NS_ENUM(NSUInteger, MemfaultLogLevel) {
    MemfaultLogLevel_Debug,
    MemfaultLogLevel_Info,
    MemfaultLogLevel_Warning,
    MemfaultLogLevel_Error,
};

typedef NS_ENUM(NSUInteger, MemfaultErrorCode) {
    MemfaultErrorCode_Success = 0,
    MemfaultErrorCode_InvalidArgument = 1,
    MemfaultErrorCode_InternalError = 2,
    MemfaultErrorCode_InvalidState = 3,
    MemfaultErrorCode_Unsupported = 10,
    MemfaultErrorCode_UnexpectedResponse = 11,
    MemfaultErrorCode_NotFound = 12,
    MemfaultErrorCode_NotImplemented = 13,
    MemfaultErrorCode_TransportNotAvailable = 14,
    MemfaultErrorCode_EndpointNotFound = 15,
    MemfaultErrorCode_Disconnected = 16,
    MemfaultErrorCode_Timeout = 17,
    MemfaultErrorCode_AuthenticationFailure = 18,
    MemfaultErrorCode_PlatformSpecificBase = 100000,
};


NS_ASSUME_NONNULL_END
