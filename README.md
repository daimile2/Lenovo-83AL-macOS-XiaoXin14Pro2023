# Lenovo 83AL／小新 Pro 14 2023 IRH8：macOS 26 专用整机基线

> [!CAUTION]
> **数据无价，看好分区再分盘安装；分盘操作不能反悔，且分完盘数据丢失在软件上不可能找回（作者个人经历）。**

> **本仓库只针对 Lenovo 83AL／小新 Pro 14 2023 IRH8 的这一套硬件与系统组合。它不是通用黑苹果引导，也不保证其他机型、其他显卡、其他主板或其他 macOS build 可用。请勿不经核对直接套用到其他电脑。**

## 已验证环境

| 项目 | 本机配置 |
| --- | --- |
| 机型 | Lenovo 83AL／小新 Pro 14 2023 IRH8，NVIDIA 独显 Intel 版 |
| CPU | Intel Core i5-13500H，4P＋8E，12 核 16 线程 |
| 内屏 | Intel 固件帧缓冲面板，2880×1800 |
| 独显 | NVIDIA GeForce RTX 3050 Laptop 6GB，PCI ID `10de:25ac` |
| 音频 | Realtek ALC287，PCH HDA/cAVS `8086:51ca`，subsystem `17aa:3845` |
| 数字麦克风 | PCH DMIC／SOF，双路数字麦克风 |
| 系统 | macOS 26.7.3，build `25G342`，Darwin `25.6.0`，x86_64 |
| 公开部署引导 | OpenCore 1.0.8；不包含发布者的 rEFInd、Ubuntu 或其他个性化启动文件 |

## 当前实测可用的内容

- **NVIDIA Metal 桌面合成与内屏显示**：NullMoth 阶段12最终改动，冷启动自动完成 proxy scanout 注册和 mode-change，无需 SSH 或手动写 `debug.nvaccelfb`。
- **模拟音频输出**：Lilu→AppleALC→SimpleHDA，恢复 macOS 26 的 AppleHDA 栈，`alc-layout-id=13`。
- **内置双路数字麦克风**：`Lenovo83ALDmic.kext`＋`Lenovo83ALDmic.driver`，已在 QuickTime 中选择 `Lenovo 83AL Internal Digital Microphone` 完成真实录音和回放。
- **网络**：当前 AirportItlwm 网络路径实际可用；蓝牙相关 kext 一并保留，但不据此宣称所有蓝牙功能均完成验收。
- **CPU HWP 修正**：Lenovo83ALHwp 0.2.0 已与音频、双麦在同一内盘 EFI 中共同工作，`route=1`，合格 P 核请求执行 max/desired 修正并将 EPP 从 `0x80` 改为 `0x00`。
- **OpenCore 冷启动**：公开版只部署 OpenCore 和默认 `BOOTX64.EFI`，其他用户不需要发布者的 rEFInd 或 Ubuntu 配置。

CPU 的 AC 短时复核中，单线程每样本最高 P 核频率约 4.0～4.64 GHz，全线程 P 核平均约 4.12 GHz；这不代表可以持续稳定运行 4.70 GHz。测试出现了 `CPU LIMIT THERMAL`，本项目不绕过热保护。

## 从 Windows／Linux 一步制作 macOS 安装 U 盘

准备 **8 GB 或更大的 U 盘、可用网络和 Python 3**。脚本会自动生成个人 SMBIOS、写入纯 OpenCore、从 Apple 下载并校验最新 Recovery，生成可启动的 macOS 联网安装 U 盘；也可选择把同一套 OpenCore 安装到内部 ESP。

Windows 管理员 PowerShell：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Tools\Windows\Lenovo83AL-EFI工具.ps1
```

Linux：

```bash
sudo bash Tools/Linux/Lenovo83AL-EFI工具.sh
```

**请直接阅读 [其他用户快速使用](docs/其他用户快速使用.md)。** 这是 Apple Recovery 联网安装盘，不是包含完整 macOS 的离线安装镜像；Recovery 中安装系统时仍需联网。安装完成后还必须运行 `Tools/安装主机端组件.sh`。

## 显示路线必须理解清楚

本机使用的路线是：

```text
NVIDIA Metal 桌面合成
→ Apple display-pipe transaction
→ NullMoth
→ Intel 固件帧缓冲
→ Intel 内屏 scan-out
```

这不是指定应用 offload，不是 NVIDIA 原生 modeset，也不是 NVIDIA 直接驱动内屏 scan-out。`NVRMIntelProxy` 返回真实 Intel 帧缓冲物理地址；Apple 正常 resource prepare 路径设置 active；K6 copy 将 IOSurface 的真实像素复制到 Intel 固件帧缓冲。

**不要把本配置与其他显卡、nmhybrid、DMC、P2P、resume、随机睡眠补丁或重复 HDA 驱动栈混合。**

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `EFI/OC/` | 已验证内盘 OpenCore 的公开脱敏版：ACPI、Kexts 和 `config.plist` |
| `HostGraphics/` | 本地合并后的 NullMoth 主机端 kext、Metal/Vulkan 组件、GSP 固件和许可 |
| `HostAudio/` | 双麦 CoreAudio HAL，安装到 `/Library/Audio/Plug-Ins/HAL/` |
| `Sources/NullMoth/` | 官方 v3.0 完整源码＋本机阶段12最终源码覆盖 |
| `Sources/Lenovo83ALDmic/` | 双麦 kext、HAL、固件与构建源码 |
| `Sources/Lenovo83ALHwp/` | CPU HWP 0.2.0 最终源码与离线构建依赖 |
| `Sources/USBMap83AL/` | 本机 codeless USB 映射的源 plist |
| `Tools/Windows/` | Windows 安装 U 盘与内部 OpenCore 部署工具 |
| `Tools/Linux/` | Linux 安装 U 盘与内部 OpenCore 部署工具 |
| `Tools/macserial/` | OpenCorePkg 1.0.8 官方 macserial 二进制、来源与许可 |
| `Tools/macrecovery/` | OpenCorePkg 1.0.8 官方 Apple Recovery 下载与校验工具 |
| `Tools/安装主机端组件.sh` | macOS 25G342 专用显卡、双麦 HAL 与 AuxKC 安装器 |
| `docs/其他用户快速使用.md` | Windows／Linux 短流程安装说明 |
| `docs/INSTALL.md` | 安装与回退说明 |
| `docs/STATUS.md` | 已验证与未验收边界 |
| `THIRD_PARTY_NOTICES.md` | 第三方来源和许可索引 |

## SMBIOS 与隐私

公开配置的 `MLB`、`SystemSerialNumber`、`SystemUUID` 和 `ROM` 均为空或占位值。部署工具会在临时副本中生成个人值，保持 `SystemProductName=MacBookPro16,2`，不会回写公开仓库。不要把生成后的个人 `config.plist` 再提交到公开仓库。

## 许可

本仓库是多组件整机集合，**没有覆盖所有内容的单一许可证**。NullMoth 使用 PolyForm Noncommercial 1.0.0；Lenovo83ALHwp 的衍生部分使用 Thou Shalt Not Profit 1.0；macserial 和 macrecovery 使用 BSD-3-Clause；其他组件分别遵循各自上游许可证。详见 `THIRD_PARTY_NOTICES.md`、各源码目录和 `licenses/`。
