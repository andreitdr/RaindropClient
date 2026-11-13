# App icon

The icon is a raindrop that is also a speech bubble, with three typing dots, on a gradient of the
themes' accent colour (`#4C6FFF`, the `seedColor` in `assets/themes/*.json`).

## One source, generated everywhere

The artwork is defined once, in [`tool/icons/make_svgs.py`](../tool/icons/make_svgs.py): the drop's
path, the dots, the colours, and how each platform's version is framed. Every icon file in the repository
is generated from it by:

```bash
tool/icons/gen_icons.sh
```

It runs on macOS only. It rasterises with AppKit through `swift` (`tool/icons/render.swift`), so it
needs no other image tools, and checks the Liquid Glass document with Xcode's `ictool`. Its outputs
are **committed**, like the generated gRPC code, so a build (local or CI) runs nothing first. To change
the icon, edit `make_svgs.py`, rerun the script, and commit everything it changed. Never edit a
generated file by hand: the next run overwrites it.

## What each platform gets

| Platform | Files | Adapts to |
|---|---|---|
| iOS / iPadOS 26+ | `ios/Runner/AppIcon.icon` (Icon Composer document) | Light, dark, clear and tinted Liquid Glass, rendered by the system |
| iOS / iPadOS 15–25 | `ios/Runner/Assets.xcassets/AppIcon.appiconset`: one 1024px image each for light, dark and tinted | Dark and tinted home screens (iOS 18+). Xcode derives every iPhone and iPad size |
| macOS 26+ | `macos/Runner/AppIcon.icon` | Light, dark, clear and tinted Liquid Glass |
| macOS 11–25 | `macos/Runner/Assets.xcassets/AppIcon.appiconset`, 16–1024px | — (inset on Apple's 824pt grid, with transparent margin) |
| Android 8+ | `mipmap-anydpi-v26/ic_launcher.xml` + `ic_launcher_{background,foreground,monochrome}.png` per density | Any launcher mask shape, parallax, and Android 13+ themed icons (the monochrome layer) |
| Android, legacy launchers | `mipmap-*/ic_launcher.png` | — |
| Windows | `windows/runner/resources/app_icon.ico`, 16–256px | — |
| Linux | `packaging/linux/raindrop.png` (512px) and `raindrop.svg` (scalable) | Any size; `build-packages.sh` installs both into `hicolor` |

Both Apple projects carry their own copy of `AppIcon.icon`, listed in each `project.pbxproj` under the
Runner's resources. When Xcode 26 or later builds the app, the `.icon` supplies the icon on OS 26+ and
the asset catalog of the same name (`AppIcon`) is the fallback for older systems.

The Android foreground keeps the mark inside the 66dp safe circle of the 108dp layer, so no launcher
mask clips it. The monochrome layer is the drop alone, with the dots cut through, because the launcher
tints it a single colour.
