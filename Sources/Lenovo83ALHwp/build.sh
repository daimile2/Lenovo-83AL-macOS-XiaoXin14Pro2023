#!/bin/bash
# Offline build for Lenovo83ALHwp.kext. No sudo and no system installation.
set -euo pipefail
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SRC="$ROOT/src"
BUILD="$ROOT/build"
DEPS="$BUILD/deps"
OUT="$BUILD/Lenovo83ALHwp.kext"
NAME='Lenovo83ALHwp'
BID='org.lenovo83al.hwp'
VER='0.2.0'

[[ "$(uname -s)" == Darwin ]] || { echo '请在 macOS 中构建' >&2; exit 1; }
command -v clang >/dev/null && command -v clang++ >/dev/null || { echo '需要 Xcode Command Line Tools' >&2; exit 1; }

hash_of() { /usr/bin/shasum -a 256 "$1" | /usr/bin/awk '{print $1}'; }
check_archive() {
    [[ -f "$1" ]] || { echo "缺少离线依赖：$1" >&2; exit 1; }
    [[ "$(hash_of "$1")" == "$2" ]] || { echo "依赖哈希不匹配：$1" >&2; exit 1; }
}
check_archive "$ROOT/deps/MacKernelSDK.tar.gz" '7ec8b20b137e030d0036ff2f76d21cceaff26f06b47592c1cbe66530b81035f8'
check_archive "$ROOT/deps/Lilu-1.7.2-DEBUG.zip" 'e95df95d82e8b151047abf359ecd9c853755c59293e19dfcc3907da8fbd8cf89'

rm -rf "$BUILD"
mkdir -p "$DEPS"
tar -xzf "$ROOT/deps/MacKernelSDK.tar.gz" -C "$DEPS"
mv "$DEPS/MacKernelSDK-master" "$DEPS/MacKernelSDK"
unzip -q "$ROOT/deps/Lilu-1.7.2-DEBUG.zip" -d "$DEPS"
SDK="$DEPS/MacKernelSDK"
LILU="$DEPS/Lilu.kext/Contents/Resources"
[[ -f "$SDK/Library/x86_64/libkmod.a" && -f "$LILU/Library/plugin_start.cpp" ]]
plutil -lint "$SRC/Info.plist" >/dev/null

TMP="$(mktemp -d /tmp/l83-hwp-build.XXXXXX)"
trap '/bin/rm -rf "$TMP"' EXIT
mkdir -p "$OUT/Contents/MacOS"
cp "$SRC/Info.plist" "$OUT/Contents/Info.plist"

FLAGS=(-arch x86_64 -mkernel -nostdinc -fno-builtin -fno-common -fno-stack-protector
       -mmacosx-version-min=13.0 -mmmx -msse -msse2
       -DKERNEL -DKERNEL_PRIVATE -DDRIVER_PRIVATE -DAPPLE -DNeXT
       -DDEBUG=1 -DAPPLE_KEXT_ASSERTIONS=1 -DPRODUCT_NAME=$NAME -DMODULE_VERSION=$VER
       -isystem "$SDK/Headers" -I"$LILU" -I"$SRC" -O2 -g)

cat > "$TMP/info.c" <<EOC
#include <mach/mach_types.h>
extern kern_return_t ${NAME}_kern_start(kmod_info_t *ki, void *data);
extern kern_return_t ${NAME}_kern_stop(kmod_info_t *ki, void *data);
__attribute__((visibility("default"))) KMOD_EXPLICIT_DECL($BID, "$VER", ${NAME}_kern_start, ${NAME}_kern_stop)
__private_extern__ kmod_start_func_t *_realmain = 0;
__private_extern__ kmod_stop_func_t *_antimain = 0;
__private_extern__ int _kext_apple_cc = __APPLE_CC__;
EOC
clang "${FLAGS[@]}" -c "$TMP/info.c" -o "$TMP/info.o"
for source in kern_start kern_hwp; do
    clang++ "${FLAGS[@]}" -std=gnu++17 -nostdinc++ -fno-exceptions -fno-rtti -fapple-kext \
        -Wall -Wextra -Wno-deprecated-declarations -Wno-unused-parameter \
        -c "$SRC/$source.cpp" -o "$TMP/$source.o"
done
clang++ "${FLAGS[@]}" -std=gnu++17 -nostdinc++ -fno-exceptions -fno-rtti -fapple-kext \
    -Wno-deprecated-declarations -c "$LILU/Library/plugin_start.cpp" -o "$TMP/plugin_start.o"
clang++ -arch x86_64 -mkernel -nostdlib -static -Xlinker -kext -Xlinker -export_dynamic \
    -mmacosx-version-min=13.0 "$TMP"/*.o "$SDK/Library/x86_64/libkmod.a" -lcc_kext \
    -o "$OUT/Contents/MacOS/$NAME"
codesign -f -s - "$OUT" >/dev/null 2>&1
codesign --verify --strict "$OUT"
plutil -lint "$OUT/Contents/Info.plist" >/dev/null
file "$OUT/Contents/MacOS/$NAME"

echo "KEXT=$OUT"
echo "Info.plist SHA256=$(hash_of "$OUT/Contents/Info.plist")"
echo "Executable SHA256=$(hash_of "$OUT/Contents/MacOS/$NAME")"
echo 'BUILD_PASS: offline dependencies and kext link completed.'
