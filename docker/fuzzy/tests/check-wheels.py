#!/usr/bin/env python3
"""Audit both wheel flavors and unpack their ELF files for the ISA checks."""
from email.parser import BytesParser
from pathlib import Path, PurePosixPath
import re
import shutil
import sys
import zipfile

root, destination = map(Path, sys.argv[1:])
markers = list((root / 'wheels/prism').glob('fuzzy_prism_runtime-*.whl'))
assert len(markers) == 1, markers
runtime = markers[0].name.split('-')[1]
expected_requirement = f'fuzzy-prism-runtime=={runtime}'

for flavor in ('ieee', 'prism'):
    for wheel in sorted((root / 'wheels' / flavor).glob('*.whl')):
        with zipfile.ZipFile(wheel) as archive:
            metadata_paths = [name for name in archive.namelist() if name.endswith('.dist-info/METADATA')]
            assert len(metadata_paths) == 1, wheel
            metadata = BytesParser().parsebytes(archive.read(metadata_paths[0]))
            if metadata['Name'] == 'fuzzy-prism-runtime':
                continue
            assert metadata['Version'].endswith('+' + flavor), (wheel, metadata['Version'])
            requirements = metadata.get_all('Requires-Dist', [])
            runtime_requirements = [re.sub(r'\s+', '', req) for req in requirements
                                    if req.lower().startswith('fuzzy-prism-runtime')]
            assert runtime_requirements == ([expected_requirement] if flavor == 'prism' else []), (wheel, runtime_requirements)
            for member in archive.infolist():
                path = PurePosixPath(member.filename)
                assert not path.is_absolute() and '..' not in path.parts, (wheel, path)
                assert not re.match(r'lib(prism|interflop|hwy).*\.so', path.name), (wheel, path)
                if member.is_dir():
                    continue
                with archive.open(member) as source:
                    if source.read(4) != b'\x7fELF':
                        continue
                    target = destination / flavor / wheel.stem / member.filename
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with target.open('wb') as output:
                        output.write(b'\x7fELF')
                        shutil.copyfileobj(source, output)
                    target.chmod(0o755)
        print(f'[PASS] {wheel.name}: flavor, runtime dependency, no private runtime')
