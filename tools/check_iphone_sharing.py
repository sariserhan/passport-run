#!/usr/bin/env python3
"""Exercise the exact native share bridge in an isolated temporary iPhone simulator."""
import json
import plistlib
from pathlib import Path
import subprocess
import tempfile
import time
ROOT = Path(__file__).resolve().parents[1]
def run(*args):
    return subprocess.check_output(args, text=True).strip()
def main():
    runtime = next(r['identifier'] for r in json.loads(run('xcrun','simctl','list','runtimes','--json'))['runtimes'] if r.get('isAvailable') and r['name'].startswith('iOS'))
    device_type = next(d['identifier'] for d in json.loads(run('xcrun','simctl','list','devicetypes','--json'))['devicetypes'] if d['name'] == 'iPhone 17 Pro')
    device = run('xcrun','simctl','create','PassportRun-Share-Smoke',device_type,runtime)
    print('Created isolated sharing simulator', flush=True)
    try:
        run('xcrun','simctl','boot',device)
        subprocess.run(['xcrun','simctl','bootstatus',device,'-b'],check=True)
        with tempfile.TemporaryDirectory(prefix='passport-share-') as directory:
            app = Path(directory) / 'PassportShareSmoke.app'
            app.mkdir()
            info = {'CFBundleIdentifier':'com.serhansari.passportrun.share-smoke','CFBundleExecutable':'PassportShareSmoke','CFBundleName':'PassportShareSmoke','CFBundleVersion':'1','CFBundleShortVersionString':'1.0','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'MinimumOSVersion':'16.0','UIDeviceFamily':[1],'UILaunchScreen':{}}
            (app/'Info.plist').write_bytes(plistlib.dumps(info))
            sdk = run('xcrun','--sdk','iphonesimulator','--show-sdk-path')
            subprocess.run(['xcrun','--sdk','iphonesimulator','clang','-fobjc-arc','-target','arm64-apple-ios16.0-simulator','-isysroot',sdk,'-framework','UIKit','-framework','Foundation','-framework','CoreGraphics',str(ROOT/'tests/ios_share_smoke.m'),'-o',str(app/'PassportShareSmoke')],check=True)
            subprocess.run(['codesign','--force','--sign','-',str(app)],check=True)
            run('xcrun','simctl','install',device,str(app))
            run('xcrun','simctl','launch',device,info['CFBundleIdentifier'])
            container = Path(run('xcrun','simctl','get_app_container',device,info['CFBundleIdentifier'],'data'))
            result_path = container/'Documents/native-smoke-result.json'
            deadline = time.monotonic()+30
            while not result_path.exists() and time.monotonic()<deadline: time.sleep(.25)
            if not result_path.exists(): raise RuntimeError('Native share smoke test did not finish')
            result = json.loads(result_path.read_text())
            print(json.dumps(result), flush=True)
            if not all(result.values()): raise RuntimeError('Native share smoke check failed')
            print('iPhone share sheet and cancellation checks passed', flush=True)
    finally:
        subprocess.run(['xcrun','simctl','shutdown',device],check=False,stdout=subprocess.DEVNULL)
        subprocess.run(['xcrun','simctl','delete',device],check=False)
if __name__ == '__main__': main()
