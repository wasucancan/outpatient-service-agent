"""Verify that the 18 teaching documents trace to the packaged 8 source files."""

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(canonical=None):
    source_dir = ROOT / 'dify-knowledge-import'
    numbered = list(source_dir.glob('[0-9][0-9]-*.md'))
    if len(numbered) != 8:
        raise ValueError('Expected exactly eight packaged source Markdown files')
    if canonical:
        original_files = {p.name: p for p in canonical.glob('[0-9][0-9]-*.md')}
        if set(original_files) != {p.name for p in numbered}:
            raise ValueError('Packaged source file names differ from the canonical base')
        for path in numbered:
            if path.read_bytes() != original_files[path.name].read_bytes():
                raise ValueError('Packaged source differs from canonical base: ' + path.name)
    records = json.loads((ROOT / 'knowledge-provenance.json').read_text(encoding='utf-8'))
    if len(records) != 18:
        raise ValueError('Expected provenance for 18 teaching documents')
    used = set()
    outputs = set()
    for record in records:
        if not record['shared_sources']:
            raise ValueError('Teaching document has no canonical source: ' + record['file'])
        if record['file'] in outputs:
            raise ValueError('Duplicate teaching document record: ' + record['file'])
        outputs.add(record['file'])
        output = ROOT / 'stage3-knowledge' / record['file']
        if digest(output) != record['sha256']:
            raise ValueError('Teaching document changed after review: ' + record['file'])
        supplement = (ROOT.parent / record['native_supplement']).resolve()
        if supplement != (ROOT.parent / '[下发文件]考核-需求开发文档.md').resolve() or not supplement.is_file():
            raise ValueError('Teaching supplement is missing from this package: ' + record['file'])
        text = output.read_text(encoding='utf-8')
        for source in record['shared_sources']:
            path = (ROOT.parent / source['file']).resolve()
            if path.parent != source_dir.resolve() or not path.is_file():
                raise ValueError('Packaged source path is invalid: ' + source['file'])
            name = path.name
            if digest(path) != source['sha256'] or '## ' + source['heading'] not in path.read_text(encoding='utf-8'):
                raise ValueError('Source or section changed after review: ' + name)
            if name not in text:
                raise ValueError('Source citation missing from teaching document: ' + record['file'])
            used.add(name)
    if used != {p.name for p in numbered}:
        raise ValueError('Not all eight canonical documents are represented')
    if outputs != {p.name for p in (ROOT / 'stage3-knowledge').glob('*.md')}:
        raise ValueError('Teaching document list differs from provenance')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--canonical', type=Path, help='Optional path to proj2-2-OCMS/base/dify-knowledge-import')
    args = parser.parse_args()
    verify(args.canonical)
    print('8 source files and 18 teaching documents verified')
