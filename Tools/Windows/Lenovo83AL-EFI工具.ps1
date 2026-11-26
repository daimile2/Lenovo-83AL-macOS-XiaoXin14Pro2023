#Requires -RunAsAdministrator
# Lenovo 83AL only. Creates an Apple Recovery installation USB and optionally installs OpenCore to the internal ESP.
# Does not install host graphics components, the DMIC HAL, or an AuxKC.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$EfiSource = Join-Path $RepoRoot 'EFI'
$Macserial = Join-Path $RepoRoot 'Tools\macserial\macserial.exe'
$Macrecovery = Join-Path $RepoRoot 'Tools\macrecovery\macrecovery.py'
if (-not (Test-Path (Join-Path $EfiSource 'OC\config.plist'))) { throw '未找到仓库 EFI/OC/config.plist。' }
if (-not (Test-Path (Join-Path $EfiSource 'OC\OpenCore.efi'))) { throw '未找到仓库 EFI/OC/OpenCore.efi。' }
if (-not (Test-Path $Macserial)) { throw '未找到 Tools/macserial/macserial.exe。' }

Write-Host '数据无价，看好分区再分盘安装；分盘操作不能反悔，且分完盘数据丢失在软件上不可能找回（作者个人经历）。' -ForegroundColor Red
Write-Host '仅适用于 Lenovo 83AL／小新 Pro 14 2023 IRH8，不是通用引导。'
Write-Host '安装 U 盘使用 Apple 官方 Recovery，制作和安装 macOS 时都需要网络。'
$action = Read-Host '选择：1=制作macOS安装U盘，2=安装OpenCore到内部ESP，3=两者都做'
if ($action -notin @('1','2','3')) { throw '无效选择。' }
if ($action -in @('1','3') -and -not (Test-Path $Macrecovery)) { throw '未找到 Tools/macrecovery/macrecovery.py。' }

function Select-InternalEsp {
    $items = @()
    foreach ($part in (Get-Partition)) {
        if ($part.Type -ne 'System') { continue }
        $disk = Get-Disk -Number $part.DiskNumber
        if ($disk.BusType -eq 'USB') { continue }
        $items += [PSCustomObject]@{
            Disk = $part.DiskNumber
            Partition = $part.PartitionNumber
            SizeGB = [math]::Round($part.Size / 1GB, 2)
            Object = $part
        }
    }
    if ($items.Count -eq 0) { throw '没有找到内部 GPT EFI 系统分区。' }
    for ($i = 0; $i -lt $items.Count; $i++) {
        Write-Host ("[{0}] disk={1} partition={2} size={3}GB" -f $i,$items[$i].Disk,$items[$i].Partition,$items[$i].SizeGB)
    }
    $selected = [int](Read-Host '输入内部 ESP 前面的序号')
    if ($selected -lt 0 -or $selected -ge $items.Count) { throw '内部 ESP 序号无效。' }
    return $items[$selected]
}

$esp = $null
if ($action -in @('2','3')) { $esp = Select-InternalEsp }

$stage = Join-Path $env:TEMP ('Lenovo83AL-Installer-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
# Do not leave the generated private SMBIOS in TEMP after a terminating error.
trap {
    if ($stage -and (Test-Path $stage)) { Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue }
    throw $_
}
$stagedEfi = Join-Path $stage 'EFI'
New-Item -ItemType Directory -Path $stagedEfi | Out-Null
# Public deployment contains OpenCore only: no publisher rEFInd or Ubuntu files.
Copy-Item (Join-Path $EfiSource 'OC') -Destination $stagedEfi -Recurse -Force
$boot = Join-Path $stagedEfi 'Boot'
New-Item -ItemType Directory -Path $boot | Out-Null
Copy-Item (Join-Path $stagedEfi 'OC\OpenCore.efi') (Join-Path $boot 'BOOTX64.EFI') -Force

# Generate private SMBIOS values only in the staged copy.
$pairLine = & $Macserial -g -m MacBookPro16,2 -n 1 2>$null | Where-Object { $_ -match '\|' } | Select-Object -First 1
if (-not $pairLine) { throw 'macserial 未能生成 SMBIOS。' }
$pair = $pairLine -split '\s*\|\s*'
$serial = $pair[0].Trim()
$mlb = $pair[1].Trim()
$uuid = [guid]::NewGuid().ToString().ToUpperInvariant()
$rom = New-Object byte[] 6
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($rom)
$rng.Dispose()
$rom64 = [Convert]::ToBase64String($rom)

function Get-PlistChild($dict, [string]$keyName) {
    foreach ($node in $dict.ChildNodes) {
        if ($node.Name -eq 'key' -and $node.InnerText -eq $keyName) { return $node.NextSibling }
    }
    throw "config.plist 缺少字段：$keyName"
}

$config = Join-Path $stagedEfi 'OC\config.plist'
(Get-Item $config).IsReadOnly = $false
$doc = New-Object System.Xml.XmlDocument
$doc.PreserveWhitespace = $true
$doc.Load($config)
$rootDict = $doc.SelectSingleNode('/plist/dict')
$platform = Get-PlistChild $rootDict 'PlatformInfo'
$generic = Get-PlistChild $platform 'Generic'
(Get-PlistChild $generic 'SystemProductName').InnerText = 'MacBookPro16,2'
(Get-PlistChild $generic 'SystemSerialNumber').InnerText = $serial
(Get-PlistChild $generic 'MLB').InnerText = $mlb
(Get-PlistChild $generic 'SystemUUID').InnerText = $uuid
(Get-PlistChild $generic 'ROM').InnerText = $rom64
# Allow OpenCore to show the USB Apple Recovery entry in its boot picker.
$misc = Get-PlistChild $rootDict 'Misc'
$security = Get-PlistChild $misc 'Security'
(Get-PlistChild $security 'ScanPolicy').InnerText = '0'
$doc.Save($config)
Write-Host '个人 SMBIOS 已写入临时副本；公开仓库未被修改。'

if ($action -in @('1','3')) {
    Get-Disk | Where-Object BusType -eq 'USB' | Format-Table Number,FriendlyName,BusType,@{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}},IsBoot,IsSystem
    $usbNumber = [int](Read-Host '输入要完全擦除的 USB 磁盘编号')
    $usb = Get-Disk -Number $usbNumber
    if ($usb.BusType -ne 'USB' -or $usb.IsBoot -or $usb.IsSystem) { throw '目标不是可安全用于本工具的外部 USB 磁盘。' }
    $confirm = Read-Host "将擦除磁盘 $usbNumber 全部分区；输入 ERASE $usbNumber 继续"
    if ($confirm -ne "ERASE $usbNumber") { throw '已取消，未擦除。' }
    Clear-Disk -Number $usbNumber -RemoveData -RemoveOEM -Confirm:$false
    if ((Get-Disk -Number $usbNumber).PartitionStyle -eq 'RAW') { Initialize-Disk -Number $usbNumber -PartitionStyle GPT }
    $usbPart = New-Partition -DiskNumber $usbNumber -Size 4GB -AssignDriveLetter
    Format-Volume -Partition $usbPart -FileSystem FAT32 -NewFileSystemLabel 'L83INSTALL' -Confirm:$false | Out-Null
    $usbRoot = $usbPart.DriveLetter.ToString() + ':\'
    Copy-Item $stagedEfi -Destination $usbRoot -Recurse -Force
    $recoveryDir = Join-Path $usbRoot 'com.apple.recovery.boot'
    Write-Host '正在从 Apple 下载并校验 MacBookPro16,2 最新 Recovery，请保持网络连接。'
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        & $pyLauncher.Source -3 $Macrecovery -b Mac-5F9802EFE386AA28 -m 00000000000000000 -os latest -n BaseSystem -o $recoveryDir download
    } else {
        $python = Get-Command python -ErrorAction SilentlyContinue
        if (-not $python) { throw '制作安装 U 盘需要 Python 3；请安装后重新运行本脚本。' }
        & $python.Source $Macrecovery -b Mac-5F9802EFE386AA28 -m 00000000000000000 -os latest -n BaseSystem -o $recoveryDir download
    }
    if ($LASTEXITCODE -ne 0) { throw 'Apple Recovery 下载或校验失败。' }
    Write-Host "macOS 联网安装 U 盘完成：$usbRoot。通过开机启动菜单选择它，再进入 Recovery 安装。"
}

if ($action -in @('2','3')) {
    $part = $esp.Object
    if (-not $part.DriveLetter) {
        $letter = $null
        foreach ($candidate in (90..65)) {
            $c = [char]$candidate
            if (-not (Get-PSDrive -Name $c -ErrorAction SilentlyContinue)) { $letter = $c; break }
        }
        if (-not $letter) { throw '没有可用盘符挂载内部 ESP。' }
        Set-Partition -DiskNumber $part.DiskNumber -PartitionNumber $part.PartitionNumber -NewDriveLetter $letter
        $part = Get-Partition -DiskNumber $part.DiskNumber -PartitionNumber $part.PartitionNumber
    }
    $espRoot = $part.DriveLetter.ToString() + ':\'
    $desktop = [Environment]::GetFolderPath('Desktop')
    $backup = Join-Path $desktop ('Lenovo83AL-OpenCore原配置备份-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $backup | Out-Null
    $oldOC = Join-Path $espRoot 'EFI\OC'
    if (Test-Path $oldOC) { Copy-Item $oldOC -Destination $backup -Recurse -Force }
    $oldDefault = Join-Path $espRoot 'EFI\Boot\BOOTX64.EFI'
    if (Test-Path $oldDefault) {
        New-Item -ItemType Directory -Path (Join-Path $backup 'Boot') -Force | Out-Null
        Copy-Item $oldDefault -Destination (Join-Path $backup 'Boot') -Force
    }

    New-Item -ItemType Directory -Path (Join-Path $espRoot 'EFI') -Force | Out-Null
    # Replace only OC and the fallback boot file after backup. Other users' boot directories stay untouched.
    if (Test-Path $oldOC) { Remove-Item $oldOC -Recurse -Force }
    Copy-Item (Join-Path $stagedEfi 'OC') -Destination (Join-Path $espRoot 'EFI') -Recurse -Force
    New-Item -ItemType Directory -Path (Join-Path $espRoot 'EFI\Boot') -Force | Out-Null
    Copy-Item (Join-Path $stagedEfi 'Boot\BOOTX64.EFI') -Destination (Join-Path $espRoot 'EFI\Boot\BOOTX64.EFI') -Force
    Write-Host "内部 ESP 的 OpenCore 已更新：$espRoot"
    Write-Host "原配置备份：$backup"
    Write-Host '其他启动目录未被复制或删除；没有重置或重建 NVRAM 启动项。'
}

Write-Host '安装 macOS 后运行 Tools/安装主机端组件.sh，安装显卡、双麦 HAL 并重建 AuxKC。'
Remove-Item $stage -Recurse -Force
