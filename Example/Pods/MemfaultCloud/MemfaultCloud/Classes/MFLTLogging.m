//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

#import "MFLTLogging.h"

MemfaultLogLevel gMFLTLogLevel = MemfaultLogLevel_Info;

static const char *MFLTLevelStr(MemfaultLogLevel level) {
    switch (level) {
        case MemfaultLogLevel_Debug:   return "🔨";
        case MemfaultLogLevel_Info:    return "ℹ️";
        case MemfaultLogLevel_Warning: return "⚠️";
        case MemfaultLogLevel_Error:   return "❌";
    }
    return "?";
}

void MFLTLog(MemfaultLogLevel level, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    MFLTLogv(level, format, args);
    va_end(args);
}

void MFLTLogv(MemfaultLogLevel level, NSString *format, va_list args) {
    if (level < gMFLTLogLevel) {
        return;
    }
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    NSLog(@"%s MFLT | %@", MFLTLevelStr(level), msg);
}
