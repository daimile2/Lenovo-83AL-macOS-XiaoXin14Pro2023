# Lenovo83ALDmic 0.1.0

Lenovo 83AL／小新 Pro 14 2023 IRH8 专用内置双路数字麦克风驱动，包含内核 kext、CoreAudio HAL 和原样嵌入的 Intel SOF 固件。

## 已验证状态

- 控制器：Intel HDA/cAVS `8086:51ca`，PCI subsystem `17aa:3845`。
- 目标系统：本机 macOS 26.7.3（25G342）。
- 设备名称：`Lenovo 83AL Internal Digital Microphone`。
- 已在 QuickTime 中完成真实录音与回放；不是只看到输入设备或模拟 ALC287 输入。
- 已完成多次 DSP boot→capture→stop→power down 循环。
- 尚未宣称睡眠唤醒或长期录音稳定性。

驱动从 HP250Dmic 0.1.0 参考实现移植，但不包含 HP 的 EFI、显卡、电源管理或主板专用补丁。PCI 匹配限定 Lenovo `17aa:3845`，不会作为通用 DMIC 驱动分发。

## 本机参数

- 两个数字麦克风，48 kHz，双通道。
- PDM0：38.4 MHz 输入，CLKDIV=16，PDM clock=2.4 MHz。
- MCIC=25，FIR A decimation=2，因此 `38.4 MHz / 16 / 25 / 2 = 48 kHz`。
- 使用 Ubuntu SOF 2.2 IPC3 对应的 PDM0 双通道路线。
- SOF `sof-rpl.ri` 原样嵌入，SHA-256：`294e5a51b1d3fc4ceda57780927c2a2ec95bb5d23477f879a9fb648c6c01cb30`。

完整字段保留在 `PORT-STATE.json`、`nhlt-dmic.json` 和 `pipeline.json`。

## 构建

需要 macOS 和 Xcode Command Line Tools：

```bash
cd Sources/Lenovo83ALDmic
bash build.sh
```

产物：

```text
build/Lenovo83ALDmic.kext
build/Lenovo83ALDmic.driver
build/manifest.json
```

## 安装位置

- kext：`EFI/OC/Kexts/Lenovo83ALDmic.kext`，并在 Lilu 之后启用。
- HAL：`/Library/Audio/Plug-Ins/HAL/Lenovo83ALDmic.driver`。

不要同时叠加 AppleHDA／SimpleHDA 之外的另一套 HDA 驱动来“增强”本设备。双麦是 PCH DMIC 路径，不经过 ALC287 模拟输入。不要在 CoreAudio 使用驱动时热卸载 kext。

## 来源与许可

- TGLDmic：BSD-3-Clause。
- LatSOFAudio：BSD-3-Clause。
- Intel SOF 2.2 固件：Intel 原许可，见 `firmware/LICENCE.Intel`。
- HP250Dmic 0.1.0 为移植参考实现。

许可原文保留于 `licenses/` 和固件目录。本目录只含最终源码、固件、参数和构建脚本，不含中途主机测试或验证脚本。
