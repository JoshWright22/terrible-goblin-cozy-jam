# Builds the icons and store capsules from the main menu layers.
# Run from the project root: python Store/tools/make_art.py
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
MENU = ROOT / "Assets/sprites/mainMenuSprites/menu separate"
OUT = ROOT / "Store/art"


def layer(name):
    return Image.open(MENU / f"{name}.PNG").convert("RGBA")


BG = layer("menuEmptyBGSprite")
BLENDER = layer("menuBlenderSprite")
LID = layer("menuLidSprite")
TITLE = layer("menuTitleSprite")
FRUITS = [layer(f"menuFruit{i}Sprite") for i in range(1, 8)]


def trimmed(im):
    return im.crop(im.getbbox())


def fit(im, w, h):
    s = min(w / im.width, h / im.height)
    return im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)


def cover(im, w, h, focus=(0.5, 0.5)):
    s = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    x = round((im.width - w) * focus[0])
    y = round((im.height - h) * focus[1])
    return im.crop((x, y, x + w, y + h))


def full_scene(title=True):
    scene = BG.copy()
    for part in [BLENDER, LID, *FRUITS]:
        scene.alpha_composite(part)
    if title:
        scene.alpha_composite(TITLE)
    return scene


def icon(size):
    canvas = cover(BG, size, size, (0.55, 0.3))
    blender = fit(trimmed(BLENDER), size * 0.78, size * 0.9)
    canvas.alpha_composite(blender, ((size - blender.width) // 2, round(size * 0.08)))
    berry = fit(trimmed(FRUITS[2]), size * 0.42, size * 0.42)
    canvas.alpha_composite(berry, (round(size * 0.55), round(size * 0.55)))
    banana = fit(trimmed(FRUITS[0]), size * 0.42, size * 0.5)
    canvas.alpha_composite(banana, (round(size * 0.02), round(size * 0.48)))
    return canvas


def capsule(w, h, logo_share=0.62, focus=(0.5, 0.5), logo_x=0.5):
    # logo_x is where the logo's centre sits across the width; wide capsules keep it left like the menu
    scene = cover(full_scene(title=False), w, h, focus)
    logo = fit(trimmed(TITLE), w * logo_share, h * 0.8)
    x = round(w * logo_x - logo.width / 2)
    scene.alpha_composite(logo, (max(0, x), (h - logo.height) // 2))
    return scene


def logo_only(w, h):
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    logo = fit(trimmed(TITLE), w * 0.9, h * 0.9)
    canvas.alpha_composite(logo, ((w - logo.width) // 2, (h - logo.height) // 2))
    return canvas


def save(im, name, rgb=True):
    OUT.mkdir(parents=True, exist_ok=True)
    (im.convert("RGB") if rgb else im).save(OUT / name)


if __name__ == "__main__":
    big_icon = icon(1024)
    save(big_icon, "icon_1024.png", rgb=False)
    save(big_icon.resize((512, 512), Image.LANCZOS), "play_icon_512.png")
    save(big_icon.resize((256, 256), Image.LANCZOS), "icon_256.png", rgb=False)
    big_icon.resize((256, 256), Image.LANCZOS).save(OUT / "icon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    save(big_icon.resize((184, 184), Image.LANCZOS), "steam_community_icon_184.jpg")

    # Android launcher: 192 legacy, adaptive 432 foreground (art inside the 66% safe circle) + background
    save(big_icon.resize((192, 192), Image.LANCZOS), "android_192.png")
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    inner = icon(288)
    mask = Image.new("L", (288, 288), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, 287, 287), fill=255)
    fg.paste(inner, (72, 72), mask)
    save(fg, "android_adaptive_fg_432.png", rgb=False)
    save(cover(BG, 432, 432, (0.55, 0.3)), "android_adaptive_bg_432.png")

    # Steam store and library
    save(capsule(920, 430, 0.5, logo_x=0.3), "steam_header_920x430.png")
    save(capsule(462, 174, 0.55, logo_x=0.3), "steam_small_capsule_462x174.png")
    save(capsule(1232, 706, 0.5, logo_x=0.3), "steam_main_capsule_1232x706.png")
    save(capsule(748, 896, 0.9), "steam_vertical_capsule_748x896.png")
    save(capsule(600, 900, 0.9), "steam_library_capsule_600x900.png")
    save(cover(full_scene(title=False), 3840, 1240, (0.5, 0.45)), "steam_library_hero_3840x1240.png")
    save(logo_only(1280, 720), "steam_library_logo_1280x720.png", rgb=False)
    save(cover(full_scene(title=False), 1438, 810).filter(ImageFilter.GaussianBlur(6)), "steam_page_background_1438x810.png")

    # Google Play feature graphic
    save(capsule(1024, 500, 0.48, logo_x=0.3), "play_feature_1024x500.png")
