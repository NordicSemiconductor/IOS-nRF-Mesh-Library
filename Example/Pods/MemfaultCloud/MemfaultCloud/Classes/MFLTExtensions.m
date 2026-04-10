//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTExtensions.h"

@implementation NSError (MFLTErrors)
+ (NSError *)mfltErrorWithCode:(NSInteger)code message:(NSString *)messageFormat, ...
{
    va_list args;
    va_start(args, messageFormat);
    NSString *message = [[NSString alloc] initWithFormat:messageFormat arguments:args];
    va_end(args);
    return [NSError errorWithDomain:@"com.memfault" code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}
@end


@implementation NSArray (MFLTNSArray)
- (NSArray *)mfltMap:(_Nonnull id(^)(id _Nonnull obj, NSUInteger idx))mapBlock {
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [output addObject:mapBlock(obj, idx)];
    }];
    return [output copy];
}
- (NSArray *)mfltFilter:(BOOL(^)(id _Nonnull obj, NSUInteger idx))filterBlock {
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (filterBlock(obj, idx)) {
            [output addObject:obj];
        }
    }];
    return [output copy];
}
@end

NSString *MFLTStringFromErrorCode(MemfaultErrorCode error) {
    switch (error) {
        case MemfaultErrorCode_Success:
            return @"Success";
        case MemfaultErrorCode_InvalidArgument:
            return @"Invalid Argument";
        case MemfaultErrorCode_Unsupported:
            return @"Unsupported";
        case MemfaultErrorCode_AuthenticationFailure:
            return @"Authentication Failure";
        case MemfaultErrorCode_InvalidState:
            return @"Invalid State";
        case MemfaultErrorCode_InternalError:
            return @"Internal Error";
        case MemfaultErrorCode_UnexpectedResponse:
            return @"Unexpected Response";
        case MemfaultErrorCode_NotFound:
            return @"Not Found";
        case MemfaultErrorCode_NotImplemented:
            return @"Not Implemented";
        case MemfaultErrorCode_TransportNotAvailable:
            return @"Transport Not Available";
        case MemfaultErrorCode_EndpointNotFound:
            return @"Endpoint Not Found";
        case MemfaultErrorCode_Disconnected:
            return @"Disconnected";
        case MemfaultErrorCode_Timeout:
            return @"Timeout";
        default:
            return @"???";
    }
}

@implementation NSHTTPURLResponse (MFLTNSHTTPURLResponse)
- (NSString *)mfltValueForHTTPHeaderField:(NSString *)caseInsensitiveField
{
    NSDictionary *allFields = [self allHeaderFields];
    NSString *lowercaseField = caseInsensitiveField.lowercaseString;
    for (NSString *field in allFields) {
        if ([field.lowercaseString isEqualToString:lowercaseField]) {
            return allFields[field];
        }
    }
    return nil;
}
@end
