// Lenovo83ALHwp Lilu entry point. Normal macOS boots only.
#include <Headers/kern_api.hpp>
#include <Headers/plugin_start.hpp>

extern void l83HwpInstall(KernelPatcher &patcher);

static const char *bootargOff[] = {"-l83hwpoff"};

PluginConfiguration ADDPR(config) {
    xStringify(PRODUCT_NAME),
    parseModuleVersion(xStringify(MODULE_VERSION)),
    LiluAPI::AllowNormal,
    bootargOff,
    arrsize(bootargOff),
    nullptr,
    0,
    nullptr,
    0,
    KernelVersion::Tahoe,
    KernelVersion::Tahoe,
    []() {
        lilu.onPatcherLoadForce(
            [](void *, KernelPatcher &patcher) { l83HwpInstall(patcher); }, nullptr);
    }
};
