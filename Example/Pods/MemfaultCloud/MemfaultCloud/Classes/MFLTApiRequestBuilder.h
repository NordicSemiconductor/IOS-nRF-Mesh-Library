//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFLTApiRequestBuilder : NSObject
- (instancetype)initWithApiBaseURL:(NSURL *)apiBaseURL projectKey:(NSString *)projectKey;
- (NSURLRequest *)post:(id)dataOrJsonSerializablePostBody
               headers:(nullable NSDictionary *)headers
             queryDict:(nullable NSDictionary<NSString *, NSString *> *)queryDict
            pathFormat:(NSString *)pathFormat, ... NS_FORMAT_FUNCTION(4,5);
- (NSURLRequest *)getWithQueryDict:(nullable NSDictionary<NSString *, NSString *> *)queryDict
                        pathFormat:(NSString *)pathFormat, ... NS_FORMAT_FUNCTION(2,3);
@end

NS_ASSUME_NONNULL_END
