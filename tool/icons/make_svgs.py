#!/usr/bin/env python3
"""Writes every Raindrop app-icon source from one definition of the mark.

Usage: make_svgs.py <out_dir> <icon_bundle_dir>

<out_dir> receives the flat SVGs that tool/icons/gen_icons.sh rasterises; <icon_bundle_dir>
is the Icon Composer document (AppIcon.icon) that Xcode 26+ compiles into the Liquid Glass
icon for iOS, iPadOS and macOS 26 and later. Change the shape or colours here, then rerun
gen_icons.sh. Nothing else in the repository should hold its own copy of the artwork.
"""
import json
import os
import sys

# The brand accent, the same seedColor as assets/themes/*.json.
ACCENT = "#4C6FFF"
BG_TOP, BG_BOTTOM = "#6F8BFF", "#3346D6"

# A raindrop that is also a speech bubble (its tail at the lower right), on a 1024 canvas.
DROP = (
    "M512 150 C452 250 276 420 276 600 C276 730 381 836 512 836 "
    "C548 836 582 828 612 814 L728 862 L702 748 "
    "C731 707 748 656 748 600 C748 420 572 250 512 150 Z"
)
DOTS = [(420, 610), (512, 610), (604, 610)]
DOT_R = 40
MARK_CENTER = (512, 506)  # centre of the mark's bounding box


def svg(body, defs=""):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
        f"<defs>{defs}</defs>\n{body}\n</svg>\n"
    )


def vgrad(gid, top, bottom):
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>')


BG_DEFS = (f'<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">'
           f'<stop offset="0" stop-color="{BG_TOP}"/><stop offset="1" stop-color="{BG_BOTTOM}"/></linearGradient>')
DOTS_SVG = "".join(f'<circle cx="{x}" cy="{y}" r="{DOT_R}" fill="{{c}}"/>' for x, y in DOTS)
DOTS_MASK = ('<mask id="cut"><rect width="1024" height="1024" fill="#fff"/>'
             + DOTS_SVG.replace("{c}", "#000") + "</mask>")


def scaled(body, s):
    """Scales the mark about its own centre and centres it on the canvas."""
    cx, cy = MARK_CENTER
    return (f'<g transform="translate(512 512) scale({s}) translate({-cx} {-cy})">{body}</g>')


def mark(drop_fill, dot_fill):
    return f'<path fill="{drop_fill}" d="{DROP}"/>' + DOTS_SVG.replace("{c}", dot_fill)


def mark_cutout(fill):
    """The drop alone with the dots punched through, for one-colour renditions."""
    return f'<path fill="{fill}" mask="url(#cut)" d="{DROP}"/>'


LIGHT_MARK = mark("url(#drop)", ACCENT)
LIGHT_DEFS = vgrad("drop", "#FFFFFF", "#E4E9FF")

files = {
    # Full-bleed square: Android legacy, the iOS < 18 fallback.
    "icon_full.svg": svg('<rect width="1024" height="1024" fill="url(#bg)"/>' + LIGHT_MARK,
                         BG_DEFS + LIGHT_DEFS),
    # macOS < 26: Apple's 824pt rounded rect inside the 1024 canvas.
    "icon_macos.svg": svg('<rect x="100" y="100" width="824" height="824" rx="185" fill="url(#bg)"/>'
                          + scaled(LIGHT_MARK, 0.805), BG_DEFS + LIGHT_DEFS),
    # Windows and Linux: a rounded square with a thin margin; also the scalable Linux icon.
    "icon_rounded.svg": svg('<rect x="32" y="32" width="960" height="960" rx="216" fill="url(#bg)"/>'
                            + scaled(LIGHT_MARK, 0.9375), BG_DEFS + LIGHT_DEFS),
    # iOS 18-25 dark appearance: transparent, the system draws the dark backdrop.
    "icon_ios_dark.svg": svg(mark("url(#drop)", "#2F45C8"), vgrad("drop", "#E3E9FF", "#94A8FF")),
    # iOS 18-25 tinted appearance: greyscale on black, the system applies the tint.
    "icon_ios_tinted.svg": svg('<rect width="1024" height="1024" fill="#000"/>'
                               + mark_cutout("url(#drop)"),
                               vgrad("drop", "#FFFFFF", "#B8B8B8") + DOTS_MASK),
    # Android adaptive icon (API 26+): 108dp layers, the mark inside the 66dp safe circle.
    "android_background.svg": svg('<rect width="1024" height="1024" fill="url(#bg)"/>', BG_DEFS),
    "android_foreground.svg": svg(scaled(LIGHT_MARK, 0.72), LIGHT_DEFS),
    # Android 13+ themed icon: one colour, the launcher tints it.
    "android_monochrome.svg": svg(scaled(mark_cutout("#FFFFFF"), 0.72), DOTS_MASK),
}

# Icon Composer layers: the drop and the dots separately, so Liquid Glass gives them depth.
icon_layers = {
    "drop.svg": svg(f'<path fill="#FFFFFF" d="{DROP}"/>'),
    "dots.svg": svg(DOTS_SVG.replace("{c}", ACCENT)),
}


def p3(hex_color):
    r, g, b = (int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return f"srgb:{r:.5f},{g:.5f},{b:.5f},1.00000"


icon_json = {
    "fill": {"linear-gradient": [p3(BG_TOP), p3(BG_BOTTOM)]},
    "groups": [
        {
            "layers": [
                {
                    "image-name": "dots.svg",
                    "name": "dots",
                    # On the dark and tinted backdrops the drop turns dark, so the dots go light.
                    "fill-specializations": [
                        {"appearance": "dark", "value": {"solid": p3("#FFFFFF")}},
                        {"appearance": "tinted", "value": {"solid": p3("#FFFFFF")}},
                    ],
                },
                {"image-name": "drop.svg", "name": "drop"},
            ],
            "position": {"scale": 0.88, "translation-in-points": [0, 0]},
            "shadow": {"kind": "neutral", "opacity": 0.5},
            "translucency": {"enabled": True, "value": 0.4},
        }
    ],
    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
}


def write(path, text):
    with open(path, "w") as f:
        f.write(text)


def main():
    out_dir, bundle = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    for name, text in files.items():
        write(os.path.join(out_dir, name), text)
    os.makedirs(os.path.join(bundle, "Assets"), exist_ok=True)
    for name, text in icon_layers.items():
        write(os.path.join(bundle, "Assets", name), text)
    write(os.path.join(bundle, "icon.json"), json.dumps(icon_json, indent=2) + "\n")


if __name__ == "__main__":
    main()
