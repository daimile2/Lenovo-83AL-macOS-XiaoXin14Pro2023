# 安装、构建与回退

> [!CAUTION]
> **数据无价，看好分区再分盘安装；分盘操作不能反悔，且分完盘数据丢失在软件上不可能找回（作者个人经历）。**

## 1. 适用范围

仅建议在与发布者相同的 Lenovo 83AL／小新 Pro 14 2023 IRH8、i5-13500H、RTX 3050 Laptop 6GB、macOS 26.7.3（25G342）环境中参考。其他机型不要直接复制整份 EFI。

先保留一个能够独立启动的 EFI。不要在工作过程中重置 NVRAM，不要把旧 `config.plist.before-*` 或 `._*` 文件当成有效配置。

## 2. 最短安装路径

Windows 或 Linux 用户直接使用 `Tools/Windows/`、`Tools/Linux/` 中的部署工具，自动完成个人 SMBIOS、纯 OpenCore、Apple Recovery 下载校验和安装 U 盘写入。完整步骤见 [其他用户快速使用](其他用户快速使用.md)。

公开版不包含发布者的 rEFInd、Ubuntu 文件、主题或磁盘 GUID。安装 U 盘属于联网 Recovery 安装盘，不是全量离线安装镜像。

## 3. 手工填写 SMBIOS（不使用部署工具时）

编辑 `EFI/OC/config.plist`：

```text
PlatformInfo → Generic → MLB
PlatformInfo → Generic → SystemSerialNumber
PlatformInfo → Generic → SystemUUID
PlatformInfo → Generic → ROM
```

公开版故意将这些字段清空或置零。保持 `SystemProductName=MacBookPro16,2`，用可靠工具生成自己的信息。不要把公开占位配置当作无需修改即可启动的成品，也不要公开发布自己的真实字段。

## 4. 安装 OpenCore

将填写好 SMBIOS 的 `EFI/OC/` 放入本机 EFI 分区的 `EFI/` 下，并用 `OpenCore.efi` 作为默认启动文件。最终应具有：

```text
EFI/OC/OpenCore.efi
EFI/OC/config.plist
EFI/Boot/BOOTX64.EFI
```

不要把 NullMoth 的 `NVRM.kext`、`NVAccel.kext`、`NVRMFB.kext`、`NVRMAGDC.kext` 或 `NMIntelFB.kext` 再加入 `EFI/OC/Kexts`；它们由主机端 AuxKC 加载，不能重复注入。

## 5. 安装主机端显卡与双麦组件

确认完整仓库已经包含：

```text
HostGraphics/Library/Extensions/NVAccel.kext
HostGraphics/Library/GPUBundles/NVMTLDriver.bundle
HostAudio/Lenovo83ALDmic.driver
```

在仓库根目录运行最终安装器：

```bash
bash Tools/安装主机端组件.sh
```

安装器只处理 `HostGraphics` 和 `HostAudio`，不修改 EFI、NVRAM、默认输入或 TCC，不自动重启 CoreAudio，也不自动重启电脑。它会在当前 Mac 上重新生成 Auxiliary Kernel Collection；**不要直接复制其他机器的 AuxKC**。

脚本只对已核对的 macOS build `25G342`、x86_64 环境执行。密码只应在 macOS 自己的终端提示中输入，不要写入脚本或日志。

## 6. 冷启动与功能核对

关机后再开机，通过 OpenCore 启动内盘 macOS。无需 SSH，不要手动写 `debug.nvaccelfb=3/4/5`，不要把重启 WindowServer 当作修复。

进入系统后：

```bash
sysctl debug.l83hwp.report
kextstat | grep -E 'org.lenovo83al.hwp|Lenovo83ALDmic|AppleALC|SimpleHDA'
```

CPU 应显示 `route=1`，合格 P 核快照应为 `new_epp=0x00`。再用 QuickTime 选择 `Lenovo 83AL Internal Digital Microphone` 做真实录音和回放；只看到输入设备不等于录音成功。

## 7. 从最终源码构建

正常使用合并后的主机端二进制即可，不必重新编译。需要修改时：

- NullMoth：见 `Sources/NullMoth/LENOVO_83AL_STAGE12.md` 与上游 README。需要 macOS、Xcode、Rust、Meson/Ninja 和 NVIDIA open-gpu-kernel-modules 620.70.06。
- 双麦：在 `Sources/Lenovo83ALDmic` 中执行 `bash build.sh`，产物在 `build/`。
- HWP：在 `Sources/Lenovo83ALHwp` 中执行 `bash build.sh`，产物在 `build/Lenovo83ALHwp.kext`。

新构建不应被自动描述为已经过真机验证；发布包中已验证的二进制与后续自行构建要明确区分。

## 8. 回退

- 启动问题：使用事先保留的可启动 EFI，不要叠加另一套显卡或音频补丁。
- CPU 回退：移除 `Lenovo83ALHwp.kext` 及其唯一 `Kernel/Add` 条目，或使用 `-l83hwpoff`；不要热卸载正在使用的驱动。
- 双麦回退：只移除 Lenovo DMIC kext 条目、对应 kext 和 HAL；不要动显示、AppleHDA 输出或其他启动项。不要在 CoreAudio 使用时热卸载 kext。
- 显卡回退：恢复与原系统匹配的 NullMoth 主机端组件并重新生成 AuxKC；不要通过随机 boot-args 或显示寄存器写入试错。
