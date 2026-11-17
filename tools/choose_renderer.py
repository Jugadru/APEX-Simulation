#!/usr/bin/env python3
"""Configure a local Godot project renderer with a recoverable backup.

Usage: python3 tools/choose_renderer.py forward_plus
       python3 tools/choose_renderer.py compatibility
       python3 tools/choose_renderer.py status
Never touch the user's originals when run on an extracted project copy.
"""
from pathlib import Path
import sys
import shutil

VALID = {'forward_plus', 'compatibility', 'gl_compatibility'}
root = Path(__file__).resolve().parents[1]
project = root / 'project.godot'
backup = root / 'project.godot.before_renderer_change.bak'

def current_value(raw: str) -> str:
    for line in raw.splitlines():
        if line.startswith('renderer/rendering_method='):
            return line.split('=', 1)[1].strip().strip('"')
    return 'não configurado'

def main():
    if len(sys.argv) != 2 or (sys.argv[1] not in VALID and sys.argv[1] != 'status'):
        print('Uso: python3 tools/choose_renderer.py [forward_plus|compatibility|status]')
        return 2
    raw = project.read_text(encoding='utf-8')
    print(f'Renderizador atual: {current_value(raw)}')
    if sys.argv[1] == 'status':
        return 0
    mode = 'gl_compatibility' if sys.argv[1] == 'compatibility' else 'forward_plus'
    if mode == current_value(raw):
        print('Nenhuma mudança necessária.')
        return 0
    if not backup.exists():
        shutil.copyfile(project, backup)
    lines = raw.splitlines(keepends=True)
    changed = False
    for i, line in enumerate(lines):
        if line.startswith('renderer/rendering_method='):
            lines[i] = f'renderer/rendering_method="{mode}"\n'
            changed = True
            break
    if not changed:
        print('ERRO: campo do renderizador não encontrado; arquivo preservado.')
        return 1
    project.write_text(''.join(lines), encoding='utf-8')
    print(f'Renderizador alterado para {mode}. Reinicie o editor Godot.')
    print(f'Backup local: {backup.name}')
    print('Se houver problemas no Linux Mint, volte a gl_compatibility.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
