# AMFIAnchor sources and licenses

Original AMFIAnchor source and tools are licensed under BSD-3-Clause. This license does not relicense upstream projects or proprietary platform components.

Build dependencies:

- Lilu 1.7.2 (`e4748cc081bf060302c7d3c44a643ce1d11b7e1d`): BSD-3-Clause.
- MacKernelSDK (`05094e5e88cec7caedbfb35e8449ed0db94bf95b`): APSL-2.0 root license; individual files retain their own notices.

The resulting kext includes code from the SDK's `libkmod.a` and Lilu's `Library/plugin_start.cpp`, and uses Lilu's headers and runtime API. Retain applicable dependency notices when redistributing binaries.

Compatibility research references AMFIPass 1.4.1 / OpenCore-Legacy-Patcher, CoreTrustDemo research notes and Acidanthera style references. AMFIAnchor's injector contains the public SPKI and SKID for the signing CA used by WEX, not signing private keys.

Full upstream notices: https://github.com/b00t0x/AMFIAnchor/blob/main/NOTICES.md
