"""Generates the app's raster assets: launcher icons and promo banners.

Run from the project root:  python3 tools/generate_assets.py
Everything is drawn from scratch (no third-party artwork) at 4x and
downsampled, so edges stay smooth.
"""

import json
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES = os.path.join(ROOT, "assets", "images")
ICON_DIR = os.path.join(ROOT, "assets", "icon")
FONT_BOLD = os.path.join(ROOT, "assets", "fonts", "Inter-Bold.ttf")

BRAND = (31, 85, 168)
BRAND_DEEP = (20, 53, 107)
SS = 4  # supersample factor


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def diagonal_gradient(size, start, end):
    """Top-left to bottom-right linear gradient."""
    w, h = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(h):
        for x in range(w):
            pixels[x, y] = lerp(start, end, (x / w + y / h) / 2)
    return image


def rounded_mask(size, radius):
    mask = Image.new("L", (size[0] * SS, size[1] * SS), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] * SS - 1, size[1] * SS - 1),
        radius=radius * SS,
        fill=255,
    )
    return mask.resize(size, Image.LANCZOS)


def soft_circles(image, circles):
    """Translucent decorative circles, drawn on an overlay layer."""
    w, h = image.size
    overlay = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for cx, cy, r, alpha in circles:
        box = (
            (cx - r) * w * SS,
            (cy - r) * h * SS,
            (cx + r) * w * SS,
            (cy + r) * h * SS,
        )
        draw.ellipse(box, fill=(255, 255, 255, alpha))
    overlay = overlay.resize((w, h), Image.LANCZOS)
    image.alpha_composite(overlay)


def banner(name, start, end, circles):
    size = (1200, 520)
    base = diagonal_gradient(size, start, end).convert("RGBA")
    soft_circles(base, circles)
    base.putalpha(rounded_mask(size, 56))
    path = os.path.join(IMAGES, name)
    base.save(path)
    print("wrote", os.path.relpath(path, ROOT))


def app_icon(size=1024, rounded=True):
    """Gradient tile with a white 'A' wordmark."""
    base = diagonal_gradient((size, size), (46, 112, 200), BRAND_DEEP).convert("RGBA")
    soft_circles(base, [(0.86, 0.14, 0.26, 16), (0.12, 0.9, 0.22, 13)])

    glyph = Image.new("RGBA", (size * 2, size * 2), (0, 0, 0, 0))
    font = ImageFont.truetype(FONT_BOLD, int(size * 1.02))
    draw = ImageDraw.Draw(glyph)
    draw.text(
        (size, size * 1.0),
        "A",
        font=font,
        fill=(255, 255, 255, 255),
        anchor="mm",
    )

    shadow = glyph.filter(ImageFilter.GaussianBlur(size * 0.05))
    shadow = Image.new("RGBA", glyph.size, (20, 16, 70, 0)).copy()
    shadow.putalpha(
        glyph.getchannel("A").filter(ImageFilter.GaussianBlur(size * 0.045)).point(
            lambda value: int(value * 0.45)
        )
    )
    merged = Image.alpha_composite(shadow, glyph).resize((size, size), Image.LANCZOS)
    base.alpha_composite(merged)

    if rounded:
        base.putalpha(rounded_mask((size, size), int(size * 0.22)))
    return base


def write_android_icons(master):
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    for folder, px in densities.items():
        target = os.path.join(res, folder)
        os.makedirs(target, exist_ok=True)
        master.resize((px, px), Image.LANCZOS).save(
            os.path.join(target, "ic_launcher.png")
        )
    print("wrote android launcher icons")


def write_ios_icons(square):
    appicon = os.path.join(
        ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
    )
    contents = json.load(open(os.path.join(appicon, "Contents.json")))
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        base = float(entry["size"].split("x")[0])
        scale = float(entry["scale"].rstrip("x"))
        px = max(1, round(base * scale))
        # iOS applies its own mask, so feed it the unrounded square.
        square.resize((px, px), Image.LANCZOS).convert("RGB").save(
            os.path.join(appicon, filename)
        )
    print("wrote ios app icons")


def main():
    os.makedirs(IMAGES, exist_ok=True)
    os.makedirs(ICON_DIR, exist_ok=True)

    banner(
        "banner_earnings.png",
        (42, 106, 194),
        (18, 50, 104),
        [(0.86, 0.22, 0.34, 34), (0.68, 0.84, 0.26, 26), (0.94, 0.72, 0.16, 40)],
    )
    banner(
        "banner_referral.png",
        (16, 185, 129),
        (4, 108, 92),
        [(0.84, 0.26, 0.32, 36), (0.62, 0.88, 0.24, 26)],
    )
    banner(
        "banner_training.png",
        (245, 158, 11),
        (180, 83, 9),
        [(0.88, 0.3, 0.3, 38), (0.6, 0.9, 0.22, 26)],
    )

    rounded = app_icon()
    rounded.save(os.path.join(ICON_DIR, "app_icon.png"))
    print("wrote assets/icon/app_icon.png")
    write_android_icons(rounded)
    write_ios_icons(app_icon(rounded=False))


if __name__ == "__main__":
    main()
