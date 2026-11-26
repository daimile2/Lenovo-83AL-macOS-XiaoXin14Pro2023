#!/bin/bash
# Final host-component installer for the verified Lenovo 83AL macOS 25G342 baseline.
# Does not modify EFI, NVRAM, CoreAudio defaults, TCC, or reboot automatically.
set -e
export LC_ALL=C
export LANG=C
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

[[ "$(uname -m)" == x86_64 ]]
[[ "$(sw_vers -buildVersion)" == 25G342 ]]
[[ -d "$ROOT/HostGraphics/Library/Extensions/NVAccel.kext" ]]
[[ -d "$ROOT/HostGraphics/Library/GPUBundles/NVMTLDriver.bundle" ]]
[[ -d "$ROOT/HostGraphics/Library/NullMoth/nvfw/nvidia/620.70.06" ]]
[[ -d "$ROOT/HostAudio/Lenovo83ALDmic.driver" ]]

sudo -v
for name in NVRM.kext NVAccel.kext NVRMFB.kext NVRMAGDC.kext NMIntelFB.kext; do
    [[ -d "$ROOT/HostGraphics/Library/Extensions/$name" ]]
    sudo ditto "$ROOT/HostGraphics/Library/Extensions/$name" "/Library/Extensions/$name"
    sudo chown -R root:wheel "/Library/Extensions/$name"
    sudo chmod -R go-w "/Library/Extensions/$name"
done

sudo ditto "$ROOT/HostGraphics/Library/GPUBundles/NVMTLDriver.bundle" /Library/GPUBundles/NVMTLDriver.bundle
sudo chown -R root:wheel /Library/GPUBundles/NVMTLDriver.bundle
sudo chmod -R go-w /Library/GPUBundles/NVMTLDriver.bundle
if [[ -d "$ROOT/HostGraphics/Library/GPUBundles/nvmtl" ]]; then
    sudo ditto "$ROOT/HostGraphics/Library/GPUBundles/nvmtl" /Library/GPUBundles/nvmtl
    sudo chown -R root:wheel /Library/GPUBundles/nvmtl
    sudo chmod -R go-w /Library/GPUBundles/nvmtl
fi

sudo mkdir -p /Library/NullMoth/nvfw/nvidia
sudo ditto "$ROOT/HostGraphics/Library/NullMoth/nvfw/nvidia/620.70.06" /Library/NullMoth/nvfw/nvidia/620.70.06
sudo chown -R root:wheel /Library/NullMoth/nvfw/nvidia/620.70.06
sudo chmod -R go-w /Library/NullMoth/nvfw/nvidia/620.70.06
if [[ -d "$ROOT/HostGraphics/Library/NullMoth/licenses" ]]; then
    sudo ditto "$ROOT/HostGraphics/Library/NullMoth/licenses" /Library/NullMoth/licenses
fi

sudo mkdir -p /Library/Audio/Plug-Ins/HAL
sudo ditto "$ROOT/HostAudio/Lenovo83ALDmic.driver" /Library/Audio/Plug-Ins/HAL/Lenovo83ALDmic.driver
sudo chown -R root:wheel /Library/Audio/Plug-Ins/HAL/Lenovo83ALDmic.driver
sudo chmod -R go-w /Library/Audio/Plug-Ins/HAL/Lenovo83ALDmic.driver

TMP=$(mktemp -d /private/tmp/Lenovo83AL-auxkc.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
KC="$TMP/AuxiliaryKernelExtensions.kc"
ARGS=(--allow-missing-kdk -a x86_64)
if [[ -s /System/Library/KernelCollections/SystemKernelExtensions.kc ]]; then
    ARGS+=(-S /System/Library/KernelCollections/SystemKernelExtensions.kc)
fi
if [[ -f /System/Library/Kernels/kernel ]]; then
    ARGS+=(--kernel /System/Library/Kernels/kernel)
fi
sudo kmutil create -n aux --volume-root / "${ARGS[@]}" \
    -B /System/Library/KernelCollections/BootKernelExtensions.kc \
    --repository /Library/Extensions \
    -p /Library/Extensions/NVRM.kext \
    -p /Library/Extensions/NVAccel.kext \
    -p /Library/Extensions/NVRMFB.kext \
    -p /Library/Extensions/NVRMAGDC.kext \
    -p /Library/Extensions/NMIntelFB.kext \
    -A "$KC" -z
sudo ditto "$KC" /Library/KernelCollections/AuxiliaryKernelExtensions.kc

echo 'HOST_COMPONENTS_INSTALLED=YES'
echo 'AuxKC 已在当前电脑重新生成；没有修改 EFI 或 NVRAM。'
echo '请关机后再开机；不要直接热卸载当前显示或音频驱动。'
