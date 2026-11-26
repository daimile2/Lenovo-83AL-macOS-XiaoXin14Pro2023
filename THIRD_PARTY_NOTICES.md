# 第三方来源与许可索引

本仓库是机型专用的整机集合，不重设任何第三方组件的许可证。每个组件的版权和许可仍属于各自作者。源码目录中的原许可、bundle 内资源和 `licenses/` 中的文本应一并保留。

## 本机定制组件

| 组件 | 来源与许可 |
| --- | --- |
| NullMoth Lenovo 83AL 阶段12 | 基于 [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver) v3.0，提交 `64342081d975c903183d7bea44c0800310dcdec4`；主体 PolyForm Noncommercial 1.0.0，见 `Sources/NullMoth/LICENSE`、`NOTICE` 和 `licenses/` |
| Lenovo83ALHwp 0.2.0 | HWP 路由及修正机制衍生自 NootedGreen XE-PM；Thou Shalt Not Profit 1.0。Lilu 为 BSD-3-Clause，MacKernelSDK 为 APSL-2.0；详见该源码目录 |
| Lenovo83ALDmic 0.1.0 | 参考 HP250Dmic；TGLDmic／LatSOFAudio 为 BSD-3-Clause；Intel SOF 固件保留 Intel 许可；见源码目录和 bundle Resources |
| USBMap83AL | 本机 codeless plist 映射，源文件保留在 `Sources/USBMap83AL/` |

## EFI 中的主要第三方组件

| 组件／本机版本 | 上游 |
| --- | --- |
| OpenCore 1.0.8、OpenRuntime、OpenHfsPlus | [acidanthera/OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) |
| Lilu 1.7.2 | [acidanthera/Lilu](https://github.com/acidanthera/Lilu)，BSD-3-Clause |
| AppleALC 1.9.8 | [acidanthera/AppleALC](https://github.com/acidanthera/AppleALC)，BSD-3-Clause |
| VirtualSMC／SMCBatteryManager 1.3.8 | [acidanthera/VirtualSMC](https://github.com/acidanthera/VirtualSMC)，BSD-3-Clause |
| VoodooPS2Controller 2.3.7 | [acidanthera/VoodooPS2](https://github.com/acidanthera/VoodooPS2)，保留上游许可 |
| VoodooI2C 3.1.1 | [VoodooI2C/VoodooI2C](https://github.com/VoodooI2C/VoodooI2C)，GPL-3.0 |
| VoodooI2CHID | [VoodooI2C/VoodooI2CHID](https://github.com/VoodooI2C/VoodooI2CHID)，保留上游许可 |
| WhateverXe 0.8.3 | [b00t0x/WhateverXe](https://github.com/b00t0x/WhateverXe)，BSD-3-Clause |
| CpuTopologyRebuild 2.0.2 | [b00t0x/CpuTopologyRebuild](https://github.com/b00t0x/CpuTopologyRebuild)，BSD-3-Clause |
| AMFIAnchor 0.1.2／Injector | [b00t0x/AMFIAnchor](https://github.com/b00t0x/AMFIAnchor)，BSD-3-Clause；原 NOTICE 也应保留 |
| AMFIPass 1.4.1 | [dhinakg/AMFIPass](https://github.com/dhinakg/AMFIPass)，按实际上游条款使用 |
| SimpleHDA 1.0.2 | [laobamac/SimpleHDA](https://github.com/laobamac/SimpleHDA)，上游 NOTICE 保留于 `licenses/` |
| AirportItlwm 2.4.0 | [OpenIntelWireless/itlwm](https://github.com/OpenIntelWireless/itlwm)，GPL-2.0；无线固件另遵循 Intel 固件许可 |
| IntelBluetoothFirmware／IntelBTPatcher 2.5.3 | [OpenIntelWireless/IntelBluetoothFirmware](https://github.com/OpenIntelWireless/IntelBluetoothFirmware)，GPL-3.0 |
| BlueToolFixup 2.7.2 | [acidanthera/BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM)，GPL-2.0 |

## 部署工具

- `Tools/macserial/macserial.exe` 与 `macserial.linux` 原样取自 [acidanthera/OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) 1.0.8 RELEASE 的 `Utilities/macserial/`，使用 BSD-3-Clause；来源、格式说明和许可证见 `Tools/macserial/`。
- `Tools/macrecovery/` 原样取自同一官方 RELEASE 的 `Utilities/macrecovery/`，使用 BSD-3-Clause；用于从 Apple 下载并校验 Recovery，不改变其许可或归属。
- Windows／Linux 部署脚本只在临时 EFI 副本中生成个人 SMBIOS，不携带发布者的 rEFInd、Ubuntu 或个人磁盘配置。

## 主机端 NullMoth 相关组件

NVIDIA open GPU kernel modules、GSP firmware、Mesa／NVK、Vulkan loader、metal2vulkan、LLVM 和其他依赖的归属与许可见 `Sources/NullMoth/NOTICE`、`Sources/NullMoth/licenses/` 以及合并后 `HostGraphics/Library/NullMoth/licenses/`。GSP 固件不因被收录而改授为其他许可证。

若上游许可证文件缺失或链接发生变化，不代表相应代码进入公共领域；发布和再分发者应自行遵守该版本实际上游条款。
