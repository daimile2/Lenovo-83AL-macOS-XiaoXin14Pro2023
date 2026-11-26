#!/bin/bash
# Lenovo 83AL only. Creates an Apple Recovery installation USB and optionally installs OpenCore to the internal ESP.
# Does not install host graphics components, the DMIC HAL, or an AuxKC.
set -e
export LC_ALL=C
export LANG=C

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo '请用 sudo bash Tools/Linux/Lenovo83AL-EFI工具.sh 运行。'
    exit 1
fi
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO=$(CDPATH= cd -- "$HERE/../.." && pwd)
[[ -f "$REPO/EFI/OC/config.plist" ]]
[[ -f "$REPO/EFI/OC/OpenCore.efi" ]]
[[ -f "$REPO/Tools/macserial/macserial.linux" ]]
for cmd in python3 lsblk blkid mount umount mountpoint awk; do
    command -v "$cmd" >/dev/null || { echo "缺少命令：$cmd"; exit 1; }
done

printf '\033[31m数据无价，看好分区再分盘安装；分盘操作不能反悔，且分完盘数据丢失在软件上不可能找回（作者个人经历）。\033[0m\n'
echo '仅适用于 Lenovo 83AL／小新 Pro 14 2023 IRH8，不是通用引导。'
echo '安装 U 盘使用 Apple 官方 Recovery，制作和安装 macOS 时都需要网络。'
read -rp '选择：1=制作macOS安装U盘，2=安装OpenCore到内部ESP，3=两者都做：' ACTION
[[ "$ACTION" == 1 || "$ACTION" == 2 || "$ACTION" == 3 ]] || { echo '无效选择。'; exit 1; }
if [[ "$ACTION" == 1 || "$ACTION" == 3 ]]; then
    [[ -f "$REPO/Tools/macrecovery/macrecovery.py" ]] || { echo '缺少 Tools/macrecovery/macrecovery.py'; exit 1; }
    for cmd in wipefs parted mkfs.vfat partprobe; do
        command -v "$cmd" >/dev/null || { echo "缺少命令：$cmd"; exit 1; }
    done
fi

ESP=
if [[ "$ACTION" == 2 || "$ACTION" == 3 ]]; then
    command -v getent >/dev/null || { echo '缺少命令：getent'; exit 1; }
    echo '内部 GPT EFI 系统分区：'
    lsblk -pn -o NAME,PARTTYPE,FSTYPE,LABEL,SIZE,MOUNTPOINTS | awk 'BEGIN{IGNORECASE=1} $2=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print}'
    read -rp '输入内部 ESP 设备（例如 /dev/nvme0n1p1 或 /dev/sda1）：' ESP
    [[ -b "$ESP" ]] || { echo '不是块设备。'; exit 1; }
    PARTTYPE=$(blkid -s PARTTYPE -o value "$ESP" | tr 'A-F' 'a-f')
    [[ "$PARTTYPE" == c12a7328-f81f-11d2-ba4b-00a0c93ec93b ]] || { echo '所选分区不是 GPT EFI 系统分区。'; exit 1; }
fi

TMP=$(mktemp -d /tmp/Lenovo83AL-Installer.XXXXXX)
USB_MNT="$TMP/usb"
INT_MNT="$TMP/internal"
mkdir -p "$USB_MNT" "$INT_MNT" "$TMP/EFI/Boot"
cleanup() {
    mountpoint -q "$USB_MNT" && umount "$USB_MNT" || true
    mountpoint -q "$INT_MNT" && umount "$INT_MNT" || true
    # If unmounting ever fails, do not recursively delete through a mounted ESP or USB.
    rm -rf --one-file-system "$TMP"
}
trap cleanup EXIT

# Public deployment contains OpenCore only: no publisher rEFInd or Ubuntu files.
cp -a "$REPO/EFI/OC" "$TMP/EFI/OC"
cp "$TMP/EFI/OC/OpenCore.efi" "$TMP/EFI/Boot/BOOTX64.EFI"

cp "$REPO/Tools/macserial/macserial.linux" "$TMP/macserial"
chmod +x "$TMP/macserial"
PAIR=$("$TMP/macserial" -g -m MacBookPro16,2 -n 1 2>/dev/null | awk -F'|' '/\|/{print;exit}')
[[ -n "$PAIR" ]] || { echo 'macserial 未能生成 SMBIOS。'; exit 1; }
SERIAL=$(printf '%s' "$PAIR" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$1);print $1}')
MLB=$(printf '%s' "$PAIR" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$2);print $2}')

SERIAL="$SERIAL" MLB="$MLB" CONFIG="$TMP/EFI/OC/config.plist" python3 - <<'PY'
import os, plistlib, uuid
from pathlib import Path
p=Path(os.environ['CONFIG'])
c=plistlib.load(p.open('rb'))
g=c['PlatformInfo']['Generic']
g['SystemProductName']='MacBookPro16,2'
g['SystemSerialNumber']=os.environ['SERIAL']
g['MLB']=os.environ['MLB']
g['SystemUUID']=str(uuid.uuid4()).upper()
g['ROM']=os.urandom(6)
# Allow OpenCore to show the USB Apple Recovery entry in its boot picker.
c['Misc']['Security']['ScanPolicy']=0
p.write_bytes(plistlib.dumps(c,fmt=plistlib.FMT_XML,sort_keys=False))
PY

echo '个人 SMBIOS 已写入临时副本；公开仓库未被修改。'

if [[ "$ACTION" == 1 || "$ACTION" == 3 ]]; then
    lsblk -dn -o NAME,PATH,SIZE,TYPE,TRAN,MODEL | awk '$4=="disk" && $5=="usb" {print}'
    read -rp '输入要完全擦除的 USB 整盘设备（例如 /dev/sdb，不要填分区）：' USB
    [[ -b "$USB" ]] || { echo 'USB 不是块设备。'; exit 1; }
    [[ "$(lsblk -dn -o TYPE "$USB")" == disk ]] || { echo '必须输入整盘设备。'; exit 1; }
    [[ "$(lsblk -dn -o TRAN "$USB")" == usb ]] || { echo '目标不是 USB 总线磁盘，拒绝擦除。'; exit 1; }
    read -rp "将擦除 $USB 全部分区；输入 ERASE 继续：" CONFIRM
    [[ "$CONFIRM" == ERASE ]] || { echo '已取消，未擦除。'; exit 1; }
    wipefs -a "$USB"
    parted -s "$USB" mklabel gpt mkpart L83INSTALL fat32 1MiB 4097MiB set 1 esp on
    partprobe "$USB"
    udevadm settle 2>/dev/null || true
    sleep 1
    USBPART=$(lsblk -lnpo NAME,TYPE "$USB" | awk '$2=="part"{print $1;exit}')
    [[ -n "$USBPART" ]] || { echo '未找到新 USB 分区。'; exit 1; }
    mkfs.vfat -F 32 -n L83INSTALL "$USBPART"
    mount "$USBPART" "$USB_MNT"
    # FAT32 cannot preserve Unix ownership or permissions; do not use cp -a here.
    cp -R "$TMP/EFI" "$USB_MNT/"
    echo '正在从 Apple 下载并校验 MacBookPro16,2 最新 Recovery，请保持网络连接。'
    python3 "$REPO/Tools/macrecovery/macrecovery.py" \
        -b Mac-5F9802EFE386AA28 \
        -m 00000000000000000 \
        -os latest \
        -n BaseSystem \
        -o "$USB_MNT/com.apple.recovery.boot" \
        download
    sync
    umount "$USB_MNT"
    echo "macOS 联网安装 U 盘完成：$USBPART。通过开机启动菜单选择它，再进入 Recovery 安装。"
fi

if [[ "$ACTION" == 2 || "$ACTION" == 3 ]]; then
    mount "$ESP" "$INT_MNT"
    REAL_USER=${SUDO_USER:-$(id -un)}
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    [[ -n "$REAL_HOME" ]] || REAL_HOME=/root
    BACKUP="$REAL_HOME/Lenovo83AL-OpenCore原配置备份-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP"
    [[ ! -e "$INT_MNT/EFI/OC" ]] || cp -a "$INT_MNT/EFI/OC" "$BACKUP/"
    if [[ -f "$INT_MNT/EFI/Boot/BOOTX64.EFI" || -f "$INT_MNT/EFI/Boot/bootx64.efi" ]]; then
        mkdir -p "$BACKUP/Boot"
        cp -a "$INT_MNT/EFI/Boot/"[Bb][Oo][Oo][Tt][Xx]64.[Ee][Ff][Ii] "$BACKUP/Boot/" 2>/dev/null || true
    fi
    REAL_GROUP=$(id -gn "$REAL_USER")
    chown -R "$REAL_USER:$REAL_GROUP" "$BACKUP"
    # Replace only OC and the fallback boot file after backup. Other users' boot directories stay untouched.
    rm -rf "$INT_MNT/EFI/OC"
    mkdir -p "$INT_MNT/EFI/Boot"
    cp -R "$TMP/EFI/OC" "$INT_MNT/EFI/"
    cp "$TMP/EFI/Boot/BOOTX64.EFI" "$INT_MNT/EFI/Boot/BOOTX64.EFI"
    sync
    umount "$INT_MNT"
    echo "内部 ESP 的 OpenCore 已更新：$ESP"
    echo "原配置备份：$BACKUP"
    echo '其他启动目录未被复制或删除；没有重置或重建 NVRAM 启动项。'
fi

echo '安装 macOS 后运行 Tools/安装主机端组件.sh，安装显卡、双麦 HAL 并重建 AuxKC。'
