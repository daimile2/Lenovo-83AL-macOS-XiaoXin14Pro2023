#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
sdk="$(xcrun --show-sdk-path)"
kernel="$sdk/System/Library/Frameworks/Kernel.framework/Headers"
project="$PWD"
mkdir -p "$project/build/Lenovo83ALDmic.kext/Contents/MacOS" "$project/build/Lenovo83ALDmic.driver/Contents/MacOS"
python3 - <<'PY'
from pathlib import Path
p=Path('kext/Lenovo83ALDmic/kmod_info.c')
p.write_text('''#include <mach/mach_types.h>
kern_return_t Lenovo83ALDmic_start(kmod_info_t *ki, void *data) { return KERN_SUCCESS; }
kern_return_t Lenovo83ALDmic_stop(kmod_info_t *ki, void *data) { return KERN_SUCCESS; }
KMOD_EXPLICIT_DECL(com.tarekwasfy.Lenovo83ALDmic, "0.1.0", Lenovo83ALDmic_start, Lenovo83ALDmic_stop)
''')
Path('firmware-embed.s').write_text('''.section __DATA,__lenovo_sof_fw
.globl _kSofRplRi
.globl _kSofRplRiSize
_kSofRplRi:
.incbin "firmware/sof-rpl.ri"
_lenovosof_fw_end:
.section __DATA,__lenovo_sof_sz
_kSofRplRiSize:
.long _lenovosof_fw_end - _kSofRplRi
''')
PY
common=(-arch x86_64 -target x86_64-apple-macos14.0 -isysroot "$sdk" -I"$kernel" -I"$kernel/IOKit"
    -I"$project/kext/Lenovo83ALDmic" -mkernel -nostdlib -fno-builtin -fno-common -fno-stack-protector
    -DKERNEL -DKERNEL_PRIVATE -DDRIVER_PRIVATE -DAPPLE -DNeXT -D__MACOSX__ -O2 -Wall
    -Wno-inconsistent-missing-override -Wno-deprecated-declarations)
for name in Lenovo83ALDmic DspBoot Capture Lenovo83ALDmicUserClient; do
    xcrun clang++ "${common[@]}" -std=c++17 -fno-exceptions -fno-rtti \
        -c "$project/kext/Lenovo83ALDmic/$name.cpp" -o "$project/build/$name.o"
done
xcrun clang "${common[@]}" -c "$project/kext/Lenovo83ALDmic/kmod_info.c" -o "$project/build/kmod_info.o"
xcrun clang -arch x86_64 -target x86_64-apple-macos14.0 -c "$project/firmware-embed.s" -o "$project/build/Firmware.o"
xcrun clang++ -arch x86_64 -target x86_64-apple-macos14.0 -isysroot "$sdk" -nostdlib -Xlinker -kext -lcc_kext \
    "$project/build/Lenovo83ALDmic.o" "$project/build/DspBoot.o" "$project/build/Capture.o" \
    "$project/build/Lenovo83ALDmicUserClient.o" "$project/build/Firmware.o" "$project/build/kmod_info.o" \
    -o "$project/build/Lenovo83ALDmic.kext/Contents/MacOS/Lenovo83ALDmic"
cp "$project/kext/Lenovo83ALDmic/Info.plist" "$project/build/Lenovo83ALDmic.kext/Contents/Info.plist"
xcrun clang++ -arch x86_64 -mmacosx-version-min=14.0 -std=c++17 -O2 -Wall -Wextra -Wno-unused-parameter \
    -bundle "$project/hal/Lenovo83ALDmicDriver.cpp" -framework CoreAudio -framework CoreFoundation -framework IOKit \
    -o "$project/build/Lenovo83ALDmic.driver/Contents/MacOS/Lenovo83ALDmic"
cp "$project/hal/Info.plist" "$project/build/Lenovo83ALDmic.driver/Contents/Info.plist"
for name in Lenovo83ALDmic.kext Lenovo83ALDmic.driver; do
    mkdir -p "$project/build/$name/Contents/Resources"
    cp "$project/licenses/"* "$project/build/$name/Contents/Resources/"
    codesign --force --sign - --timestamp=none "$project/build/$name"
    codesign --verify --strict "$project/build/$name"
    plutil -lint "$project/build/$name/Contents/Info.plist"
done
python3 - <<'PY'
from pathlib import Path
import hashlib,json
b=Path('build')
manifest={}
for name in ['Lenovo83ALDmic.kext','Lenovo83ALDmic.driver']:
    manifest[name]={str(p.relative_to(b/name)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (b/name).rglob('*') if p.is_file()}
(b/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('Lenovo 83AL kext and CoreAudio plug-in built; no hardware verification claimed.')
PY
