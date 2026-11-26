# 功能状态与验收边界

## 已在本机确认

截至 2026-11-26，在合并后的**内盘 EFI**启动中确认：

| 功能 | 状态与依据 |
| --- | --- |
| NVIDIA Metal／内屏显示 | 当前桌面正常；阶段12已确认自动注册、active=1，submit／perform／copy 持续增长 |
| CPU HWP 0.2.0 | `org.lenovo83al.hwp (0.2.0)` 已加载，`route=1`，`new_epp=0x00`，writes 持续执行 |
| AppleHDA 音频栈 | AppleALC 1.9.8 与 SimpleHDA 1.0.2 已加载；用户确认原音频输出播放正常 |
| Lenovo 双麦 | Lenovo83ALDmic 0.1.0 已加载；QuickTime 真实录音和回放正常 |
| 网络 | 用户确认合并后的内盘启动中网页访问正常 |
| OpenCore | 内盘 OpenCore 和 macOS 冷启动成功；公开部署仅保留这一套启动链 |

早期 U 盘只是 CPU 0.2.0 基线，没有音频与 DMIC；本仓库不采用该 U 盘配置覆盖内盘。最终 EFI 来自“内盘音频＋双麦基线＋定点加入 CPU 0.2.0”的合并结果。

## 公开 EFI 范围

公开部署只提供 `EFI/OC/`，部署工具从 `OpenCore.efi` 生成默认 `EFI/Boot/BOOTX64.EFI`。发布者本机的 rEFInd、Ubuntu、主题、volume GUID 和其他个性化启动内容不属于其他用户的安装依赖，不应放入公开基线。

## 明确没有据此宣称的内容

- 其他 Lenovo 机型、其他 RTX 显卡或其他 macOS build 的兼容性。
- 睡眠、唤醒以及唤醒后的显示、HWP、音频或 DMIC 稳定性。
- 电池供电下的频率、功耗和长期稳定性。
- 深层 Package C-state 或完整电源管理。
- 持续稳定 4.70 GHz；硬件热限制仍然存在。
- proxy 内屏亮度调节。当前已知该路线不能调整亮度，Xe 核显路线的亮度能力与这里是独立问题。
- 所有蓝牙、扬声器组合、摄像头或其他未逐项测试功能。
- Windows 部署脚本已通过真实 Windows 执行，或两个部署脚本已在所有 USB 磁盘和固件组合上验收。
- Apple `latest` Recovery 永远对应固定 build；主机端安装器仍只接受已经核对的 `25G342`。
