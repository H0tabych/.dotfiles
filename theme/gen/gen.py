#!/usr/bin/env python3
"""Генератор токенов дизайн-системы Glass Tide из единственного источника
`theme/palette.toml` (DOT-9, DSN-TOK-1/2). Только стандартная библиотека
Python >= 3.11 (DESIGN_SYSTEM.md, Приложение S.2) — без внешних зависимостей,
чтобы работать на любой системе (переносимость dotfiles, DOT-8).

Команды:
    gen.py                 сгенерировать файлы для активного варианта, профиль ac
    gen.py --variant forest сгенерировать для варианта forest
    gen.py --check          только проверки (DSN-A1/A2, Приложение S.3), без записи файлов

Статус (DSN-S2, первый шаг ретрофита): генератор и проверки полные; из
потребителей на этом шаге перенесены только 7 уже существовавших шаблонов
(DSN-S2 в ROADMAP — R6.5). Про-профильная генерация (ac/battery/solid/game)
и остальные потребители (Lua-композитор, starship, swayosd, qt6ct,
sddm-astronaut) — шаги DSN-S3…DSN-S8 (R6.6–R6.11).
"""
from __future__ import annotations

import argparse
import hashlib
import re
import sys
import tomllib
from pathlib import Path
from string import Template

REPO_ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = REPO_ROOT / "theme" / "palette.toml"
TEMPLATES_DIR = REPO_ROOT / "theme" / "gen" / "templates"
WALLPAPERS_DIR = REPO_ROOT / "theme" / "wallpapers"

GENERATED_HEADER = {
    ".lua": "-- Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант {variant}, профиль {profile}) — не редактируйте\n",
    ".conf": "# Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант {variant}, профиль {profile}) — не редактируйте\n",
    ".css": "/* Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант {variant}, профиль {profile}) — не редактируйте */\n",
    ".rasi": "/* Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант {variant}, профиль {profile}) — не редактируйте */\n",
    ".ini": "# Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант {variant}, профиль {profile}) — не редактируйте\n",
    ".toml": "# Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант {variant}, профиль {profile}) — не редактируйте\n",
}
# default for files without a recognised extension (mako config)
DEFAULT_HEADER = "# Сгенерировано theme/gen/gen.py из theme/palette.toml (вариант {variant}, профиль {profile}) — не редактируйте\n"

# tmpl filename -> destination path relative to repo root (DSN-S2: перенос
# 7 существующих потребителей; остальные консьюмеры S.2 — следующие шаги)
DEST = {
    "nvim-colors.lua.tmpl": "nvim/lua/colors.lua",
    "foot-colors.ini.tmpl": "foot/colors.ini",
    "waybar-colors.css.tmpl": "waybar/colors.css",
    "rofi-colors.rasi.tmpl": "rofi/colors.rasi",
    "hypr-colors.conf.tmpl": "hypr/colors.conf",
    "mako-config.tmpl": "mako/config",
    "yazi-theme.toml.tmpl": "yazi/theme.toml",
}

HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")
REQUIRED_FONT_SIZES = {"sm", "md", "lg", "mono", "display"}
NEUTRAL_ORDER = ["crust", "mantle", "base", "surface0", "surface1", "surface2"]


class CheckError(Exception):
    pass


def load_palette() -> dict:
    with PALETTE_PATH.open("rb") as f:
        return tomllib.load(f)


# ---------------------------------------------------------------- contrast --

def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(hex_color: str) -> float:
    r, g, b = hex_to_rgb01(hex_color)
    return 0.2126 * srgb_to_linear(r) + 0.7152 * srgb_to_linear(g) + 0.0722 * srgb_to_linear(b)


def hex_to_rgb01(hex_color: str) -> tuple[float, float, float]:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
    return r, g, b


def wcag_contrast(fg_hex: str, bg_hex: str) -> float:
    l1, l2 = relative_luminance(fg_hex), relative_luminance(bg_hex)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def blend(fg_alpha_hex: str, alpha: float, bg_hex: str) -> str:
    """fg_alpha_hex над bg_hex с непрозрачностью alpha -> результирующий hex."""
    fr, fg_, fb = hex_to_rgb01(fg_alpha_hex)
    br, bg__, bb = hex_to_rgb01(bg_hex)
    r = fr * alpha + br * (1 - alpha)
    g = fg_ * alpha + bg__ * (1 - alpha)
    b = fb * alpha + bb * (1 - alpha)
    return f"#{round(r * 255):02X}{round(g * 255):02X}{round(b * 255):02X}"


def hex_to_hue(hex_color: str) -> float:
    r, g, b = hex_to_rgb01(hex_color)
    mx, mn = max(r, g, b), min(r, g, b)
    d = mx - mn
    if d == 0:
        return 0.0
    if mx == r:
        h = ((g - b) / d) % 6
    elif mx == g:
        h = (b - r) / d + 2
    else:
        h = (r - g) / d + 4
    return h * 60.0


def hue_diff(a: float, b: float) -> float:
    d = abs(a - b) % 360
    return min(d, 360 - d)


# ------------------------------------------------------------------- checks --

def check_schema(p: dict) -> list[str]:
    errs = []
    for table in ("neutral", "semantic", "ansi", "glass", "blur", "font", "shape", "motion", "notify"):
        if table not in p:
            errs.append(f"схема: отсутствует таблица [{table}]")
    for role, val in p.get("neutral", {}).items():
        if not HEX_RE.match(val):
            errs.append(f"схема: neutral.{role} не HEX: {val!r}")
    for role, val in p.get("semantic", {}).items():
        if not HEX_RE.match(val):
            errs.append(f"схема: semantic.{role} не HEX: {val!r}")
    for key in ("regular", "bright"):
        arr = p.get("ansi", {}).get(key, [])
        if len(arr) != 8:
            errs.append(f"схема: ansi.{key} должен содержать 8 цветов, найдено {len(arr)}")
        for val in arr:
            if not HEX_RE.match(val):
                errs.append(f"схема: ansi.{key} содержит не-HEX: {val!r}")
    sizes = set(p.get("font", {}).get("size", {}).keys())
    if sizes != REQUIRED_FONT_SIZES:
        errs.append(f"схема: font.size должен содержать ровно {REQUIRED_FONT_SIZES}, найдено {sizes}")
    for profile, alphas in p.get("glass", {}).items():
        if profile == "rim":
            continue
        for level, a in alphas.items():
            if not 0 <= a <= 1:
                errs.append(f"схема: glass.{profile}.{level}={a} вне [0,1]")
    for name, variant in p.get("variant", {}).items():
        if "accent" not in variant or not HEX_RE.match(variant["accent"]):
            errs.append(f"схема: variant.{name}.accent не HEX")
        if "wallpaper" not in variant or "file" not in variant["wallpaper"] or "sha256" not in variant["wallpaper"]:
            errs.append(f"схема: variant.{name}.wallpaper требует file и sha256")
        for probe_key, val in variant.get("probe", {}).items():
            if not HEX_RE.match(val):
                errs.append(f"схема: variant.{name}.probe.{probe_key} не HEX: {val!r}")
    return errs


def check_monotonic(p: dict) -> list[str]:
    neutral = p["neutral"]
    lums = [relative_luminance(neutral[k]) for k in NEUTRAL_ORDER]
    errs = []
    for a, b, la, lb in zip(NEUTRAL_ORDER, NEUTRAL_ORDER[1:], lums, lums[1:]):
        if not (lb > la):
            errs.append(f"DSN-COL-3: нарушена монотонность {a} ({la:.4f}) < {b} ({lb:.4f})")
    return errs


# DSN-COL-4: минимальные пороги (WCAG ratio); APCA (Lc) в этой версии
# генератора не проверяется как блокирующий порог — реализация SAPC здесь
# приближённая и не сверена с эталонной (ПРОВЕРИТЬ), выводится только
# информационно отдельным скриптом при необходимости.
CONTRAST_RULES = [
    # (роль, мин. WCAG, описание)
    ("text", 7.0, "text"),
    ("subtext1", 7.0, "subtext1"),
    ("subtext0", 4.5, "subtext0"),
    ("overlay1", 4.5, "overlay1 / ansi.bright[0]"),
]
SEMANTIC_TEXT_RULES = [("success", 4.5), ("warning", 4.5), ("error", 4.5), ("info", 4.5), ("special", 4.5)]


def check_contrast(p: dict) -> list[str]:
    errs: list[str] = []
    neutral = p["neutral"]
    semantic = p["semantic"]
    on_accent = semantic["on_accent"]
    profiles = {k: v for k, v in p["glass"].items() if k != "rim"}

    for vname, variant in p["variant"].items():
        probe = variant["probe"]
        accent = variant["accent"]
        for pname, alphas in profiles.items():
            blur_enabled = p["blur"].get(pname, {}).get("enabled", pname == "ac")
            screen_probe = probe["screen"] if blur_enabled else probe["screen_sharp"]
            bar_probe = probe["bar"] if blur_enabled else probe["bar_sharp"]

            def worst(level_alpha: float, level_probe: str, surface_hex: str) -> str:
                return blend(surface_hex, level_alpha, level_probe)

            # L1 (панель) и L2/L3 (окно/попап) — worst-case фон под текстом
            bg_bar = worst(alphas["bar"], bar_probe, neutral["base"])
            bg_window = worst(alphas["window"], screen_probe, neutral["base"])
            bg_popup = worst(alphas["popup"], screen_probe, neutral["mantle"])

            for role, min_ratio, label in CONTRAST_RULES:
                fg = neutral[role]
                for level_name, bg in (("bar", bg_bar), ("window", bg_window), ("popup", bg_popup)):
                    if level_name == "bar" and role in ("subtext0",):
                        continue  # DSN-MAT-2: вторичный текст не на L1 при низкой тонировке
                    ratio = wcag_contrast(fg, bg)
                    if ratio < min_ratio:
                        errs.append(
                            f"DSN-COL-4: {vname}/{pname}/{level_name}: {label} на фоне {bg} "
                            f"даёт {ratio:.2f}:1, нужно >= {min_ratio}:1"
                        )

            for role, min_ratio in SEMANTIC_TEXT_RULES:
                fg = semantic[role]
                ratio = wcag_contrast(fg, bg_window)
                if ratio < min_ratio:
                    errs.append(
                        f"DSN-COL-4: {vname}/{pname}: semantic.{role} на фоне окна {bg_window} "
                        f"даёт {ratio:.2f}:1, нужно >= {min_ratio}:1"
                    )
                ratio_on = wcag_contrast(on_accent, semantic[role])
                if ratio_on < 7.0:
                    errs.append(
                        f"DSN-COL-4: {vname}: on_accent на {role} даёт {ratio_on:.2f}:1, нужно >= 7:1"
                    )

            ratio_on_accent = wcag_contrast(on_accent, accent)
            if ratio_on_accent < 7.0:
                errs.append(f"DSN-COL-4: {vname}: on_accent на accent даёт {ratio_on_accent:.2f}:1, нужно >= 7:1")

            ratio_sel = wcag_contrast(neutral["text"], neutral["surface2"])
            if ratio_sel < 7.0:
                errs.append(f"DSN-COL-4: text на selection (surface2) даёт {ratio_sel:.2f}:1, нужно >= 7:1")

    return errs


def check_hue(p: dict) -> list[str]:
    errs = []
    success_hue = hex_to_hue(p["semantic"]["success"])
    for vname, variant in p["variant"].items():
        diff = hue_diff(hex_to_hue(variant["accent"]), success_hue)
        if diff < 30:
            errs.append(f"DSN-COL-7: {vname}: accent/success различаются по тону на {diff:.1f}° (< 30°)")
    return errs


LITERAL_HEX_RE = re.compile(r"#[0-9A-Fa-f]{6}\b")
LITERAL_RGB_RE = re.compile(r"\brgba?\(")


def check_literals(p: dict) -> list[str]:
    errs = []
    font_names = {v for v in p.get("font", {}).values() if isinstance(v, str)}
    generated_files = {REPO_ROOT / dest for dest in DEST.values()}
    skip_dirs = {REPO_ROOT / "theme" / "gen", REPO_ROOT / ".git"}
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if path == PALETTE_PATH or path in generated_files:
            continue
        if any(str(path).startswith(str(d) + "/") for d in skip_dirs):
            continue
        try:
            text = path.read_text(errors="ignore")
        except OSError:
            continue
        for m in LITERAL_HEX_RE.finditer(text):
            errs.append(f"DSN-TOK-8: литерал цвета {m.group(0)} в {path.relative_to(REPO_ROOT)}")
        for m in LITERAL_RGB_RE.finditer(text):
            errs.append(f"DSN-TOK-8: литерал rgb()/rgba() в {path.relative_to(REPO_ROOT)}")
        for name in font_names:
            if name and name in text:
                errs.append(f"DSN-TOK-8: имя шрифта {name!r} в {path.relative_to(REPO_ROOT)}")
    return errs


def check_wallpapers(p: dict) -> list[str]:
    errs = []
    for vname, variant in p["variant"].items():
        wp = variant["wallpaper"]
        path = WALLPAPERS_DIR / wp["file"]
        if not path.is_file():
            errs.append(f"DSN-TOK-10: {vname}: файл обоев не найден: {path}")
            continue
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != wp["sha256"]:
            errs.append(
                f"DSN-TOK-10: {vname}: sha256 обоев не совпадает (palette.toml={wp['sha256']}, файл={actual}); "
                f"пересчитайте probe.py и обновите запись"
            )
    return errs


def run_checks(p: dict) -> list[str]:
    errs: list[str] = []
    errs += check_schema(p)
    if errs:
        return errs  # дальнейшие проверки не имеют смысла без валидной схемы
    errs += check_monotonic(p)
    errs += check_contrast(p)
    errs += check_hue(p)
    errs += check_literals(p)
    errs += check_wallpapers(p)
    return errs


# --------------------------------------------------------------- rendering --

def flatten_tokens(p: dict, variant_name: str, profile_name: str) -> dict[str, str]:
    neutral = p["neutral"]
    semantic = p["semantic"]
    variant = p["variant"][variant_name]
    ansi = p["ansi"]
    shape = p["shape"]
    font = p["font"]
    motion = p["motion"]
    glass = p["glass"][profile_name]
    notify = p["notify"]

    tokens: dict[str, str] = {}

    def add_color(name: str, hexval: str) -> None:
        tokens[name] = hexval
        tokens[f"{name}_raw"] = hexval.lstrip("#")

    for role, hexval in neutral.items():
        add_color(role, hexval)
    for role, hexval in semantic.items():
        add_color(role, hexval)
    add_color("accent", variant["accent"])
    add_color("selection", neutral["surface2"])

    for idx, hexval in enumerate(ansi["regular"]):
        add_color(f"ansi_regular_{idx}", hexval)
    for idx, hexval in enumerate(ansi["bright"]):
        add_color(f"ansi_bright_{idx}", hexval)

    tokens["radius_window"] = str(shape["radius"]["window"])
    tokens["radius_control"] = str(shape["radius"]["control"])
    tokens["radius_pill"] = str(shape["radius"]["pill"])
    tokens["gap_inner"] = str(shape["gap"]["inner"])
    tokens["gap_outer"] = str(shape["gap"]["outer"])
    tokens["border_window"] = str(shape["border"]["window"])
    tokens["border_rim"] = str(shape["border"]["rim"])
    tokens["bar_width"] = str(shape["bar"]["width"])
    tokens["icon_bar"] = str(shape["icon"]["bar"])
    tokens["icon_list"] = str(shape["icon"]["list"])
    tokens["cursor_size"] = str(shape["cursor"])
    tokens["pad_term_x"], tokens["pad_term_y"] = (str(v) for v in shape["pad"]["term"])

    tokens["font_ui"] = font["ui"]
    tokens["font_mono"] = font["mono"]
    tokens["font_symbols"] = font["symbols"]
    for size_name, size_val in font["size"].items():
        tokens[f"size_{size_name}"] = str(size_val)
    for weight_name, weight_val in font["weight"].items():
        tokens[f"weight_{weight_name}"] = str(weight_val)
    tokens["line_ui"] = str(font["line"]["ui"])
    tokens["line_mono"] = str(font["line"]["mono"])

    tokens["motion_in"] = str(motion["in_ms"])
    tokens["motion_out"] = str(motion["out_ms"])
    tokens["motion_workspace"] = str(motion["workspace_ms"])
    tokens["motion_fade"] = str(motion["fade_ms"])

    tokens["notify_width"] = str(notify["width"])
    tokens["notify_max_visible"] = str(notify["max_visible"])
    tokens["notify_timeout"] = str(notify["timeout_ms"])

    tokens["glass_bar"] = str(glass["bar"])
    tokens["glass_window"] = str(glass["window"])
    tokens["glass_popup"] = str(glass["popup"])
    tokens["glass_rim"] = str(p["glass"]["rim"])

    tokens["term_alpha"] = str(glass["window"])

    tokens["variant"] = variant_name
    tokens["profile"] = profile_name

    return tokens


def header_for(dest: Path, variant: str, profile: str) -> str:
    fmt = GENERATED_HEADER.get(dest.suffix, DEFAULT_HEADER)
    return fmt.format(variant=variant, profile=profile)


def render(p: dict, variant_name: str, profile_name: str) -> None:
    tokens = flatten_tokens(p, variant_name, profile_name)
    for tmpl_name, dest_rel in DEST.items():
        tmpl_path = TEMPLATES_DIR / tmpl_name
        dest_path = REPO_ROOT / dest_rel
        content = Template(tmpl_path.read_text()).substitute(tokens)
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        header = header_for(dest_path, variant_name, profile_name)
        dest_path.write_text(header + content)
        print(f"generated {dest_rel}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--variant", default=None, help="вариант (по умолчанию — active из palette.toml)")
    ap.add_argument("--profile", default="ac", choices=["ac", "battery", "solid", "game"])
    ap.add_argument("--check", action="store_true", help="только проверки S.3, без записи файлов")
    a = ap.parse_args()

    p = load_palette()

    errs = run_checks(p)
    if errs:
        print(f"[gen.py] НАЙДЕНО {len(errs)} ПРОБЛЕМ:", file=sys.stderr)
        for e in errs:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print("[gen.py] все проверки S.3 пройдены (DSN-A1, DSN-A2)")

    if a.check:
        return 0

    variant_name = a.variant or p.get("active")
    if not isinstance(variant_name, str) or variant_name not in p["variant"]:
        print(f"[gen.py] неизвестный вариант: {variant_name}", file=sys.stderr)
        return 1
    render(p, variant_name, a.profile)
    return 0


if __name__ == "__main__":
    sys.exit(main())
