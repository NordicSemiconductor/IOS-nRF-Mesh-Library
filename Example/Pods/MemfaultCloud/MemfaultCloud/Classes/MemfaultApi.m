//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MemfaultApi.h"

#import "MemfaultCloud.h"
#import "MFLTApiRequestBuilder.h"
#import "MFLTBackoff.h"
#import "MFLTChunkSender.h"
#import "MFLTChunkSenderRegistry.h"
#import "MFLTDeviceInfo.h"
#import "MFLTExtensions.h"
#import "MFLTLogging.h"
#import "MFLTTemporaryChunkQueue.h"

NSString *const kMFLTProjectKey = @"apiKey";
NSString *const kMFLTApiBaseURL = @"apiBaseURL";
NSString *const kMFLTApiIngressBaseURL = @"ingressBaseURL";
NSString *const kMFLTApiChunksBaseURL = @"chunksBaseURL";
NSString *const kMFLTApiUrlSession = @"apiUrlSession";

NSString *const MFLTDefaultApiBaseURL = @"https://api.memfault.com";
NSString *const MFLTDefaultApiIngressBaseURL = @"https://ingress.memfault.com";
NSString *const MFLTDefaultApiChunksBaseURL = @"https://chunks.memfault.com";

NSString *const kMFLTChunkQueueProvider = @"chunkQueueProvider";
NSString *const kMFLTChunksMaxConsecutiveErrorCount = @"chunksMaxConsecutiveErrorCount";

#define kMFLTChunksMinimumRetryDelaySecs (5.0 * 60.0)
#define kMFLTChunksMinimumDelayBetweenCallsSecs (0.5)
#define kMFLTChunksBackoffFactor (2)
#define kMFLTChunksMinimumBackoffSecs (1.0)
#define kMFLTChunksMaximumBackoffSecs (120.0)
#define kMFLTMaxConsecutiveErrors (100)

static MemfaultApi *gMemfaultSharedApi;

@interface MemfaultApi (ChunkSenderFactory) <MFLTChunkSenderFactory>
@end

@implementation MemfaultApi
{
    NSURLSession *_session;
    MFLTApiRequestBuilder *_requestBuilder;
    // Use with API's that push data into Memfault, such as Events and Coredumps:
    MFLTApiRequestBuilder *_ingressRequestBuilder;
    MFLTApiRequestBuilder *_chunksRequestBuilder;
    MFLTChunkSenderRegistry *_chunkSenderRegistry;
    id<MemfaultChunkQueueProvider> _chunkQueueProvider;
    dispatch_time_t _chunksLastTime;
    dispatch_queue_t _chunksDispatchQueue;
    NSInteger _chunksMaxConsecutiveErrorCount;

    // For testing
    NSTimeInterval _minimumRetryDelaySecs;
    NSTimeInterval _minimumDelayBetweenCallsSecs;
}
@synthesize minimumRetryDelaySecs = _minimumRetryDelaySecs;
@synthesize minimumDelayBetweenCallsSecs = _minimumDelayBetweenCallsSecs;

+ (BOOL)_setSharedApi:(MemfaultApi *)api {
    static dispatch_once_t onceToken;
    __block BOOL success = NO;
    dispatch_once(&onceToken, ^{
        gMemfaultSharedApi = api;
        success = YES;
    });
    return success;
}

+ (void)configureSharedApi:(NSDictionary *)configuration {
    MemfaultApi *api = [self apiWithConfiguration:configuration];
    BOOL success = [self _setSharedApi: api];
    NSAssert(success, @"+configureSharedApi: should only be called once!");
    (void)success;
}

+ (MemfaultApi *)sharedApi {
    NSAssert(gMemfaultSharedApi, @"+configureSharedApi: must be called before using sharedApi");
    return gMemfaultSharedApi;
}

- (instancetype)initApiWithSession:(NSURLSession *)session projectKey:(NSString *)projectKey
                        apiBaseURL:(NSURL *)apiBaseURL ingressBaseURL:(NSURL *)ingressBaseURL
                     chunksBaseURL:(NSURL *)chunksBaseURL
                chunkQueueProvider:(id<MemfaultChunkQueueProvider>)chunkQueueProvider
    chunksMaxConsecutiveErrorCount:(NSInteger)chunksMaxConsecutiveErrorCount
{
    self = [super init];
    if (self) {
        NSAssert(session && projectKey && apiBaseURL, @"Invalid parameters");
        _session = session;
        _requestBuilder = [[MFLTApiRequestBuilder alloc] initWithApiBaseURL:apiBaseURL projectKey:projectKey];
        _ingressRequestBuilder = [[MFLTApiRequestBuilder alloc] initWithApiBaseURL:ingressBaseURL projectKey:projectKey];
        _chunksRequestBuilder = [[MFLTApiRequestBuilder alloc] initWithApiBaseURL:chunksBaseURL projectKey:projectKey];
        _chunkQueueProvider = chunkQueueProvider;
        _chunksDispatchQueue = dispatch_queue_create("com.memfault.chunks",
                                                     dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                                                                             QOS_CLASS_BACKGROUND, 0));
        _chunksMaxConsecutiveErrorCount = chunksMaxConsecutiveErrorCount;
        _chunkSenderRegistry = [MFLTChunkSenderRegistry createRegistry:self];
        _minimumRetryDelaySecs = kMFLTChunksMinimumRetryDelaySecs;
        _minimumDelayBetweenCallsSecs = kMFLTChunksMinimumDelayBetweenCallsSecs;
    }
    return self;
}

+ (instancetype)apiWithConfiguration:(NSDictionary *)configuration
{
    NSString *projectKey = configuration[kMFLTProjectKey];
    NSAssert(projectKey, @"Project key missing! Use the kMFLTProjectKey in the configuration to set the project key.");

    NSString *apiBaseURLString = configuration[kMFLTApiBaseURL];
    if (apiBaseURLString == nil) {
        apiBaseURLString = MFLTDefaultApiBaseURL;
    }
    NSURL *apiBaseURL = [NSURL URLWithString:apiBaseURLString];
    NSAssert(apiBaseURL, @"API base URL missing! Use the MFLTDefaultApiBaseURL in the configuration to set the API base URL.");
    MFLTLogDebug(@"Using %@ as API root", apiBaseURLString);

    NSString *ingressBaseURLString = configuration[kMFLTApiIngressBaseURL];
    if (ingressBaseURLString == nil) {
        ingressBaseURLString = MFLTDefaultApiIngressBaseURL;
    }
    NSURL *ingressBaseURL = [NSURL URLWithString:ingressBaseURLString];
    NSAssert(ingressBaseURL, @"Ingress API base URL missing! Use the kMFLTApiIngressBaseURL in the configuration to set the Ingress API base URL.");
    MFLTLogDebug(@"Using %@ as Ingress API root", ingressBaseURLString);

    NSString *chunksBaseURLString = configuration[kMFLTApiChunksBaseURL];
    if (chunksBaseURLString == nil) {
        chunksBaseURLString = MFLTDefaultApiChunksBaseURL;
    }
    NSURL *chunksBaseURL = [NSURL URLWithString:chunksBaseURLString];
    NSAssert(chunksBaseURL, @"Chunks API base URL missing! Use the kMFLTApiChunksBaseURL in the configuration to set the Chunks API base URL.");
    MFLTLogDebug(@"Using %@ as Chunks API root", chunksBaseURLString);

    NSObject<MemfaultChunkQueueProvider> *chunkQueueProvider = configuration[kMFLTChunkQueueProvider];
    if (chunkQueueProvider) {
        NSAssert([chunkQueueProvider conformsToProtocol:NSProtocolFromString(@"MemfaultChunkQueueProvider")],
                 @"The object with key kMFLTChunkQueueProvider must conform to the MemfaultChunkQueueProvider protocol.");
    } else {
        chunkQueueProvider = [[MFLTTemporaryChunkQueueProvider alloc] init];
    }
    MFLTLogDebug(@"Using chunk queue provider: %@", chunkQueueProvider);

    NSNumber *chunksMaxConsecutiveErrorCount = configuration[kMFLTChunksMaxConsecutiveErrorCount];
    if (!chunksMaxConsecutiveErrorCount) {
        chunksMaxConsecutiveErrorCount = @(kMFLTMaxConsecutiveErrors);
    }
    MFLTLogDebug(@"Using chunksMaxConsecutiveErrorCount: %@", chunksMaxConsecutiveErrorCount);

    NSURLSession *session = configuration[kMFLTApiUrlSession];
    if (session == nil) {
        session = [NSURLSession sharedSession];
    }

    return [[MemfaultApi alloc] initApiWithSession:session
                                        projectKey:projectKey
                                        apiBaseURL:apiBaseURL
                                    ingressBaseURL:ingressBaseURL
                                     chunksBaseURL:chunksBaseURL
                                chunkQueueProvider:chunkQueueProvider
                    chunksMaxConsecutiveErrorCount:[chunksMaxConsecutiveErrorCount integerValue]];
}

- (void)_doRequest:(NSURLRequest *)request completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))block
{
    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        MFLTLogError(@"Request failed: %@\n%@", request, error);
                                                    } else {
                                                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                        MFLTLogDebug(@"Request success: %@\n%@", request, httpResponse);
                                                    }
                                                    block(data, response, error);
                                                }];
    [dataTask resume];
}

- (void)postCoredump:(NSData *)coredumpData
{
    NSURLRequest *request = [_ingressRequestBuilder post:coredumpData headers:nil queryDict:nil pathFormat:@"/api/v0/upload/coredump"];

    [self _doRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if (httpResponse.statusCode != 202) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            MFLTLogDebug(@"Post error: %@", dict);
        }
    }];
}

- (void)postWatchEvent:(id)jsonBlob
{
    NSURLRequest *request = [_ingressRequestBuilder post:jsonBlob headers:nil queryDict:nil pathFormat:@"/api/v0/events"];

    [self _doRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if (httpResponse.statusCode != 202) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            MFLTLogDebug(@"Post error: %@", dict);
        }
    }];
}

- (void)postStatusEvent:(NSString *)eventName deviceInfo:(MemfaultDeviceInfo *_Nullable)deviceInfo userInfo:(NSDictionary *_Nullable)userInfo
{
    if (deviceInfo == nil) {
        return; // We can't post event info if we don't know where it came from
    }

    NSDictionary *info = @{ @"type": eventName,
                            @"hardware_version": deviceInfo.hardwareVersion,
                            @"device_serial": deviceInfo.deviceSerial,
                            };
    NSMutableDictionary *mutableDict = [info mutableCopy];

    // MFLTBleDeviceInfoQuery returns a MemfaultDeviceInfo with an emtpy string:
    if (deviceInfo.softwareType.length > 0) {
        mutableDict[@"sdk_version"] = @"0.5.0";
        mutableDict[@"software_version"] = deviceInfo.softwareVersion;
        mutableDict[@"software_type"] = deviceInfo.softwareType;
    } else {
        mutableDict[@"sdk_version"] = @"0.1.0";
        mutableDict[@"fw_version"] = deviceInfo.softwareVersion;
    }

    if (userInfo != nil) {
        [mutableDict setObject:userInfo forKey:@"user_info"];
    }

    NSArray *parameters = @[ mutableDict ];

    NSURLRequest *request = [_ingressRequestBuilder post:parameters headers:nil queryDict:nil pathFormat:@"/api/v0/events"];
    [self _doRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            MFLTLogDebug(@"%@", error);
        }
    }];
}

- (NSURLSessionDownloadTask *)downloadFile:(NSURL *)url delegate:(nullable id<NSURLSessionDownloadDelegate>)delegate
{
    NSURLSession *downloadSession = [NSURLSession sessionWithConfiguration:_session.configuration delegate:delegate delegateQueue:_session.delegateQueue];
    NSURLSessionDownloadTask *dataTask = [downloadSession downloadTaskWithURL:url];
    [dataTask resume];
    return dataTask;
}

- (NSString *)_findErrorReponseMessage:(NSData *)responseData statusCode:(NSUInteger)statusCode
{
    NSError *error = nil;
    if (responseData) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
        if ([dict isKindOfClass:[NSDictionary class]] && !error) {
            NSDictionary<NSString *, NSString *> *errorDict = dict[@"error"];
            if (errorDict && [errorDict isKindOfClass:[NSDictionary class]]) {
                NSString *errorMsg = errorDict[@"message"];
                if (errorMsg && [errorMsg isKindOfClass:[NSString class]]) {
                    return errorMsg;
                }
            }
        }
    }
    return [NSString stringWithFormat:@"HTTP Error %@", @(statusCode)];
}

- (void)getLatestReleaseForDeviceInfo:(MemfaultDeviceInfo *)deviceInfo
                           completion:(void(^)(MemfaultOtaPackage *_Nullable latestRelease, BOOL isDeviceUpToDate, NSError *_Nullable error))block
{
    NSAssert(deviceInfo, @"deviceInfo must not be nil");
    NSAssert(deviceInfo.hardwareVersion, @"deviceInfo.hardwareVersion must not be nil");
    NSAssert(deviceInfo.softwareVersion, @"deviceInfo.softwareVersion must not be nil");
    NSAssert(deviceInfo.softwareType, @"deviceInfo.softwareType must not be nil");
    NSAssert(deviceInfo.deviceSerial, @"deviceInfo.deviceSerial must not be nil");

    if (nil == block) {
        block = ^(MemfaultOtaPackage *latestRelease, BOOL isDeviceUpToDate,
                  NSError *error) {
        };
    }

    NSMutableDictionary<NSString *, NSString *> *query = [@{ @"hardware_version": deviceInfo.hardwareVersion,
                                                             @"current_version": deviceInfo.softwareVersion,
                                                             @"device_serial": deviceInfo.deviceSerial,
                                                          } mutableCopy];
    // MFLTBleDeviceInfoQuery returns a MemfaultDeviceInfo with an emtpy string:
    if (deviceInfo.softwareType.length > 0) {
        query[@"software_type"] = deviceInfo.softwareType;
    }
    NSURLRequest *request = [_requestBuilder getWithQueryDict:query pathFormat:@"/api/v0/releases/latest"];
    [self _doRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            block(nil, NO, error);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if (httpResponse.statusCode == 204) {
            block(nil, YES, error);
            return;
        }

        if (httpResponse.statusCode != 200) {
            NSString *errorMsg = [self _findErrorReponseMessage:data statusCode:httpResponse.statusCode];
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"%@", errorMsg]);
            return;
        }
    
        if ([data length] == 0) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"Response was empty."]);
            return;
        }

        // TODO: clean this up and put in a response parsing class
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (error) {
            block(nil, NO, error);
            return;
        }

        if (NO == [dict isKindOfClass:[NSDictionary class]]) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"Expected response body to be an object."]);
            return;
        }

        NSArray<NSDictionary<NSString *, NSString *> *> *artifacts = dict[@"artifacts"];
        if (artifacts == nil || NO == [artifacts isKindOfClass:[NSArray class]]) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"Expected artifacts to be an array."]);
            return;
        }
        if (artifacts.count == 0) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_NotFound message:@"No releases found!"]);
            return;
        }
        NSDictionary<NSString *, NSString *> *latest = artifacts[0];
        if (NO == [latest isKindOfClass:[NSDictionary class]]) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"Expected artifact to be an object."]);
            return;
        }

        NSString *urlString = latest[@"url"];
        if (urlString == nil || NO == [urlString isKindOfClass:[NSString class]]) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"Expected url to be a string."]);
            return;
        }
        NSString *version = dict[@"version"];
        if (version == nil || NO == [version isKindOfClass:[NSString class]]) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"Expected version to be a string."]);
            return;
        }
        NSString *notes = dict[@"notes"];
        if (notes == nil || NO == [notes isKindOfClass:[NSString class]]) {
            block(nil, NO, [NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"Expected notes to be a string."]);
            return;
        }
        MemfaultOtaPackage *latestRelease = [[MemfaultOtaPackage alloc] init];
        latestRelease.location = [NSURL URLWithString:urlString];

        // TODO: parse more of the metadata
        latestRelease.releaseNotes = notes;
        latestRelease.softwareVersion = version;
        block(latestRelease, NO, nil);
    }];
}

- (NSData *)_buildMultipartMixedBody:(NSArray<NSData *> *_Nonnull)parts boundary:(NSString *)boundary
{
    NSMutableData *body = [NSMutableData data];
    for (NSData *part in parts) {
        [body appendData: [[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Length: %@", @(part.length)] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData: [@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData: part];
        [body appendData: [[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return [body copy];
}

- (void)postChunks:(NSArray<NSData *> *_Nonnull)chunks
      deviceSerial:(NSString *_Nonnull)deviceSerial
        completion:(void(^)(NSError *_Nullable error))completion
          boundary:(NSString *_Nullable)boundary
{
    NSAssert(chunks, @"chunks must not be nil");
    NSAssert(chunks.count > 0, @"chunks array cannot be empty");
    for (NSData *chunk in chunks) {
        (void)chunk;
        NSAssert(chunk && [chunk isKindOfClass:[NSData class]], @"each chunk must be an instance inheriting from NSData");
    }
    NSAssert(deviceSerial && [deviceSerial isKindOfClass:[NSString class]], @"deviceSerial must be an instance inheriting from NSString");

    BOOL isMultipart = (chunks.count > 1);
    boundary = boundary ?: [NSString stringWithFormat:@"--mflt-%@", [NSUUID UUID]];
    NSData *bodyData = isMultipart ? [self _buildMultipartMixedBody:chunks boundary:boundary] : chunks[0];
    NSDictionary *headers = @{
        @"Content-Type": isMultipart ? [NSString stringWithFormat:@"multipart/mixed; boundary=\"%@\"", boundary] : @"application/octet-stream"
    };
    NSURLRequest *request = [_chunksRequestBuilder post:bodyData headers:headers queryDict:nil pathFormat:@"/api/v0/chunks/%@", deviceSerial];

    __weak MemfaultApi* weakSelf = self;

    __auto_type callCompletionBlock = ^(NSError *error){
        MemfaultApi *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        completion(error);
    };

    __auto_type bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    __block void(^schedulePost)(NSTimeInterval delay) = nil;
    __auto_type postBlock = ^{
        [weakSelf _doRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            MemfaultApi *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if (error) {
                callCompletionBlock(error);
                return;
            }
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            if (httpResponse.statusCode == 503 || httpResponse.statusCode == 429) {
                NSTimeInterval retryDelaySeconds = self->_minimumRetryDelaySecs;
                NSString *retryAfterString = [httpResponse mfltValueForHTTPHeaderField:@"retry-after"];
                if (retryAfterString) {
                    [[NSScanner scannerWithString:retryAfterString] scanDouble:&retryDelaySeconds];
                    retryDelaySeconds = MAX(self->_minimumRetryDelaySecs, retryDelaySeconds);
                }
                MFLTLogWarning(@"Chunk service unavailable, will retry again after %d seconds", (int)retryDelaySeconds);
                schedulePost(retryDelaySeconds);
                return;
            }
            if (httpResponse.statusCode >= 300) {
                NSString *errorMsg = [strongSelf _findErrorReponseMessage:data statusCode:httpResponse.statusCode];
                MFLTLogError(@"Chunk upload request failed: %@", errorMsg);

                callCompletionBlock([NSError mfltErrorWithCode:MemfaultErrorCode_UnexpectedResponse message:@"%@", errorMsg]);
                return;
            }
            callCompletionBlock(nil);
        }];
    };

    schedulePost = ^(NSTimeInterval delaySecs) {
        MemfaultApi *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        // Keep track of last time the /chunks endpoint was called and space out the calls, to avoid hammering the API:
        dispatch_time_t earliestTime = dispatch_time(strongSelf->_chunksLastTime, self->_minimumDelayBetweenCallsSecs * NSEC_PER_SEC);
        dispatch_time_t requestedTime = dispatch_time(DISPATCH_TIME_NOW, delaySecs * NSEC_PER_SEC);
        strongSelf->_chunksLastTime = MAX(earliestTime, requestedTime);
        dispatch_after(strongSelf->_chunksLastTime, bgQueue, postBlock);
    };

    schedulePost(0);
}

- (void)postChunks:(NSArray<NSData *> *_Nonnull)chunks
      deviceSerial:(NSString *_Nonnull)deviceSerial
        completion:(void(^)(NSError *_Nullable error))completion
{
    [self postChunks:chunks deviceSerial:deviceSerial completion:completion boundary:nil];
}

- (id<MemfaultChunkSender>)chunkSenderWithDeviceSerial:(NSString *_Nonnull)deviceSerial
{
    return [_chunkSenderRegistry senderWithDeviceSerial:deviceSerial];
}

@end


@implementation MemfaultApi (ChunkSenderFactory)

- (id<MemfaultChunkSender>)createSenderWithDeviceSerial:(NSString *)deviceSerial
{
    id<MemfaultChunkQueue> chunkQueue = [_chunkQueueProvider queueWithDeviceSerial:deviceSerial];
    NSAssert(chunkQueue, @"-queueWithDeviceSerial: must not return nil!");
    MFLTBackoff *backoff = [[MFLTBackoff alloc] initWithBackoffFactor:kMFLTChunksBackoffFactor
                                                      initialDuration:kMFLTChunksMinimumBackoffSecs
                                                      maximumDuration:kMFLTChunksMaximumBackoffSecs];
    return [[MFLTChunkSender alloc] initWithDeviceSerial:deviceSerial
                                              chunkQueue:chunkQueue
                                           dispatchQueue:_chunksDispatchQueue
                                                     api:self
                                                   backoff:backoff
                                maxConsecutiveErrorCount:_chunksMaxConsecutiveErrorCount];
}

@end
