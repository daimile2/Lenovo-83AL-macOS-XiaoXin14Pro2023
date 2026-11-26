// Lenovo83ALHwp: hybrid P-core HWP request-unit and EPP support for i5-13500H.
// Derived from the HWP-routing idea in NootedGreen XE-PM (kern_xepm.cpp),
// Copyright 2026 the NootedGreen contributors. Licensed under the
// Thou Shalt Not Profit License 1.0; see LICENSE-NootedGreen.
//
// This derivative intentionally removes XE-PM's energy-efficient-turbo, C-state,
// PCI D3, PL1, sensor and graphics functionality. After Apple's own eligible
// 0x774 write it rescales max/desired and changes EPP 0x80 to 0. No timer.

#include <Headers/kern_api.hpp>
#include <Headers/kern_patcher.hpp>
#include <IOKit/IOLib.h>
#include <sys/sysctl.h>
#include "hwp_transform.hpp"

extern "C" int cpu_number(void);

static inline uint64_t l83Rdmsr(uint32_t m) {
    uint32_t lo, hi;
    asm volatile("rdmsr" : "=a"(lo), "=d"(hi) : "c"(m));
    return ((uint64_t)hi << 32) | lo;
}

static inline void l83Wrmsr(uint32_t m, uint64_t v) {
    asm volatile("wrmsr" : : "c"(m), "a"((uint32_t)v), "d"((uint32_t)(v >> 32)));
}

static inline void l83Cpuid(uint32_t leaf, uint32_t subleaf,
                            uint32_t &a, uint32_t &b, uint32_t &c, uint32_t &d) {
    asm volatile("cpuid" : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
                         : "a"(leaf), "c"(subleaf));
}

struct CpuSnapshot {
    uint32_t seen;
    uint32_t writes;
    uint32_t type;
    uint32_t highest;
    uint64_t oldRequest;
    uint64_t newRequest;
};

static mach_vm_address_t gOriginalSetMult = 0;
static int gRoute = 0; // 1 installed; 2 no symbol; 3/4 byte mismatch; 5 route error; 6 unsupported CPU
static int gWrites = 0;
static int gSkips = 0;
static CpuSnapshot gCpu[32];

static bool supportedCpu() {
    uint32_t a, b, c, d;
    l83Cpuid(1, 0, a, b, c, d);
    const uint32_t baseFamily = (a >> 8) & 0xf;
    const uint32_t family = baseFamily == 0xf ? baseFamily + ((a >> 20) & 0xff) : baseFamily;
    const uint32_t model = ((a >> 4) & 0xf) | ((a >> 12) & 0xf0);
    if (family != 6 || model != 0xba) return false; // real Raptor Lake, not the spoofed kernel model

    l83Cpuid(6, 0, a, b, c, d);
    if (!(a & (1U << 7))) return false;            // CPUID.06H:EAX.HWP

    l83Cpuid(7, 0, a, b, c, d);
    if (!(d & (1U << 15))) return false;           // CPUID.07H:EDX.Hybrid
    return true;
}

static uint64_t l83SetMult(uint64_t mult, uint64_t a1, uint64_t a2, uint64_t a3) {
    const uint64_t result = FunctionCast(l83SetMult, gOriginalSetMult)(mult, a1, a2, a3);

    // XCPM also calls this before HWP is enabled. Do not touch HWP MSRs then.
    if (!(l83Rdmsr(0x770) & 1)) return result;

    const uint64_t oldRequest = l83Rdmsr(0x774);
    uint32_t a, b, c, d;
    l83Cpuid(0x1a, 0, a, b, c, d);
    const uint32_t type = a >> 24;                  // 0x40 P-core, 0x20 E-core
    const uint32_t highest = (uint32_t)(l83Rdmsr(0x771) & 0xff);
    uint64_t newRequest = oldRequest;

    // Do not override reduced limits. Only XCPM's known full-range request is
    // eligible. E-cores and every other CPU/request combination remain untouched.
    if (!l83TransformRequest(oldRequest, type, highest, newRequest)) {
        __sync_fetch_and_add(&gSkips, 1);
        return result;
    }

    if (newRequest != oldRequest) {
        l83Wrmsr(0x774, newRequest);
        const int cpu = cpu_number();
        __sync_fetch_and_add(&gWrites, 1);
        if (cpu >= 0 && cpu < 32) {
            gCpu[cpu].type = type;
            gCpu[cpu].highest = highest;
            gCpu[cpu].oldRequest = oldRequest;
            gCpu[cpu].newRequest = newRequest;
            __sync_fetch_and_add(&gCpu[cpu].writes, 1);
            gCpu[cpu].seen = 1;
        }
    }
    return result;
}

static int l83Report SYSCTL_HANDLER_ARGS {
    char buf[3072];
    int used = snprintf(buf, sizeof(buf),
        "Lenovo83ALHwp 0.2.0\nroute=%d writes=%d skips=%d\n"
        "route: 1=installed 2=no-symbol 3=prologue-mismatch 4=wrmsr-mismatch 5=route-error 6=unsupported-cpu\n"
        "scope: P-core highest=60, Apple max=47, EPP 0x80->0; min/window/other bits unchanged\n",
        gRoute, gWrites, gSkips);
    if (used < 0) return EIO;
    size_t off = (size_t)used;
    for (int i = 0; i < 32 && off < sizeof(buf); i++) {
        if (!gCpu[i].seen) continue;
        const int n = snprintf(buf + off, sizeof(buf) - off,
            "cpu=%d writes=%u type=0x%02x highest=%u old=0x%016llx new=0x%016llx old_epp=0x%02x new_epp=0x%02x\n",
            i, gCpu[i].writes, gCpu[i].type, gCpu[i].highest,
            (unsigned long long)gCpu[i].oldRequest,
            (unsigned long long)gCpu[i].newRequest,
            (unsigned)((gCpu[i].oldRequest >> 24) & 0xff),
            (unsigned)((gCpu[i].newRequest >> 24) & 0xff));
        if (n < 0) return EIO;
        off += (size_t)n;
    }
    if (off >= sizeof(buf)) off = sizeof(buf) - 1;
    buf[off] = 0;
    return SYSCTL_OUT(req, buf, off + 1);
}

SYSCTL_NODE(_debug, OID_AUTO, l83hwp, CTLFLAG_RD, 0, "Lenovo83ALHwp read-only status");
SYSCTL_PROC(_debug_l83hwp, OID_AUTO, report, CTLTYPE_STRING | CTLFLAG_RD | CTLFLAG_ANYBODY,
            nullptr, 0, l83Report, "S", "HWP request snapshots; no MSR access");

void l83HwpInstall(KernelPatcher &patcher) {
    sysctl_register_oid(&sysctl__debug_l83hwp);
    sysctl_register_oid(&sysctl__debug_l83hwp_report);

    if (!supportedCpu()) {
        gRoute = 6;
        IOLog("L83HWP: unsupported CPU; no route and no MSR writes\n");
        return;
    }

    const mach_vm_address_t base = patcher.solveSymbol(KernelPatcher::KernelID, "_xcpm_enable_pstate_ctrs");
    patcher.clearError();
    if (!base) {
        gRoute = 2;
        IOLog("L83HWP: _xcpm_enable_pstate_ctrs missing; no writes\n");
        return;
    }

    // Reference location established by XE-PM. Both the function prologue and
    // the exact IA32_HWP_REQUEST wrmsr site must match on the running kernel.
    const mach_vm_address_t fn = base + 0x1190;
    static const uint8_t prologue[] = {0x55, 0x48, 0x89, 0xe5, 0x53, 0x50, 0x89, 0xfb};
    static const uint8_t writeSite[] = {0x89, 0xf8, 0xc1, 0xea, 0x18,
                                       0xb9, 0x74, 0x07, 0x00, 0x00, 0x0f, 0x30};
    const auto *p = reinterpret_cast<const uint8_t *>(fn);
    for (size_t i = 0; i < sizeof(prologue); i++) {
        if (p[i] != prologue[i]) {
            gRoute = 3;
            IOLog("L83HWP: prologue mismatch at +0x1190; no writes\n");
            return;
        }
    }
    for (size_t i = 0; i < sizeof(writeSite); i++) {
        if (p[0x168 + i] != writeSite[i]) {
            gRoute = 4;
            IOLog("L83HWP: HWP wrmsr site mismatch; no writes\n");
            return;
        }
    }

    gOriginalSetMult = patcher.routeFunction(fn, reinterpret_cast<mach_vm_address_t>(l83SetMult), true);
    if (patcher.getError() != KernelPatcher::Error::NoError || !gOriginalSetMult) {
        gOriginalSetMult = 0;
        gRoute = 5;
        patcher.clearError();
        IOLog("L83HWP: route failed; no writes\n");
        return;
    }
    gRoute = 1;
    IOLog("L83HWP: route installed; P-core max/desired 47->60 and EPP 0x80->0 only\n");
}
