//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTApiRequestBuilder.h"
#import "MFLTExtensions.h"
#import "MFLTLogging.h"

@implementation MFLTApiRequestBuilder
{
    NSURL *_apiBaseURL;
    NSString *_projectKey;
}
- (instancetype)initWithApiBaseURL:(NSURL *)apiBaseURL projectKey:(NSString *)projectKey
{
    self = [super init];
    if (self) {
        NSAssert(apiBaseURL, @"apiBaseURL must not be nil");
        NSAssert(projectKey, @"projectKey must not be nil");
        _apiBaseURL = apiBaseURL;
        _projectKey = projectKey;
    }
    return self;

}

- (NSURLRequest *)request:(NSString *)httpMethod
                     body:(id)dataOrJsonSerializable
                  headers:(NSDictionary *)extraHeaders
                queryDict:(NSDictionary<NSString *, NSString *> *)queryDict
               pathFormat:(NSString *)pathFormat
                     args:(va_list)args
{
    NSURLComponents *components = [[NSURLComponents alloc] init];

    if (nil != queryDict) {
        // Sort the keys so the order is deterministic:
        NSArray *sortedKeys = [queryDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
        components.queryItems = [sortedKeys mfltMap:^id _Nonnull(id _Nonnull name, NSUInteger idx) {
            return [NSURLQueryItem queryItemWithName:name value:queryDict[name]];
        }];
    }

    components.path = [[NSString alloc] initWithFormat:pathFormat arguments:args];

    NSURL *url = [components URLRelativeToURL:_apiBaseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:httpMethod];

    NSString *contentType = @"application/json";
    if (dataOrJsonSerializable) {
        NSData *httpBody;
        if ([dataOrJsonSerializable isKindOfClass:[NSData class]]) {
            httpBody = dataOrJsonSerializable;
            // Use generic 'application/octet-stream' when NSData is passed:
            contentType = @"application/octet-stream";
        } else {
            NSError *error = nil;
            httpBody = [NSJSONSerialization dataWithJSONObject:dataOrJsonSerializable options:0 error:&error];
            if (error) {
                MFLTLogError(@"Error building URL with body: %@\n%@", dataOrJsonSerializable, error);
                return nil;
            }
        }
        [request setHTTPBody:httpBody];
    }
    NSMutableDictionary<NSString *, NSString *> *headers = [@{
        @"Memfault-Project-Key": _projectKey,
        @"Accept": @"application/json",
        @"Content-Type": contentType,
    } mutableCopy];
    if (extraHeaders) {
        for (NSString *key in extraHeaders) {
            headers[key] = extraHeaders[key];
        }
    }
    [request setAllHTTPHeaderFields:[headers copy]];
    return request;
}

- (NSURLRequest *)post:(id)dataOrJsonSerializablePostBody
               headers:(nullable NSDictionary *)headers
             queryDict:(nullable NSDictionary<NSString *, NSString *> *)queryDict
            pathFormat:(NSString *)pathFormat, ...
{
    va_list args;
    va_start(args, pathFormat);
    NSURLRequest *request = [self request:@"POST" body:dataOrJsonSerializablePostBody headers:headers queryDict:queryDict pathFormat:pathFormat args:args];
    va_end(args);
    return request;
}

- (NSURLRequest *)getWithQueryDict:(NSDictionary<NSString *, NSString *> *)queryDict
                        pathFormat:(NSString *)pathFormat, ...
{
    va_list args;
    va_start(args, pathFormat);
    NSURLRequest *request = [self request:@"GET" body:nil headers:nil queryDict:queryDict pathFormat:pathFormat args:args];
    va_end(args);
    return request;
}
@end

