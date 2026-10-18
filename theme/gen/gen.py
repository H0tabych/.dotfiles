#!/usr/bin/env python3
"""Генератор токенов дизайн-системы Glass Tide из единственного источника
`theme/palette.toml` (DOT-9, DSN-TOK-1/2). Только стандартная библиотека
Python >= 3.11 (DESIGN_SYSTEM.md, Приложение S.2) — без внешних зависимостей,
чтобы работать на любой системе (переносимость dotfiles, DOT-8).

Команды:
    gen.py                 сгенерировать файлы для активного варианта, профиль ac
    gen.py --variant forest сгенерировать для варианта forest
    gen.py --check          только проверки (DSN-A1/A2, Приложение S.3), без записи файлов

Статус: DSN-S2 (R6.5) перенёс 7 существовавших потребителей; DSN-S4 (R6.7)
добавил композитор (`hypr/theme.lua`, `hypr/effects.lua` — только профиль
`ac`, PROFILE_EFFECTS). DSN-S5 (R6.8) добавил SwayOSD, `hypr/theme.conf`
(роли цвета/шрифт для hyprlock — не зависит от профиля, L6 не тонируется,
раздел 2.1) и per-profile файлы для waybar/rofi/swayosd (`theme-<профиль>.<ext>`
+ симлинк `theme.<ext>` без суффикса, PROFILED_DEST).
DSN-S7 (R6.10): `hypr/effects.lua` и `mako/config` переведены в PROFILED_DEST
(`effects-<профиль>.lua`, `config-<профиль>`); `render()` пишет файлы **всех**
PROFILES за один прогон (переключателю `hypr/scripts/profile` нужны файлы
всех четырёх сразу) и создаёт симлинк только при первом прогоне (его ещё
нет) — на уже переключённом профиле симлинк не трогается, им владеет сам
переключатель.
Обои (`hypr/hyprpaper.conf`, путь к файлу обоев) генератор НЕ пишет
(исправление R6.8, 2026-10-15): hyprlang не резолвит необъявленную переменную
как переменную окружения (ПРОВЕРЕНО на машине), абсолютный путь — факт
установки (dotfiles.source пользователя), его собирает Nix
(`modules/shell/dotfiles-link.nix` в nixos-config, machine.d/hypr-wallpaper.conf).
DSN-S6 (R6.9) добавил starship (`starship/starship.toml`,
`starship/starship-lite.toml` — без `$git_status` в `format`, без
профильного варианта: палитра промпта не зависит от профиля эффектов) и
перевёл `yazi/theme.toml` на разбивку секций DESIGN_SYSTEM.md P.3.5:
`[mgr]`/`[indicator]`/`[tabs]`/`[mode]` вместо `[manager]` с вложенными
`tab_*`/`mode_*`. ПРОВЕРЕНО на машине (yazi 26.5.6): имена TOML-таблиц
верхнего уровня должны быть kebab-case — `[snake_case]` падает с ошибкой
"must be a kebab-cased string", `[kebab-case]` и вложенные snake_case-поля
(`find_keyword`, `border_style` и т. п.) парсятся без ошибок. Само наличие
секций `[mgr]`/`[indicator]`/`[tabs]`/`[mode]` и реальный эффект их полей
живой проверкой не подтверждены — yazi молча игнорирует нераспознанные
TOML-таблицы и поля (кебаб-проверка — единственное, что даёт ошибку
синтаксиса); `[cmp]`/`[notify]`/`[filetype]`/`[icon]` не добавлены вовсе —
схема их полей неизвестна, ПРОВЕРИТЬ визуально на живой системе.

DSN-S9/R7.1 добавил `zathura/zathurarc` (PLAIN_DEST — не зависит от профиля
эффектов, DSN-CMP-18) и упаковку `theme/export/glass-tide-<вариант>.tdesktop-
theme` — ZIP с единственным файлом `colors.tdesktop-theme` (формат Telegram
Desktop), собирается отдельной функцией `render_tdesktop_theme()` в обход
`PLAIN_DEST` (там только текстовые файлы с подстановкой Template; здесь текст
сначала рендерится, потом упаковывается). Имена ключей `.tdesktop-theme` —
ПРОВЕРИТЬ вживую (Приложение I.6, M5 DESIGN_SYSTEM.md); импорт в Telegram —
разовое ручное действие (DSN-CMP-17), не автоматизируется.
DSN-S9/R7.2 добавил `mpv/theme.conf` (PLAIN_DEST — как zathurarc, не зависит
от профиля эффектов: DSN-EXC-1, окно видео сплошное). Токен
`osd_back_alpha_hex` — фиксированная альфа фона OSD (0.90, порог DSN-CMP-19
>= 0.85), не из `palette.toml`: это константа применения правила, а не токен
палитры (как PROFILE_EFFECTS выше), поэтому вычисляется здесь.
DSN-S9/R7.3 добавил `mangohud/MangoHud.conf` (PLAIN_DEST — не зависит от
профиля, DSN-CMP-20: оверлей всегда сплошной, DSN-EXC-2). `background_alpha`
в шаблоне — литерал 0.6 (DSN-CMP-20), как и у MangoHud сам формат (десятичная
дробь, не hex-байт как `osd_back_alpha_hex` у mpv) — отдельный токен не нужен.
Шрифт — встроенный MangoHud, не из палитры: кастомный шрифт принимает только
абсолютный путь к `.ttf` (`font_file`), а dotfiles не хранят пути nix-хранилища
(переносимость, DOT-8).
"""
from __future__ import annotations

import argparse
import hashlib
import re
import sys
import tomllib
import zipfile
from pathlib import Path
from string import Template

REPO_ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = REPO_ROOT / "theme" / "palette.toml"
TEMPLATES_DIR = REPO_ROOT / "theme" / "gen" / "templates"
WALLPAPERS_DIR = REPO_ROOT / "theme" / "wallpapers"
EXPORT_DIR = REPO_ROOT / "theme" / "export"

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

# tmpl filename -> путь назначения (не зависит от профиля: роли цвета, геометрия;
# hypr-theme-conf — роли/шрифт для hyprlock, L6 не тонируется по профилю,
# раздел 2.1 DESIGN_SYSTEM.md). Путь к файлу обоев сюда не входит — это факт
# установки (dotfiles.source), его пишет Nix (modules/shell/dotfiles-link.nix).
PLAIN_DEST = {
    "nvim-colors.lua.tmpl": "nvim/lua/colors.lua",
    "foot-colors.ini.tmpl": "foot/colors.ini",
    "hypr-theme.lua.tmpl": "hypr/theme.lua",
    "hypr-theme-conf.tmpl": "hypr/theme.conf",
    "yazi-theme.toml.tmpl": "yazi/theme.toml",
    "starship-toml.tmpl": "starship/starship.toml",
    "starship-lite-toml.tmpl": "starship/starship-lite.toml",
    "zathurarc.tmpl": "zathura/zathurarc",
    "mpv-theme-conf.tmpl": "mpv/theme.conf",
    "mangohud-theme-conf.tmpl": "mangohud/MangoHud.conf",
}

PROFILES = ("ac", "battery", "solid", "game")

# tmpl filename -> (каталог приложения, базовое имя, расширение). Реальный файл —
# "<base>-<профиль><ext>" для КАЖДОГО профиля (генератор пишет все четыре за
# один прогон — переключателю DSN-S7/R6.10 нужны файлы всех профилей сразу,
# не только активного); симлинк без суффикса — производное состояние
# переключателя (P.3.1), в .gitignore. Генератор переставляет симлинк только
# при первом прогоне (его ещё нет) — на уже переключённом профиле он не
# трогается (не затирает состояние переключателя правкой palette.toml).
PROFILED_DEST = {
    "waybar-theme.css.tmpl": ("waybar", "theme", ".css"),
    "rofi-theme.rasi.tmpl": ("rofi", "theme", ".rasi"),
    "swayosd-theme.css.tmpl": ("swayosd", "theme", ".css"),
    "hypr-effects.lua.tmpl": ("hypr", "effects", ".lua"),
    "mako-config.tmpl": ("mako", "config", ""),
}

# DSN-S4 (R6.7): матрица поведения профилей — раздел 9 DESIGN_SYSTEM.md.
# Это правило применения, не токен палитры (DSN-TOK-1 про цвета/размеры/движение),
# поэтому живёт здесь, а не в palette.toml. "anim"/"k" — грубая аппроксимация
# (у solid анимации выключены только для окон, не целиком) — уточнение раньше
# времени не нужно: полноценное переключение профилей — DSN-S7 (R6.10).
PROFILE_EFFECTS = {
    "ac":      {"shadow": True,  "dim": True,  "anim": True,  "terminal_opaque": False},
    "battery": {"shadow": False, "dim": True,  "anim": True,  "terminal_opaque": True},
    "solid":   {"shadow": True,  "dim": True,  "anim": False, "terminal_opaque": True},
    "game":    {"shadow": False, "dim": False, "anim": False, "terminal_opaque": False},
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


def alpha_to_hex(a: float) -> str:
    """0.90 -> "E6" — байт альфы для форматов с #RRGGBBAA (mako, hyprlang, rasi)."""
    return f"{round(a * 255):02X}"


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
# (?<![.\w]) исключает вызовы вида t.rgba(role, a)/t.argb(role, a) (theme.lua,
# DSN-S4): это обращение к функции-токену, а не цветовой литерал.
LITERAL_RGB_RE = re.compile(r"(?<![.\w])rgba?\(")


def all_generated_paths(p: dict) -> set[Path]:
    """Пути, которые пишет render(): исключаются из поиска литералов (DSN-TOK-8).
    Для PROFILED_DEST — симлинк без суффикса и файлы всех четырёх профилей
    (даже ещё не сгенерированных — набор путей, а не список существующих файлов)."""
    paths = {REPO_ROOT / dest for dest in PLAIN_DEST.values()}
    for subdir, base, ext in PROFILED_DEST.values():
        d = REPO_ROOT / subdir
        paths.add(d / f"{base}{ext}")
        for profile in PROFILES:
            paths.add(d / f"{base}-{profile}{ext}")
    for variant in p["variant"]:
        paths.add(EXPORT_DIR / f"glass-tide-{variant}.tdesktop-theme")
    return paths


def check_literals(p: dict) -> list[str]:
    errs = []
    font_names = {v for v in p.get("font", {}).values() if isinstance(v, str)}
    generated_files = all_generated_paths(p)
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
    tokens["dim"] = str(shape["dim"])
    tokens["shadow_range"] = str(shape["shadow"]["range"])
    tokens["shadow_power"] = str(shape["shadow"]["power"])
    tokens["shadow_active"] = str(shape["shadow"]["active"])
    tokens["shadow_inactive"] = str(shape["shadow"]["inactive"])
    tokens["bar_width"] = str(shape["bar"]["width"])
    tokens["icon_bar"] = str(shape["icon"]["bar"])
    tokens["icon_list"] = str(shape["icon"]["list"])
    tokens["cursor_size"] = str(shape["cursor"])
    tokens["pad_term_x"], tokens["pad_term_y"] = (str(v) for v in shape["pad"]["term"])
    tokens["pad_launcher"] = str(shape["pad"]["launcher"])
    tokens["pad_pill"] = str(shape["pad"]["pill"])
    tokens["pad_item_x"], tokens["pad_item_y"] = (str(v) for v in shape["pad"]["item"])

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

    # DSN-S5 (R6.8): байты альфы для форматов без функции alpha()/rgba() по
    # токену — mako (#RRGGBBAA), hyprlang (rgba(RRGGBBAAhex)), rasi (#RRGGBBAA).
    tokens["glass_bar_alpha_hex"] = alpha_to_hex(glass["bar"])
    tokens["glass_window_alpha_hex"] = alpha_to_hex(glass["window"])
    tokens["glass_popup_alpha_hex"] = alpha_to_hex(glass["popup"])
    tokens["glass_rim_alpha_hex"] = alpha_to_hex(p["glass"]["rim"])

    tokens["term_alpha"] = str(glass["window"])

    # DSN-CMP-19 (R7.2): альфа фона OSD mpv — фиксированная константа
    # применения правила (>= 0.85), не зависит от профиля эффектов (DSN-EXC-1:
    # окно видео сплошное) и не хранится в palette.toml.
    tokens["osd_back_alpha_hex"] = alpha_to_hex(0.90)

    # DSN-S4 (R6.7): fx.* для hypr/effects.lua — размытие из [blur] (как в
    # check_contrast: нет записи -> включено только у ac), остальное — из
    # PROFILE_EFFECTS (раздел 9).
    blur_cfg = p.get("blur", {}).get(profile_name, {})
    blur_enabled = blur_cfg.get("enabled", profile_name == "ac")
    fx = PROFILE_EFFECTS[profile_name]

    def lua_bool(v: bool) -> str:
        return "true" if v else "false"

    tokens["fx_blur"] = lua_bool(blur_enabled)
    tokens["blur_size"] = str(blur_cfg.get("size", 0))
    tokens["blur_passes"] = str(blur_cfg.get("passes", 0))
    tokens["blur_noise"] = str(blur_cfg.get("noise", 0))
    tokens["blur_contrast"] = str(blur_cfg.get("contrast", 1))
    tokens["blur_brightness"] = str(blur_cfg.get("brightness", 1))
    tokens["blur_vibrancy"] = str(blur_cfg.get("vibrancy", 0))
    tokens["fx_shadow"] = lua_bool(fx["shadow"])
    tokens["fx_dim"] = lua_bool(fx["dim"])
    tokens["fx_anim"] = lua_bool(fx["anim"])
    tokens["fx_k"] = "1.0" if profile_name != "battery" else str(motion["battery_factor"])
    tokens["fx_terminal_opaque"] = lua_bool(fx["terminal_opaque"])

    tokens["variant"] = variant_name
    tokens["profile"] = profile_name

    return tokens


def header_for(dest: Path, variant: str, profile: str) -> str:
    fmt = GENERATED_HEADER.get(dest.suffix, DEFAULT_HEADER)
    return fmt.format(variant=variant, profile=profile)


def write_rendered(tmpl_name: str, dest_path: Path, tokens: dict, variant_name: str, profile_name: str) -> None:
    tmpl_path = TEMPLATES_DIR / tmpl_name
    content = Template(tmpl_path.read_text()).substitute(tokens)
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    header = header_for(dest_path, variant_name, profile_name)
    dest_path.write_text(header + content)
    print(f"generated {dest_path.relative_to(REPO_ROOT)}")


def render_tdesktop_theme(tokens: dict, variant_name: str) -> None:
    """colors.tdesktop-theme — не зависит от профиля эффектов (DSN-CMP-17,
    как и остальной PLAIN_DEST); упаковывается в ZIP (формат Telegram Desktop
    для импорта темы), а не пишется как текстовый файл — отдельно от
    write_rendered(). date_time фиксирован (DOT-9: детерминированный вывод,
    иначе git diff видел бы изменение при каждом перегенерировании)."""
    content = Template((TEMPLATES_DIR / "tdesktop-colors.tmpl").read_text()).substitute(tokens)
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    dest = EXPORT_DIR / f"glass-tide-{variant_name}.tdesktop-theme"
    with zipfile.ZipFile(dest, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        info = zipfile.ZipInfo("colors.tdesktop-theme", date_time=(1980, 1, 1, 0, 0, 0))
        zf.writestr(info, content)
    print(f"generated {dest.relative_to(REPO_ROOT)}")


def render(p: dict, variant_name: str, profile_name: str) -> None:
    tokens = flatten_tokens(p, variant_name, profile_name)

    for tmpl_name, dest_rel in PLAIN_DEST.items():
        write_rendered(tmpl_name, REPO_ROOT / dest_rel, tokens, variant_name, profile_name)

    render_tdesktop_theme(tokens, variant_name)

    for tmpl_name, (subdir, base, ext) in PROFILED_DEST.items():
        dest_dir = REPO_ROOT / subdir
        link_path = dest_dir / f"{base}{ext}"
        had_link = link_path.is_symlink()

        for profile in PROFILES:
            profile_tokens = tokens if profile == profile_name else flatten_tokens(p, variant_name, profile)
            real_path = dest_dir / f"{base}-{profile}{ext}"
            write_rendered(tmpl_name, real_path, profile_tokens, variant_name, profile)

        # Начальный симлинк (DSN-PWR-7: без состояния действует ac) — только
        # если его ещё нет; дальше симлинком владеет hypr/scripts/profile.
        # Обычный файл на месте будущего симлинка (первый переход на профили,
        # напр. hypr/effects.lua/mako/config до DSN-S7) заменяется один раз.
        if not had_link:
            if link_path.exists():
                link_path.unlink()
            default_real = dest_dir / f"{base}-{profile_name}{ext}"
            link_path.symlink_to(default_real.name)
            print(f"linked {link_path.relative_to(REPO_ROOT)} -> {default_real.name} (начальный)")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--variant", default=None, help="вариант (по умолчанию — active из palette.toml)")
    ap.add_argument("--profile", default="ac", choices=list(PROFILES))
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
