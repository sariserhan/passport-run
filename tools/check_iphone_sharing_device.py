#!/usr/bin/env python3
"""Check native picture-sharing presentation on an explicitly selected paired iPhone.
Uses a separate test app and an existing provisioning profile; never replaces the game.
"""
import argparse
import hashlib
import json
import plistlib
from pathlib import Path
import subprocess
import tempfile
import time
ROOT = Path(__file__).resolve().parents[1]
BUNDLE = 'com.serhansari.passportrun.share-smoke'
def run(*args): return subprocess.check_output(args, text=True).strip()
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--device', required=True)
    parser.add_argument('--profile', type=Path, required=True)
    args = parser.parse_args()
    provisioning = plistlib.loads(subprocess.check_output(['security','cms','-D','-i',str(args.profile)]))
    if args.device not in provisioning.get('ProvisionedDevices',[]): raise RuntimeError('Existing profile does not include this device')
    identities = run('security','find-identity','-v','-p','codesigning')
    signer = next((hashlib.sha1(cert).hexdigest().upper() for cert in provisioning['DeveloperCertificates'] if hashlib.sha1(cert).hexdigest().upper() in identities), None)
    if not signer: raise RuntimeError('No matching local signing identity')
    with tempfile.TemporaryDirectory(prefix='passport-device-share-') as directory:
        app = Path(directory)/'PassportShareSmoke.app'
        app.mkdir()
        info = {'CFBundleIdentifier':BUNDLE,'CFBundleExecutable':'PassportShareSmoke','CFBundleName':'Passport Share Test','CFBundleVersion':'1','CFBundleShortVersionString':'1.0','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'MinimumOSVersion':'16.0','UIDeviceFamily':[1],'UILaunchScreen':{},'CFBundleSupportedPlatforms':['iPhoneOS']}
        (app/'Info.plist').write_bytes(plistlib.dumps(info))
        (app/'embedded.mobileprovision').write_bytes(args.profile.read_bytes())
        entitlement = provisioning['Entitlements'].copy()
        prefix = provisioning['ApplicationIdentifierPrefix'][0]
        entitlement['application-identifier'] = prefix+'.'+BUNDLE
        if 'keychain-access-groups' in entitlement: entitlement['keychain-access-groups'] = [prefix+'.'+BUNDLE]
        entitlements = Path(directory)/'entitlements.plist'
        entitlements.write_bytes(plistlib.dumps(entitlement))
        sdk = run('xcrun','--sdk','iphoneos','--show-sdk-path')
        subprocess.run(['xcrun','--sdk','iphoneos','clang','-fobjc-arc','-target','arm64-apple-ios16.0','-isysroot',sdk,'-framework','UIKit','-framework','Foundation','-framework','CoreGraphics',str(ROOT/'tests/ios_share_smoke.m'),'-o',str(app/'PassportShareSmoke')],check=True)
        subprocess.run(['codesign','--force','--sign',signer,'--entitlements',str(entitlements),str(app)],check=True)
        installed = False
        try:
            subprocess.run(['xcrun','devicectl','device','install','app','--device',args.device,str(app),'--timeout','30'],check=True)
            installed = True
            subprocess.run(['xcrun','devicectl','device','process','launch','--device',args.device,BUNDLE,'--timeout','30'],check=True)
            result = Path(directory)/'result.json'
            deadline = time.monotonic()+30
            while time.monotonic()<deadline:
                time.sleep(1)
                command = ['xcrun','devicectl','device','copy','from','--device',args.device,'--domain-type','appDataContainer','--domain-identifier',BUNDLE,'--source','Documents/native-smoke-result.json','--destination',str(result),'--timeout','10']
                attempt = subprocess.run(command,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                if attempt.returncode == 0 and result.exists(): break
            if not result.exists(): raise RuntimeError('Physical sharing test did not finish; unlock the phone and retry')
            report = json.loads(result.read_text())
            print(json.dumps(report),flush=True)
            if not all(report.values()): raise RuntimeError('Physical native sharing check failed')
            print('Physical iPhone share-sheet presentation and cancellation handler passed',flush=True)
        finally:
            if installed: subprocess.run(['xcrun','devicectl','device','uninstall','app','--device',args.device,BUNDLE,'--timeout','20'],check=False)
if __name__ == '__main__': main()
