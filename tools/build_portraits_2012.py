#!/usr/bin/env python3
"""APEX Portrait Pack 2012: real pixel crop, no re-generation of any person.

Requires Python 3.9+ and Pillow: python -m pip install Pillow
Input: the 48 source photographs uploaded in the conversation, in one folder.
Output: one ZIP containing 24 HUD crops (384x400), 24 profile crops
(640x800), contact sheets, crop coordinates and original SHA-256 hashes.

Images are not republished to public repositories. License provenance needs
separate written review before redistribution of any photo.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
import zipfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

PRESETS = Path(__file__).resolve().parents[1] / "data" / "portrait_source_uploads_2012.json"
HUD_SIZE = (384, 400)
PROFILE_SIZE = (640, 800)


def slug(value: str) -> str:
    import unicodedata
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def crop_box(image: Image.Image, context: str, x_offset: float = 0.0):
    w, h = image.size
    if context == "hud":
        # Match Hamilton's approved close-up: full face, cap/hair, shoulders,
        # little upper chest, almost square 384:400; prioritize top region.
        crop_h = min(h, int(round(w * HUD_SIZE[1] / HUD_SIZE[0])))
        crop_w = int(round(crop_h * HUD_SIZE[0] / HUD_SIZE[1]))
        crop_w = min(w, crop_w)
        x = int(round((w - crop_w) / 2 + x_offset * w))
        y = 0
    else:
        # The original full-body photo: top of head down to waist, preserve
        # left-side helmet on typical 2012 official studio portraits.
        crop_h = min(h, int(round(h * 0.66)))
        crop_w = min(w, int(round(crop_h * PROFILE_SIZE[0] / PROFILE_SIZE[1])))
        crop_h = min(h, int(round(crop_w * PROFILE_SIZE[1] / PROFILE_SIZE[0])))
        x = int(round((w - crop_w) / 2 - 0.04 * w + x_offset * w))
        y = 0
    x = max(0, min(x, w - crop_w))
    y = max(0, min(y, h - crop_h))
    return (x, y, x + crop_w, y + crop_h)


def render(image_path: Path, context: str, dimensions):
    with Image.open(image_path) as src:
        im = ImageOps.exif_transpose(src).convert("RGB")
    box = crop_box(im, context)
    resized = im.crop(box).resize(dimensions, Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    resized.save(buf, "PNG", optimize=True)
    return buf.getvalue(), list(box), list(im.size), resized


def contact_sheet(images, columns, cell, title):
    cw, ch = cell
    rows = (len(images) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cw, rows * (ch + 28) + 35), "#101822")
    draw = ImageDraw.Draw(sheet)
    draw.text((8, 8), title, fill="#FFFFFF")
    for idx, (name, picture) in enumerate(images):
        col, row = idx % columns, idx // columns
        x, y = col * cw, 35 + row * (ch + 28)
        thumb = picture.copy()
        thumb.thumbnail((cw - 8, ch - 8), Image.Resampling.LANCZOS)
        sheet.paste(thumb, (x + (cw - thumb.width)//2, y + 4))
        draw.text((x + 4, y + ch + 3), name[:24], fill="#FFFFFF")
    out = io.BytesIO()
    sheet.save(out, "JPEG", quality=91, optimize=True)
    return out.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inputs", type=Path, default=Path("/mnt/data"),
                        help="Folder with 48 uploaded PNG originals")
    parser.add_argument("--output", type=Path,
                        default=Path("APEX_PORTRAITS_2012_24_PILOTOS_REVIEW.zip"))
    args = parser.parse_args()
    source = json.loads(PRESETS.read_text(encoding="utf-8"))
    roster = source["drivers"]
    if len(roster) != 24 or len({r["name"] for r in roster}) != 24:
        raise ValueError("Expected exactly 24 different pilots.")
    missing = [item[key] for item in roster for key in ("headshot", "fullbody")
               if not (args.inputs / item[key]).is_file()]
    if missing:
        raise FileNotFoundError("Missing source photo(s), cannot provide a complete verified pack:\n"
                                + "\n".join(missing))
    review = []
    previews_hud, previews_profile = [], []
    output = args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for item in roster:
            name, ident = item["name"], slug(item["name"])
            sources = (("hud", "headshot", HUD_SIZE, previews_hud),
                       ("profile", "fullbody", PROFILE_SIZE, previews_profile))
            for context, key, dimensions, previews in sources:
                input_path = args.inputs / item[key]
                data, box, original_size, preview = render(input_path, context, dimensions)
                relative = f"{context}/{ident}_{context}_2012.png"
                archive.writestr(relative, data)
                previews.append((name, preview))
                review.append({
                    "driver": name, "context": context, "file": relative,
                    "source_file": input_path.name,
                    "source_sha256": hashlib.sha256(input_path.read_bytes()).hexdigest(),
                    "source_px": original_size, "crop_box_xyxy_source_px": box,
                    "output_px": list(dimensions), "crop_method": "Pillow Lanczos (actual pixels)",
                    "license_review": "UNVERIFIED: supplied by user, no redistributable license proven"
                })
        archive.writestr("contact_sheets/hud_24.jpg",
                         contact_sheet(previews_hud, 6, (160, 166), "APEX - HUD 24 PILOTOS 2012"))
        archive.writestr("contact_sheets/profile_24.jpg",
                         contact_sheet(previews_profile, 6, (160, 200), "APEX - MENU 24 PILOTOS 2012"))
        archive.writestr("manifest_crop_2012.json", json.dumps(review, ensure_ascii=False, indent=2) + "\n")
        archive.writestr("LEIA_ME.txt",
            "APEX PORTRAITS 2012 — REVISÃO LOCAL\n\n"
            "hud/: 24 rostos de 384x400 para classificação e rádio.\n"
            "profile/: 24 recortes de 640x800 da cabeça até a cintura.\n"
            "contact_sheets/: conferência rápida de rosto e crop dos 24 pilotos.\n\n"
            "Fotos foram RECORTADAS (pixels existentes), não recriadas por IA.\n"
            "Revisar um a um antes de usar no jogo. NÃO publicar como asset pack\n"
            "sem licenciamento/atribuição adequados para cada fotografia.\n"
            "2012: Hamilton corre pela McLaren e usa o número 4.\n")
    with zipfile.ZipFile(output) as check:
        failures = check.testzip()
        if failures:
            raise RuntimeError("ZIP CRC failed for " + failures)
        assert len([n for n in check.namelist() if n.startswith("hud/")]) == 24
        assert len([n for n in check.namelist() if n.startswith("profile/")]) == 24
    print(f"Created {output}: 24 HUD + 24 profile photos + contact sheets. "
          f"Bytes={output.stat().st_size}, sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
