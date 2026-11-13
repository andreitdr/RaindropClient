#!/usr/bin/env bash
# Regenerates every app icon from tool/icons/make_svgs.py. Run from anywhere, on macOS
# (it rasterises with AppKit through swift, and checks the Liquid Glass icon with Xcode's
# ictool). The outputs are committed, so nothing has to run before a build:
#
#   assets/icon/*.svg                       the flat sources (and Linux's scalable icon)
#   ios/Runner/AppIcon.icon                 Liquid Glass, iOS/iPadOS 26+ (Xcode compiles it)
#   macos/Runner/AppIcon.icon               Liquid Glass, macOS 26+
#   ios/.../AppIcon.appiconset              iOS/iPadOS 15-25: light, dark and tinted, 1024 single-size
#   macos/.../AppIcon.appiconset            macOS 11-25
#   android/.../mipmap-anydpi-v26           adaptive icon: background, foreground, monochrome
#   android/.../mipmap-*/ic_launcher.png    legacy launchers
#   windows/runner/resources/app_icon.ico   16-256px
#   packaging/linux/raindrop.{png,svg}      hicolor 512px and scalable
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$ROOT/tool/icons"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$ROOT"

SRC=assets/icon
python3 -I "$HERE/make_svgs.py" "$SRC" "$WORK/AppIcon.icon"

# Both Apple projects get their own copy of the Icon Composer document: each Runner folder is
# its own Xcode project, and a reference outside it would break the other platform's checkout.
for p in ios macos; do
  rm -rf "$p/Runner/AppIcon.icon"
  cp -R "$WORK/AppIcon.icon" "$p/Runner/AppIcon.icon"
done

ICTOOL="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
if [ -x "$ICTOOL" ]; then
  "$ICTOOL" "$WORK/AppIcon.icon" --export-image --output-file "$WORK/check.png" \
    --platform iOS --rendition Default --width 64 --height 64 --scale 1 >/dev/null
else
  echo "warning: Icon Composer's ictool not found; AppIcon.icon was not checked" >&2
fi

swiftc -O "$HERE/render.swift" -o "$WORK/render"
render() { "$WORK/render" "$SRC/$1" "$2" "$3" ${4:-}; }

# macOS 11-25.
for s in 16 32 64 128 256 512 1024; do
  render icon_macos.svg "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$s.png" "$s"
done

# iOS/iPadOS 15-25: one 1024 image per appearance; Xcode derives every size and idiom.
SET=ios/Runner/Assets.xcassets/AppIcon.appiconset
rm -f "$SET"/*.png
render icon_full.svg "$SET/AppIcon.png" 1024 opaque
render icon_ios_dark.svg "$SET/AppIcon-Dark.png" 1024
render icon_ios_tinted.svg "$SET/AppIcon-Tinted.png" 1024 opaque
cp "$HERE/ios-appiconset.json" "$SET/Contents.json"

# Android: adaptive layers at 108dp, and the legacy square at 48dp.
RES=android/app/src/main/res
for d in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  dir="$RES/mipmap-${d%%:*}"; f="${d##*:}"
  px() { python3 -c "print(round($1 * $f))"; }
  mkdir -p "$dir"
  render icon_full.svg "$dir/ic_launcher.png" "$(px 48)"
  render android_background.svg "$dir/ic_launcher_background.png" "$(px 108)"
  render android_foreground.svg "$dir/ic_launcher_foreground.png" "$(px 108)"
  render android_monochrome.svg "$dir/ic_launcher_monochrome.png" "$(px 108)"
done
mkdir -p "$RES/mipmap-anydpi-v26"
cp "$HERE/ic_launcher.xml" "$RES/mipmap-anydpi-v26/ic_launcher.xml"

# Windows.
mkdir -p "$WORK/ico"
for s in 16 24 32 48 64 128 256; do render icon_rounded.svg "$WORK/ico/$s.png" "$s"; done
python3 -I "$HERE/make_ico.py" windows/runner/resources/app_icon.ico "$WORK"/ico/{16,24,32,48,64,128,256}.png

# Linux.
render icon_rounded.svg packaging/linux/raindrop.png 512
cp "$SRC/icon_rounded.svg" packaging/linux/raindrop.svg

echo "Icons regenerated."
