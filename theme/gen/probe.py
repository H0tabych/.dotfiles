#!/usr/bin/env python3
"""Пересчёт контрольных точек `probe` для варианта обоев (DSN-TOK-10, S.3).

Не часть основного генератора (`gen.py`) — тому для работы изображения не
нужны, только уже посчитанные `probe`-значения в `palette.toml`. Этот скрипт
запускается вручную при смене обоев; результат (`probe.*`) копируется в
`theme/palette.toml` руками.

Требует Pillow и numpy (вне стандартной библиотеки — поэтому отдельно от
`gen.py`, S.2). Запуск, например:

    nix shell --impure --expr \
      'let pkgs = import <nixpkgs> {}; in pkgs.python3.withPackages (ps: [ps.pillow ps.numpy])' \
      --command python3 theme/gen/probe.py theme/wallpapers/tree-and-planet.jpg

Методика — Приложение V.3 DESIGN_SYSTEM.md: обои масштабируются до 1920x1080;
размытие профиля `ac` аппроксимируется гауссовым блюром с радиусом
`size * 2**passes / 2` и модуляцией яркости/контраста размытого слоя;
худшая точка — 99.5-й перцентиль относительной яркости (WCAG) в зоне
поверхности, для резких обоев (без блюра, профили battery/game) — 99.9-й.
Зоны: `screen` — весь экран (L2/L3 на любом месте), `bar` — вертикальная
полоса панели шириной `bar.width` (DSN-LAY-1, по умолчанию 44 px) у левого
края (DSN-TOK-1 `shape.bar.width`).
"""
import argparse
import sys

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

TARGET_W, TARGET_H = 1920, 1080


def relative_luminance(rgb: np.ndarray) -> np.ndarray:
    """WCAG relative luminance per pixel. rgb: float array in [0, 1], shape (..., 3)."""
    c = rgb
    lin = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return lin[..., 0] * 0.2126 + lin[..., 1] * 0.7152 + lin[..., 2] * 0.0722


def worst_point(arr: np.ndarray, percentile: float) -> str:
    """arr: uint8 RGB array (H, W, 3). Average color of the brightest
    `100 - percentile`% of pixels, as a hex string."""
    rgb01 = arr.astype(np.float64) / 255.0
    lum = relative_luminance(rgb01)
    threshold = np.percentile(lum, percentile)
    mask = lum >= threshold
    worst = arr[mask].mean(axis=0)
    r, g, b = (int(round(v)) for v in worst)
    return f"#{r:02X}{g:02X}{b:02X}"


def blurred(img: Image.Image, size: int, passes: int, contrast: float, brightness: float) -> Image.Image:
    radius = size * (2**passes) / 2
    out = img.filter(ImageFilter.GaussianBlur(radius=radius))
    out = ImageEnhance.Contrast(out).enhance(contrast)
    out = ImageEnhance.Brightness(out).enhance(brightness)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("wallpaper")
    ap.add_argument("--bar-width", type=int, default=44, help="ширина полосы панели, px (DSN-LAY-1)")
    ap.add_argument("--blur-size", type=int, default=6)
    ap.add_argument("--blur-passes", type=int, default=3)
    ap.add_argument("--blur-contrast", type=float, default=0.9)
    ap.add_argument("--blur-brightness", type=float, default=0.85)
    a = ap.parse_args()

    img = Image.open(a.wallpaper).convert("RGB").resize((TARGET_W, TARGET_H), Image.LANCZOS)
    blur = blurred(img, a.blur_size, a.blur_passes, a.blur_contrast, a.blur_brightness)

    sharp_arr = np.asarray(img)
    blur_arr = np.asarray(blur)
    bar_sharp_arr = sharp_arr[:, : a.bar_width]
    bar_blur_arr = blur_arr[:, : a.bar_width]

    screen = worst_point(blur_arr, 99.5)
    bar = worst_point(bar_blur_arr, 99.5)
    screen_sharp = worst_point(sharp_arr, 99.9)
    bar_sharp = worst_point(bar_sharp_arr, 99.9)

    print(f"probe = {{ screen = \"{screen}\", bar = \"{bar}\", "
          f"screen_sharp = \"{screen_sharp}\", bar_sharp = \"{bar_sharp}\" }}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
