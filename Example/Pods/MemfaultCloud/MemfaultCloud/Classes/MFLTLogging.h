//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import <Foundation/Foundation.h>
#import "MemfaultCloud.h"

NS_ASSUME_NONNULL_BEGIN

void MFLTLog(MemfaultLogLevel level, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
void MFLTLogv(MemfaultLogLevel level, NSString *format, va_list args) NS_FORMAT_FUNCTION(2,0);

#define MFLTLogDebug(format, ...) \
    do { MFLTLog(MemfaultLogLevel_Debug, format, ##__VA_ARGS__); } while(0)
#define MFLTLogInfo(format, ...) \
    do { MFLTLog(MemfaultLogLevel_Info, format, ##__VA_ARGS__); } while(0)
#define MFLTLogWarning(format, ...) \
    do { MFLTLog(MemfaultLogLevel_Warning, format, ##__VA_ARGS__); } while(0)
#define MFLTLogError(format, ...) \
    do { MFLTLog(MemfaultLogLevel_Error, format, ##__VA_ARGS__); } while(0)

NS_ASSUME_NONNULL_END
