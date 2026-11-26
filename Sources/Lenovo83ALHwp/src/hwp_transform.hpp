// Pure request transformation, shared by the kext and host-side unit tests.
#pragma once
#include <stdint.h>

static inline bool l83TransformRequest(uint64_t oldRequest, uint32_t type,
                                       uint32_t highest, uint64_t &newRequest) {
    if (oldRequest & (1ULL << 42)) return false; // package control
    if (type != 0x40 || highest != 60) return false; // i5-13500H P-core only

    const uint32_t maxPerf = (uint32_t)(oldRequest >> 8) & 0xff;
    const uint32_t desired = (uint32_t)(oldRequest >> 16) & 0xff;
    const uint32_t epp = (uint32_t)(oldRequest >> 24) & 0xff;
    if (maxPerf != 47 || desired > 47 || epp != 0x80) return false; // known full-range XCPM request only

    const uint32_t newDesired = desired ? (desired * highest + maxPerf / 2) / maxPerf : 0;
    newRequest = oldRequest & ~0x00ffff00ULL;
    newRequest |= (uint64_t)highest << 8;
    newRequest |= (uint64_t)(newDesired > highest ? highest : newDesired) << 16;
    newRequest &= ~0xff000000ULL; // maximum performance preference: EPP 0x80 -> 0x00

    // Minimum, activity window and every bit outside max/desired/EPP stay identical.
    if ((newRequest & ~0xffffff00ULL) != (oldRequest & ~0xffffff00ULL)) return false;
    return newRequest != oldRequest;
}
