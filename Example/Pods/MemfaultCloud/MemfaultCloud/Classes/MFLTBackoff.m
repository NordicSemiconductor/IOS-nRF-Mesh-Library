//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTBackoff.h"

@implementation MFLTBackoff {
    double _factor;
    NSTimeInterval _initialDuration;
    NSTimeInterval _currentDuration;
    NSTimeInterval _maximumDuration;
}

- (instancetype)initWithBackoffFactor:(double)factor
                      initialDuration:(NSTimeInterval)initialDuration
                      maximumDuration:(NSTimeInterval)maximumDuration
{
    self = [super init];
    if (self) {
        NSParameterAssert(factor > 1);
        NSParameterAssert(initialDuration < maximumDuration);
        _factor = factor;
        _initialDuration = _currentDuration = initialDuration;
        _maximumDuration = maximumDuration;
    }
    return self;
}

- (NSTimeInterval)bump {
    const NSTimeInterval currentDuration = _currentDuration;
    _currentDuration = MIN(_maximumDuration, _factor * _currentDuration);
    return currentDuration;
}

- (void)reset {
    _currentDuration = _initialDuration;
}

@end
