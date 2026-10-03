import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("exporter", ROOT / "tools/export_iphone.py")
exporter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(exporter)


class NativeExportTest(unittest.TestCase):
    def test_links_preserve_existing_plugin_registration(self):
        with tempfile.TemporaryDirectory() as folder:
            directory = Path(folder)
            (directory / "PassportRun.xcodeproj").mkdir()
            (directory / "PassportRun").mkdir()
            project = directory / "PassportRun.xcodeproj/project.pbxproj"
            project.write_text("lastKnownFileType = sourcecode.cpp.cpp; path = dummy.cpp;")
            (directory / "PassportRun/dummy.cpp").write_text("void godot_apple_embedded_plugins_initialize() { register_godot_storekit2_types(); }")
            info = directory / "PassportRun/PassportRun-Info.plist"
            info.write_bytes(plistlib.dumps({"CFBundleIdentifier": "com.serhansari.passportrun"}))
            exporter.patch_project(directory)
            source = (directory / "PassportRun/dummy.mm").read_text()
            self.assertIn("register_godot_storekit2_types();", source)
            self.assertIn("passportOpenURL", source)
            self.assertIn("dummy.mm", project.read_text())
            data = plistlib.loads(info.read_bytes())
            self.assertEqual(data["CFBundleIdentifier"], "com.serhansari.passportrun")
            self.assertEqual(data["CFBundleURLTypes"][0]["CFBundleURLSchemes"], ["passport-run"])


if __name__ == "__main__":
    unittest.main()
