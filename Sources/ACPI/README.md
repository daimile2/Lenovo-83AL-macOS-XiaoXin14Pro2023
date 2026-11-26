# ACPI 源码说明

`SSDT-PEG1-ON.dsl` 是本机 RTX 3050 Laptop 根端口启动恢复所用的定制源文件；对应启用成品为 `EFI/OC/ACPI/SSDT-PEG1-ON.aml`，表头 OEM ID／Table ID 为 `83AL`／`PEG1ON`。

它只在 Darwin 下执行，使用本机 OEM `PON`／`L23D` 和有界等待，不包含其他机型的主板补丁。不要因为其他电脑也有同名 ACPI 路径就直接复用。

其余 AWAC、EC-USBX、PLUG-ALT、PNLF 和未启用的 DGPU-OFF 以当前已验证 AML 成品保留在 EFI 中；这些常见补丁的上游构建背景可参考 [CorpNewt/SSDTTime](https://github.com/corpnewt/SSDTTime)。本目录不提供与实际成品对应关系未重新核对的反编译源码。
