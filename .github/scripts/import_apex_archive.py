#!/usr/bin/env python3
"""Safely import the uploaded split APEX ZIP into this repository's worktree.

The GitHub Actions runner does the processing. This script does NOT execute
anything contained in the ZIP and intentionally never modifies the main branch.
"""
from __future__ import annotations

import hashlib
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import sys
import tempfile
import zipfile

PART_DIRECTORY = Path("docs/arquivo/pacotes")
PART_BASENAME = "APEX_v0.6.6.8.zip.part"
EXPECTED_PARTS = 5
MAX_ENTRIES = 100_000
MAX_UNPACKED_BYTES = 2 * 1024**3
MAX_GIT_FILE_BYTES = 95_000_000  # keep individual files below GitHub's 100 MB limit
CHUNK_SIZE = 1024 * 1024
BLOCKED_TOP = {".git", ".github", ".godot", ".import"}
PROTECTED_FILES = {"README.md", ".gitignore"}


def write_summary(message: str) -> None:
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as out:
            out.write(message + "\n")
    print(message)


def fail(message: str) -> None:
    write_summary("### Importação bloqueada\n\n" + message)
    raise SystemExit(1)


def validate_name(name: str) -> tuple[str, ...]:
    if not name or name.startswith("/") or "\\" in name or "\x00" in name:
        fail("Caminho inseguro no ZIP: " + repr(name))
    segments = tuple(name.split("/"))
    if any(x == ".." for x in segments):
        fail("Tentativa de sair da pasta do projeto no ZIP: " + repr(name))
    return tuple(x for x in segments if x not in ("", "."))


def main() -> None:
    repo = Path.cwd().resolve()
    parts = [repo / PART_DIRECTORY / (PART_BASENAME + f"{i:03d}") for i in range(EXPECTED_PARTS)]
    missing = [p.name for p in parts if not p.is_file()]
    if missing:
        fail("Partes ausentes: " + ", ".join(missing))

    # Each invocation owns a private directory, including on validation/CRC failure.
    # An invalid RUNNER_TEMP fails closed rather than falling back elsewhere.
    try:
        with tempfile.TemporaryDirectory(
            prefix="apex-import-", dir=os.environ.get("RUNNER_TEMP") or None
        ) as temp:
            import_archive(repo, parts, Path(temp) / "apex_v0.6.6.8_combined.zip")
    except OSError as exc:
        fail("Falha no diretório temporário ou na reunião das partes: " + str(exc))


def validate_destination(repo: Path, dest: Path) -> None:
    relative = dest.relative_to(repo)
    current = repo
    for segment in relative.parts:
        current = current / segment
        if current.is_symlink():
            fail("Destino contém link simbólico: " + relative.as_posix())
    if not dest.resolve().is_relative_to(repo):
        fail("Destino inseguro: " + relative.as_posix())


def import_archive(repo: Path, parts: list[Path], combined: Path) -> None:
    digest = hashlib.sha256()
    byte_count = 0
    with combined.open("xb") as out:
        for part in parts:
            with part.open("rb") as src:
                while True:
                    block = src.read(CHUNK_SIZE)
                    if not block:
                        break
                    out.write(block)
                    digest.update(block)
                    byte_count += len(block)
    write_summary(
        "### Pacote recebido\n\n"
        f"- Partes reunidas: **{len(parts)}**\n"
        f"- Tamanho do ZIP: **{byte_count:,} bytes**\n"
        f"- SHA-256: \x60{digest.hexdigest()}\x60\n"
    )

    if not zipfile.is_zipfile(combined):
        fail("As partes concatenadas não formam um ZIP válido. Verifique ordem e integridade.")

    try:
        with zipfile.ZipFile(combined) as archive:
            infos = archive.infolist()
            if len(infos) > MAX_ENTRIES:
                fail(f"ZIP contém {len(infos)} entradas, acima do limite seguro.")

            projects: set[tuple[str, ...]] = set()
            unpacked_bytes = 0
            for info in infos:
                segments = validate_name(info.filename)
                mode = info.external_attr >> 16
                if stat.S_ISLNK(mode):
                    fail("ZIP contém link simbólico, importação recusada: " + info.filename)
                if not info.is_dir():
                    unpacked_bytes += info.file_size
                    if segments and segments[-1] == "project.godot":
                        projects.add(segments[:-1])
            if unpacked_bytes > MAX_UNPACKED_BYTES:
                fail(f"ZIP descompactado é grande demais: {unpacked_bytes:,} bytes.")
            if len(projects) != 1:
                fail(
                    "Esperado exatamente um project.godot; encontrados "
                    + str(len(projects))
                    + ". Não vou adivinhar qual subprojeto importar."
                )
            root = next(iter(projects))
            root_display = "/".join(root) if root else "(raiz do ZIP)"
            write_summary(
                f"- Pasta Godot identificada: \x60{root_display}\x60\n"
                f"- Entradas no ZIP: **{len(infos):,}**\n"
            )

            planned: list[tuple[zipfile.ZipInfo, Path]] = []
            skipped: list[str] = []
            destinations: set[str] = set()
            total_project_bytes = 0
            for info in infos:
                full = validate_name(info.filename)
                if info.is_dir() or len(full) <= len(root) or full[:len(root)] != root:
                    continue
                relative = full[len(root):]
                rel = PurePosixPath(*relative)
                if relative[0] in BLOCKED_TOP or rel.as_posix() in PROTECTED_FILES:
                    skipped.append(rel.as_posix())
                    continue
                if any(x in {".git", ".godot", ".import", "__pycache__"} for x in relative):
                    skipped.append(rel.as_posix())
                    continue
                if info.file_size > MAX_GIT_FILE_BYTES:
                    fail(
                        "Há um arquivo individual acima do limite de importação Git: "
                        f"{rel.as_posix()} ({info.file_size:,} bytes). "
                        "Será necessário configurar Git LFS sem alterar o jogo."
                    )
                if rel.as_posix() in destinations:
                    fail("Arquivo duplicado no ZIP: " + rel.as_posix())
                destinations.add(rel.as_posix())
                dest = repo.joinpath(*relative)
                validate_destination(repo, dest)
                if dest.exists():
                    skipped.append(rel.as_posix() + " (já existia)")
                    continue
                planned.append((info, dest))
                total_project_bytes += info.file_size

            if total_project_bytes > MAX_UNPACKED_BYTES:
                fail("Arquivos selecionados excedem limite de segurança.")
            if not any(dest.name == "project.godot" for _, dest in planned):
                fail("project.godot não pôde ser selecionado para importação.")
            gd = sum(dest.suffix == ".gd" for _, dest in planned)
            scenes = sum(dest.suffix == ".tscn" for _, dest in planned)
            if gd == 0 or scenes == 0:
                fail(
                    "O ZIP não parece conter fonte Godot completa: "
                    f"{gd} scripts .gd e {scenes} cenas .tscn."
                )

            for info, dest in planned:
                validate_destination(repo, dest)
                dest.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(info, "r") as src, dest.open("xb") as out:
                    shutil.copyfileobj(src, out, length=CHUNK_SIZE)
                if dest.stat().st_size != info.file_size:
                    fail("Arquivo incompleto após extração: " + str(dest))

    except (OSError, zipfile.BadZipFile, RuntimeError, EOFError) as exc:
        fail("Falha de leitura, extração ou CRC do ZIP: " + str(exc))

    write_summary(
        "### Fonte Godot extraída para ramificação experimental\n\n"
        f"- Arquivos novos: **{len(planned):,}**\n"
        f"- Scripts GDScript: **{gd:,}**\n"
        f"- Cenas TSCN: **{scenes:,}**\n"
        f"- Entradas ignoradas ou protegidas: **{len(skipped):,}**\n\n"
        "Nenhum conteúdo do ZIP foi executado. "
        "Esta etapa **não** equivale a testar o projeto no Godot.\n"
    )
    if skipped:
        write_summary(
            "<details><summary>Entradas ignoradas (primeiras 60)</summary>\n\n"
            + "\n".join(f"- \x60{x}\x60" for x in skipped[:60])
            + "\n\n</details>"
        )


if __name__ == "__main__":
    main()
