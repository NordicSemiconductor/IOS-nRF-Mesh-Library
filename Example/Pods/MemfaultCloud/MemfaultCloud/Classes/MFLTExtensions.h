//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import <Foundation/Foundation.h>

#import "MemfaultCloud.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSError (MFLTErrors)
+ (NSError *)mfltErrorWithCode:(NSInteger)code message:(NSString *)messageFormat, ... NS_FORMAT_FUNCTION(2,3);
@end


@interface NSArray (MFLTNSArray)
- (NSArray *)mfltMap:(_Nonnull id(^)(id _Nonnull obj, NSUInteger idx))mapBlock;
- (NSArray *)mfltFilter:(BOOL(^)(id _Nonnull obj, NSUInteger idx))filterBlock;
@end

NSString *MFLTStringFromErrorCode(MemfaultErrorCode error);

@interface NSHTTPURLResponse (MFLTNSHTTPURLResponse)
// NOTE: -valueForHTTPHeaderField is only added in iOS SDK 13
- (NSString *)mfltValueForHTTPHeaderField:(NSString *)caseInsensitiveField;
@end

NS_ASSUME_NONNULL_END
