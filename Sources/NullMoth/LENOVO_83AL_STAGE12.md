# Lenovo 83AL 阶段12最终源码说明

本目录不是只有补丁的碎片目录，而是 NullMoth 官方 **v3.0** 完整源码快照，再覆盖本机最终修改后的三个文件。

- 上游：https://github.com/nullmoth/nvidia-macos-driver
- 固定标签：`v3.0`
- 标签提交：`64342081d975c903183d7bea44c0800310dcdec4`
- 本机目标：Lenovo 83AL，RTX 3050 Laptop 6GB，Intel 固件内屏，macOS 26.7.3（25G342）

## 最终文件哈希

| 文件 | SHA-256 |
| --- | --- |
| `kexts/NVRM/accel/nvrm-accel.cpp` | `20372f9cf2c880f137a94674f3deb400556d8fa8ec979a8fe1b3f1a4f46608b8` |
| `kexts/NVRM/accel/nvaccel_stubs.h` | `8f5a4d7130471cb732e31b6863fbdf0534b4667a5237eb21aeee55c2272353ea` |
| `kexts/NVRMFB/fb/nvrm-fb.cpp` | `c35c3864725864b78782fca6fd8d937f9633bf310cee6627dc34d3931370e535` |

阶段10～12的关键结果均保留：真实 Intel framebuffer 物理地址、Apple 正常 resource prepare、冷启动自动 proxy 注册与 mode-change、K6 实际像素 copy，以及轻量事务计数。阶段7／8专用诊断、power replay 和 K6 每帧64点采样已移除。

不要把这里的源码回退为上游原版后仍声称支持本机内屏；上游通用实现不等于本机 proxy 最终路线。

## 构建

完整依赖和要求见上游 `README.md`。核心组件需要 macOS、Xcode、NVIDIA open-gpu-kernel-modules 620.70.06；Metal 插件和翻译器还需要 Rust、Meson／Ninja 等上游工具。

macOS 26 的 NVAccel 构建形式为：

```bash
OGKM=/path/to/ogkm-620.70.06 NM_TAHOE=1 \
  bash build/accel_build.sh kexts/NVRM /path/to/output
```

同时构建支持系统版本的 NVAccel：

```bash
bash build/accel_build_all.sh kexts/NVRM /path/to/output
```

其他组件按上游构建文档执行。修改 ABI 头文件后，必须重新构建匹配的 NVRMFB 与 NVAccel，不能混用旧 ABI 二进制。

仓库中的 `HostGraphics` 是本机当前实际运行并验证过的二进制。自行编译产生的新二进制不应在未上机前标为已验证。本目录不包含本机中途采集、安装、修复或验证脚本。

## 许可

`plugin/`、`kexts/`、`build/`、`package/` 等遵循根目录 `LICENSE` 的 PolyForm Noncommercial 1.0.0；翻译器、NVK、NVIDIA 组件及其他第三方部分遵循 `NOTICE` 和 `licenses/` 中各自条款。
