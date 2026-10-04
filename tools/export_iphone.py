#!/usr/bin/env python3
"""Export Godot and add the small native challenge-link receiver to Xcode."""
import argparse
import os
from pathlib import Path
import plistlib
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def patch_project(directory):
    project = directory / 'PassportRun.xcodeproj/project.pbxproj'
    text = project.read_text()
    # Reuse Godot's generated C++ source entry; no extra plugin/header dependencies.
    source = directory / 'PassportRun/dummy.cpp'
    source.with_suffix('.mm').write_text(source.read_text() + '\n' + (ROOT / 'ios/native/PassportLinks.m').read_text() + '\n' + (ROOT / 'ios/native/PassportShare.m').read_text())
    text = text.replace('dummy.cpp', 'dummy.mm').replace('lastKnownFileType = sourcecode.cpp.cpp;', 'lastKnownFileType = sourcecode.cpp.objcpp;')
    project.write_text(text)
    info = directory / 'PassportRun/PassportRun-Info.plist'
    data = plistlib.loads(info.read_bytes())
    data['CFBundleURLTypes'] = [{'CFBundleURLName': 'com.serhansari.passportrun.challenge', 'CFBundleURLSchemes': ['passport-run']}]
    data.setdefault('NSPhotoLibraryAddUsageDescription', 'Save your travel room, album pages and journal postcards to Photos.')
    info.write_bytes(plistlib.dumps(data))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('directory', type=Path)
    parser.add_argument('--release', action='store_true', help='Use the release template (App Store/TestFlight builds).')
    args = parser.parse_args()
    output = args.directory.resolve()
    output.mkdir(parents=True, exist_ok=True)
    subprocess.run([os.environ.get('GODOT_BIN', '/Applications/Godot.app/Contents/MacOS/Godot'), '--headless', '--path', str(ROOT), '--export-release' if args.release else '--export-debug', 'iPhone', str(output / 'PassportRun.zip')], check=True)
    if (output / 'admob_spm').is_dir():  # Google Mobile Ads via Swift Package Manager
        subprocess.run([os.environ.get('GODOT_BIN', '/Applications/Godot.app/Contents/MacOS/Godot'), '--headless', '--path', str(ROOT), '--script', 'tools/patch_admob_spm.gd', '--', str(output / 'PassportRun.xcodeproj/project.pbxproj')], check=True)
    patch_project(output)
