// Interface shared by Lenovo83ALDmic.kext (Lenovo83ALDmicUserClient) and Lenovo83ALDmic.driver (HAL plug-in).
#pragma once

#define kLenovo83ALDmicServiceClass   "Lenovo83ALDmic"
#define kLenovo83ALDmicUserClientType 0          // IOServiceOpen type
#define kLenovo83ALDmicRingMemoryType 0          // IOConnectMapMemory64 type: the 64 KB capture ring (read-only)

enum {
    kLenovo83ALDmicMethodGetInfo     = 0,   // out: version, state bits, rate, channels, ring bytes, frame bytes
    kLenovo83ALDmicMethodStart       = 1,   // out: none. Boots the DSP if needed and starts the DMIC pipeline
    kLenovo83ALDmicMethodStop        = 2,   // out: none
    kLenovo83ALDmicMethodGetPosition = 3,   // out: DMA write position in ring (bytes), mach_absolute_time, generation
    kLenovo83ALDmicMethodCount
};

enum {
    kLenovo83ALDmicStateDspUp     = 1u << 0,
    kLenovo83ALDmicStateStreaming = 1u << 1,
    kLenovo83ALDmicStateService   = 1u << 2,
};

#define kLenovo83ALDmicInterfaceVersion 1
#define kLenovo83ALDmicVersionString    "0.1.0"   // keep in sync with both Info.plist files
// Ring format: S32_LE, two interleaved channels, 48 kHz; ch0/ch1 are the PDM0 stereo pair.
