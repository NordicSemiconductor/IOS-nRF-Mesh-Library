//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

// Based on https://github.com/jspahrsummers/libextobjc/blob/master/extobjc/EXTScope.h
// Copyright (C) 2012 Justin Spahr-Summers.
// Released under the MIT license.

#define weakify(var) \
    mflt_keywordify \
    __weak typeof(var) _weak_##var = var;

#define strongify(var) \
    mflt_keywordify \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    __strong typeof(var) var = _weak_##var; \
    _Pragma("clang diagnostic pop")

// Details about the choice of backing keyword:
//
// The use of @try/@catch/@finally can cause the compiler to suppress
// return-type warnings.
// The use of @autoreleasepool {} is not optimized away by the compiler,
// resulting in superfluous creation of autorelease pools.
//
// Since neither option is perfect, and with no other alternatives, the
// compromise is to use @autorelease in DEBUG builds to maintain compiler
// analysis, and to use @try/@catch otherwise to avoid insertion of unnecessary
// autorelease pools.
#if defined(DEBUG) && !defined(NDEBUG)
#  define mflt_keywordify autoreleasepool {}
#else
#  define mflt_keywordify try {} @catch (...) {}
#endif
