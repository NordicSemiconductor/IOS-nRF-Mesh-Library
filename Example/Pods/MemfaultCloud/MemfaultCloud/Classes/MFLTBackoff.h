//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFLTBackoff : NSObject
- (instancetype)initWithBackoffFactor:(double)factor
                      initialDuration:(NSTimeInterval)initialDuration
                      maximumDuration:(NSTimeInterval)maximumDuration;
- (NSTimeInterval)bump;
- (void)reset;
@end

NS_ASSUME_NONNULL_END
