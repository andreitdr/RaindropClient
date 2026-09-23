#!/usr/bin/env bash
# Copies every shared library the Flutter Linux bundle needs but a stock desktop doesn't reliably
# have (libmpv and its whole chain, libsecret, PulseAudio, ...) into <bundle>/lib, so the app runs
# on a machine with nothing installed except a desktop session.
#
# Usage: bundle-libs.sh <path to build/linux/x64/release/bundle>
#
# Libraries every desktop already has, or that must match the host's graphics/display stack (glibc,
# GTK and its friends, OpenGL, X11/Wayland, fontconfig, ...), are deliberately left out: bundling them
# breaks more than it fixes. The bundle is therefore built on an older Ubuntu (glibc floor), see release.yml.

set -euo pipefail

BUNDLE="$(cd "$1" && pwd)"
LIB="$BUNDLE/lib"

EXCLUDE='^(ld-linux.*|linux-vdso|libc|libm|libdl|libpthread|librt|libutil|libresolv|libnsl|libcrypt|libgcc_s|libstdc\+\+'
EXCLUDE+='|libGL|libGLX|libGLdispatch|libEGL|libGLESv2|libOpenGL|libgbm|libdrm|libepoxy'
EXCLUDE+='|libX[a-zA-Z0-9]*|libxcb[a-z0-9-]*|libxkbcommon|libwayland-[a-z]+|libxshmfence'
EXCLUDE+='|libgtk-3|libgdk-3|libgdk_pixbuf-2\.0|libglib-2\.0|libgobject-2\.0|libgio-2\.0|libgmodule-2\.0|libgthread-2\.0'
EXCLUDE+='|libpango-1\.0|libpangocairo-1\.0|libpangoft2-1\.0|libcairo|libcairo-gobject|libatk-1\.0|libatk-bridge-2\.0|libatspi'
EXCLUDE+='|libharfbuzz|libfontconfig|libfreetype|libfribidi|libpixman-1|libpng16|libjpeg|libtiff|libexpat|libz|libffi'
EXCLUDE+='|libpcre2-8|libpcre|libmount|libblkid|libuuid|libselinux|libsystemd|libdbus-1|libudev|libasound|libcap'
EXCLUDE+='|libgcrypt|libgpg-error|libthai|libdatrie|libcom_err|libgssapi_krb5|libkrb5|libk5crypto|libkeyutils|libcups)(\.|-).*'

declare -A SEEN
queue=("$BUNDLE"/raindrop_client "$LIB"/*.so*)

# Resolve a library soname: the bundle first, then the system's linker cache.
resolve() {
    local name="$1"
    if [ -e "$LIB/$name" ]; then echo "$LIB/$name"; return; fi
    /sbin/ldconfig -p | awk -v n="$name" '$1 == n && /x86-64/ { print $NF; exit }'
}

while [ "${#queue[@]}" -gt 0 ]; do
    file="${queue[0]}"; queue=("${queue[@]:1}")
    for need in $(readelf -d "$file" 2>/dev/null | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p'); do
        [ -n "${SEEN[$need]:-}" ] && continue
        SEEN[$need]=1
        [[ "$need" =~ $EXCLUDE ]] && continue
        path="$(resolve "$need")"
        if [ -z "$path" ]; then
            echo "warning: cannot find $need (needed by $(basename "$file"))" >&2
            continue
        fi
        if [ ! -e "$LIB/$need" ]; then
            cp -L "$path" "$LIB/$need"
            echo "bundled $need"
        fi
        queue+=("$LIB/$need")
    done
done

# Every library looks for its siblings next to itself, so no LD_LIBRARY_PATH is needed at run time.
for so in "$LIB"/*.so*; do
    patchelf --set-rpath '$ORIGIN' "$so"
done
echo "Bundled libraries into $LIB"
