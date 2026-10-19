#!/usr/bin/env python3
"""Sign and verify BigMouse with its pinned public certificate identity."""
import hashlib
import json
import pathlib
import plistlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = json.loads((ROOT / 'config/signing.json').read_text())
IDENTIFIER = CONFIG['bundleIdentifier']
SHA1 = CONFIG['certificateSHA1']
SHA256 = CONFIG['certificateSHA256']
if not re.fullmatch(r'[A-F0-9]{40}', SHA1) or not re.fullmatch(r'[A-F0-9]{64}', SHA256):
    raise SystemExit('Invalid signing certificate fingerprint / 서명 인증서 지문 오류')
if IDENTIFIER != 'com.jvisualschool.BigMouse':
    raise SystemExit('Unexpected bundle identifier / 앱 식별자 오류')
REQUIREMENT = f'identifier "{IDENTIFIER}" and certificate leaf = H"{SHA1.lower()}"'


def run(args):
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout


def check_identity():
    identities = run(['security', 'find-identity', '-p', 'codesigning'])
    if SHA1 not in identities:
        raise RuntimeError('The BigMouse signing key is missing. Restore it from Keychain backup. '
                           '서명 키가 없습니다. 키체인 백업에서 복원하세요. '
                           'For an isolated local build / 별도 개발 빌드: bash build.sh --development')


def verify(app):
    with (app / 'Contents/Info.plist').open('rb') as stream:
        info = plistlib.load(stream)
    if info.get('CFBundleIdentifier') != IDENTIFIER:
        raise RuntimeError('Wrong bundle identifier / 앱 식별자가 다릅니다')
    run(['codesign', '--verify', '--strict', '-R', '=' + REQUIREMENT, str(app)])
    with tempfile.TemporaryDirectory(prefix='bigmouse-public-cert-') as folder:
        prefix = str(pathlib.Path(folder) / 'certificate')
        run(['codesign', '--display', '--extract-certificates=' + prefix, str(app)])
        certificate = pathlib.Path(prefix + '0').read_bytes()
        if hashlib.sha256(certificate).hexdigest().upper() != SHA256:
            raise RuntimeError('Signing certificate changed / 서명 인증서가 변경되었습니다')


def main():
    command, *paths = sys.argv[1:]
    if command == 'check' and not paths:
        check_identity()
    elif command == 'sign' and len(paths) == 1:
        check_identity()
        app = pathlib.Path(paths[0]).resolve()
        run(['codesign', '--force', '--sign', SHA1, '--timestamp=none', str(app)])
        verify(app)
    elif command == 'verify' and len(paths) == 1:
        verify(pathlib.Path(paths[0]).resolve())
    elif command == 'verify-update' and len(paths) == 2:
        for path in paths:
            verify(pathlib.Path(path).resolve())
        print('Both builds satisfy the same certificate-bound identity. / 두 빌드의 고정 서명이 일치합니다.')
    else:
        raise RuntimeError('Usage: signing.py check | sign APP | verify APP | verify-update OLD NEW')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
