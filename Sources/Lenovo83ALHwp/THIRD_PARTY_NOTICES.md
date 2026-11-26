# Third-party notices

## NootedGreen XE-PM

- Project: [Hackintosh-XPS13Plus-IrisXe-Tahoe](https://github.com/JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe)
- Reference source: `src/NootedGreen/kern_xepm.cpp`
- Used mechanism: XCPM HWP write routing, hybrid P-core max/desired scaling, and EPP preference.
- Deliberately excluded: energy-efficient-turbo writes, C-state changes, PCI D3, PL1/MCHBAR writes, sensors and graphics functionality.
- License: Thou Shalt Not Profit License 1.0. The complete license is retained in the repository root as `LICENSE`.

## Lilu 1.7.2

- Project: [acidanthera/Lilu](https://github.com/acidanthera/Lilu)
- File: `deps/Lilu-1.7.2-DEBUG.zip`
- SHA-256: `e95df95d82e8b151047abf359ecd9c853755c59293e19dfcc3907da8fbd8cf89`
- The unmodified DEBUG archive supplies the Lilu plugin SDK used at build time.
- License: BSD 3-Clause. See `licenses/Lilu-LICENSE.txt`.

## MacKernelSDK

- Project: [acidanthera/MacKernelSDK](https://github.com/acidanthera/MacKernelSDK)
- File: `deps/MacKernelSDK.tar.gz`
- SHA-256: `7ec8b20b137e030d0036ff2f76d21cceaff26f06b47592c1cbe66530b81035f8`
- The unmodified SDK snapshot supplies kernel headers and `libkmod.a` used at build time.
- License: Apple Public Source License 2.0. See `licenses/MacKernelSDK-LICENSE.txt`.

The dependency archives are included only to make the exact tested build reproducible offline. Their upstream copyrights and license terms remain with their respective owners.
