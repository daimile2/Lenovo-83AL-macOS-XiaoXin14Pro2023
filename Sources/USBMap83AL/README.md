# USBMap83AL

这是 Lenovo 83AL 当前 EFI 使用的 codeless USB 映射源 plist，成品位于 `EFI/OC/Kexts/USBMap83AL.kext`。

它只含本机 XHCI／TXHC 端口属性，没有可执行代码。其他主板或其他接线定义不能直接复用。修改后应重新核对实际 USB 端口，而不是根据端口名称猜测。
