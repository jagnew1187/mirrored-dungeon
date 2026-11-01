"""Create and verify an importable ZIP without editor caches or local exports."""
from pathlib import Path
import hashlib, zipfile

project=Path(__file__).resolve().parents[1]
archive=project.parent/'MirroredDungeon_Godot_Pass05_20261026.zip'
files=[p for p in project.rglob('*') if p.is_file() and not any(part in {'.godot','exports','__pycache__'} for part in p.relative_to(project).parts) and not p.name.endswith('.tmp')]
with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(files): z.write(p,'godot-poc/'+p.relative_to(project).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert 'godot-poc/project.godot' in z.namelist()
    assert not any('/.godot/' in n or '/exports/' in n for n in z.namelist())
    for p in files:
        assert z.read('godot-poc/'+p.relative_to(project).as_posix())==p.read_bytes()
print(f'PASS: {len(files)} ZIP members verified byte-for-byte; {archive.stat().st_size:,} bytes')
print('SHA256: '+hashlib.sha256(archive.read_bytes()).hexdigest())
