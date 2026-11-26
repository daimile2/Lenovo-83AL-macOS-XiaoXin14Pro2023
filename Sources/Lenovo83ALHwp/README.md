# Lenovo83ALHwp

Lenovo83ALHwp 是一个机器专用的 Lilu 插件，用于修正 Lenovo 83AL（小新 Pro 14 2023 IRH8）上 i5-13500H 的混合 P 核 HWP 请求。

它不是通用 XCPM 补丁，也不包含显卡、音频、睡眠、C-state、PL1 或 PCI 电源管理功能。

## 问题与修复

在本机 macOS 26.7.3（25G342）上，XCPM 持续请求 4700 MHz P-state，但 P 核实际频率长期停留在约 3.5～3.6 GHz。

实测涉及两个条件：

1. XCPM 使用 100 MHz 档位写入混合 P 核的 `IA32_HWP_REQUEST`（MSR `0x774`），而本机 P 核的 HWP highest 为 60。插件把符合条件的 max 从 47 调整为 60，并按比例换算 desired。
2. XCPM 请求的 EPP 为 `0x80`。插件把同一合格请求的 EPP 改为 `0x00`，请求最高性能偏好。

只有同时满足以下条件的请求才会被修改：

- 真实 CPU 为 family 6、model `0xBA`；
- CPUID 报告 HWP 和 Hybrid；
- 当前核心为 CPUID.1A type `0x40` 的 P 核；
- HWP highest 为 60；
- Apple 原请求的 max 为 47、desired 不超过 47、EPP 为 `0x80`；
- 未启用 package-control bit 42。

E 核、降低过的 max、非法 desired、其他 EPP 和 package-control 请求均跳过。minimum、activity window 和其他位保持不变。

插件只在 Apple 自己的 `0x774` 写入之后执行修正，没有主动定时器。不会写入 `0x1FC`、`0x610`、C-state、PCI D3、PL1 或显示寄存器。

## 已验证环境

- Lenovo 83AL / 小新 Pro 14 2023 IRH8
- Intel i5-13500H，4P＋8E
- macOS 26.7.3，build 25G342
- Darwin 25.6.0 x86_64
- Lilu 1.7.2
- CpuTopologyRebuild 2.0.2
- OpenCore 注入，正常 macOS 启动模式

路由前会逐字节核对运行中内核的函数入口和 `0x774` 写入点。不匹配时不写 MSR。

## 本机实测结果

0.2.0 在 AC 供电下完成 10 秒空闲、20 秒单线程和 10 秒全线程复核：

| 场景 | 实测结果 | Intel 模型估算封装功耗 |
| --- | --- | --- |
| 空闲 10 秒 | Package C-state 平均 63.66%，主要为 C2 | 平均 8.28 W |
| 单线程 20 秒 | 每样本最高 P 核平均约 4.49 GHz，最高 4.638 GHz | 平均 16.86 W |
| 全线程 10 秒 | P 核整体平均约 4.12 GHz，E 核约 2.66 GHz | 平均 48.55 W |

这些数值是 `powermetrics` 的 1 秒采样平均值，不代表持续稳定 4.70 GHz。测试中出现了 `CPU LIMIT THERMAL`，本项目不会绕过温度或功耗保护。

尚未验收其他机型、其他 macOS build、长期稳定性、电池供电或睡眠唤醒。

开发机已把 0.2.0 定点并入内盘音频＋双麦 EFI，并在同一内盘启动中确认本插件、AppleALC、SimpleHDA 与 Lenovo83ALDmic 同时加载。

## 构建

需要 macOS 和 Xcode Command Line Tools。仓库包含固定哈希的离线构建依赖，无需单独下载 Lilu 或 MacKernelSDK。

```bash
cd Lenovo83ALHwp
bash build.sh
```

产物位于：

```text
build/Lenovo83ALHwp.kext
```

`build/` 已被 `.gitignore` 排除，不应提交到仓库。

## 安装

1. 挂载实际用于启动的 EFI。
2. 把 `build/Lenovo83ALHwp.kext` 放入该 OpenCore 的 `EFI/OC/Kexts/`。
3. 在 `config.plist` 的 `Kernel/Add` 中，把本插件放在已启用的 Lilu 之后。
4. 重启后核对加载状态。

OpenCore 条目字段：

| 字段 | 值 |
| --- | --- |
| `Arch` | `x86_64` |
| `BundlePath` | `Lenovo83ALHwp.kext` |
| `Enabled` | `true` |
| `ExecutablePath` | `Contents/MacOS/Lenovo83ALHwp` |
| `PlistPath` | `Contents/Info.plist` |
| `MinKernel` | `25.6.0` |
| `MaxKernel` | `25.6.0` |

不要与 NootedGreen XE-PM 或 `-ngreenpm` 叠加。可使用 `-l83hwpoff` 禁用本插件。

回退时移除该 kext 及对应 `Kernel/Add` 条目，或者使用未安装本插件的原启动 EFI。不要热卸载正在使用的内核驱动。

## 启动后核对

```bash
kextstat | grep org.lenovo83al.hwp
sysctl debug.l83hwp.report
```

`route` 含义：

| 值 | 含义 |
| --- | --- |
| 1 | 路由已安装 |
| 2 | 未找到目标符号 |
| 3 | 函数入口字节不匹配，未写入 |
| 4 | `0x774` 写入点字节不匹配，未写入 |
| 5 | 路由失败，未写入 |
| 6 | CPU 不受支持，未写入 |

`writes` 表示修正路径实际执行的次数。每核快照中的 `new_epp` 应为 `0x00`。`debug.l83hwp.report` 只返回已有快照，不会因读取 sysctl 而访问 MSR。

## 许可证与上游

HWP 路由、混合核心单位换算和 EPP 机制参考并修改自 NootedGreen XE-PM。衍生代码按 Thou Shalt Not Profit License 1.0 发布，详见 `LICENSE`。

Lilu、MacKernelSDK 和 NootedGreen 的来源及许可证见 `THIRD_PARTY_NOTICES.md` 与 `licenses/`。
