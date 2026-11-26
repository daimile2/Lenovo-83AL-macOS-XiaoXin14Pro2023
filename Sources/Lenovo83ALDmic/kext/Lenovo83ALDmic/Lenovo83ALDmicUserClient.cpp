#include "Lenovo83ALDmicUserClient.hpp"
#include "Lenovo83ALDmicShared.h"
#include <IOKit/IOLib.h>
#include <sys/kauth.h>

#define super IOUserClient
OSDefineMetaClassAndStructors(Lenovo83ALDmicUserClient, IOUserClient)

const IOExternalMethodDispatch Lenovo83ALDmicUserClient::sMethods[kLenovo83ALDmicMethodCount] = {
    // function       scalarIn structIn scalarOut structOut
    { &Lenovo83ALDmicUserClient::sGetInfo,     0, 0, 6, 0 },
    { &Lenovo83ALDmicUserClient::sStart,       0, 0, 0, 0 },
    { &Lenovo83ALDmicUserClient::sStop,        0, 0, 0, 0 },
    { &Lenovo83ALDmicUserClient::sGetPosition, 0, 0, 3, 0 },
};

bool Lenovo83ALDmicUserClient::initWithTask(task_t owningTask, void *securityToken, UInt32 type, OSDictionary *properties) {
    if (type != kLenovo83ALDmicUserClientType) return false;
    bool privileged = IOUserClient::clientHasPrivilege(owningTask, kIOClientPrivilegeLocalUser) == kIOReturnSuccess ||
                      IOUserClient::clientHasPrivilege(owningTask, kIOClientPrivilegeAdministrator) == kIOReturnSuccess;
    if (!privileged && kauth_getuid() != 202 && kauth_getuid() != 0) return false;
    if (!super::initWithTask(owningTask, securityToken, type, properties)) return false;
    task = owningTask;
    return true;
}

bool Lenovo83ALDmicUserClient::start(IOService *provider) {
    owner = OSDynamicCast(Lenovo83ALDmic, provider);
    if (!owner || !super::start(provider)) return false;
    owner->retain();
    return true;
}

void Lenovo83ALDmicUserClient::stop(IOService *provider) {
    if (started && owner) { owner->clientStop(); started = false; }
    super::stop(provider);
}

IOReturn Lenovo83ALDmicUserClient::clientClose() {
    if (started && owner) { owner->clientStop(); started = false; }
    OSSafeReleaseNULL(owner);
    if (!isInactive()) terminate();
    return kIOReturnSuccess;
}

void Lenovo83ALDmicUserClient::free() {
    OSSafeReleaseNULL(owner);
    super::free();
}

IOReturn Lenovo83ALDmicUserClient::clientDied() {
    return clientClose();
}

IOReturn Lenovo83ALDmicUserClient::externalMethod(uint32_t selector, IOExternalMethodArguments *args,
                                           IOExternalMethodDispatch *dispatch, OSObject *target, void *reference) {
    if (selector >= kLenovo83ALDmicMethodCount) return kIOReturnUnsupported;
    dispatch = const_cast<IOExternalMethodDispatch *>(&sMethods[selector]);
    return super::externalMethod(selector, args, dispatch, this, reference);
}

IOReturn Lenovo83ALDmicUserClient::sGetInfo(OSObject *target, void *, IOExternalMethodArguments *args) {
    auto self = OSDynamicCast(Lenovo83ALDmicUserClient, target);
    if (!self || !self->owner) return kIOReturnNotAttached;
    args->scalarOutput[0] = kLenovo83ALDmicInterfaceVersion;
    args->scalarOutput[1] = self->owner->stateBits();
    args->scalarOutput[2] = Lenovo83ALDmic::kRate;
    args->scalarOutput[3] = Lenovo83ALDmic::kChannels;
    args->scalarOutput[4] = Lenovo83ALDmic::kRingBytes;
    args->scalarOutput[5] = Lenovo83ALDmic::kFrameBytes;
    return kIOReturnSuccess;
}

IOReturn Lenovo83ALDmicUserClient::sStart(OSObject *target, void *, IOExternalMethodArguments *) {
    auto self = OSDynamicCast(Lenovo83ALDmicUserClient, target);
    if (!self || !self->owner) return kIOReturnNotAttached;
    if (self->started) return kIOReturnSuccess;
    IOReturn r = self->owner->clientStart();
    if (r == kIOReturnSuccess) self->started = true;
    return r;
}

IOReturn Lenovo83ALDmicUserClient::sStop(OSObject *target, void *, IOExternalMethodArguments *) {
    auto self = OSDynamicCast(Lenovo83ALDmicUserClient, target);
    if (!self || !self->owner) return kIOReturnNotAttached;
    if (!self->started) return kIOReturnSuccess;
    self->started = false;
    return self->owner->clientStop();
}

IOReturn Lenovo83ALDmicUserClient::sGetPosition(OSObject *target, void *, IOExternalMethodArguments *args) {
    auto self = OSDynamicCast(Lenovo83ALDmicUserClient, target);
    if (!self || !self->owner) return kIOReturnNotAttached;
    uint64_t pos = 0, host = 0, gen = 0;
    IOReturn r = self->owner->readPosition(&pos, &host, &gen);
    args->scalarOutput[0] = pos;
    args->scalarOutput[1] = host;
    args->scalarOutput[2] = gen;
    return r;
}

IOReturn Lenovo83ALDmicUserClient::clientMemoryForType(UInt32 type, IOOptionBits *options, IOMemoryDescriptor **memory) {
    if (type != kLenovo83ALDmicRingMemoryType || !owner) return kIOReturnBadArgument;
    IOMemoryDescriptor *md = owner->ringMemory();      // retained; IOUserClient releases it
    if (!md) return kIOReturnNoMemory;
    *options = kIOMapReadOnly;
    *memory = md;
    return kIOReturnSuccess;
}
