import os
import sys
import tempfile
import unittest
import base64
import importlib.machinery
import importlib.util

cli_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts", "hermes-api"))
loader = importlib.machinery.SourceFileLoader("hermes_api", cli_path)
spec = importlib.util.spec_from_loader("hermes_api", loader)
hermes_api = importlib.util.module_from_spec(spec)
loader.exec_module(hermes_api)

class TestHermesAPI(unittest.TestCase):
    def test_parse_extended_args_simple(self):
        prompt, session, model, files, images, stream, extract_media, stop_on_interrupt, auto_fork = hermes_api.parse_extended_args(["do", "something"])
        self.assertEqual(prompt, "do something")
        self.assertIsNone(session)
        self.assertEqual(model, "hermes-agent")
        self.assertEqual(files, [])
        self.assertEqual(images, [])
        self.assertFalse(stream)
        self.assertIsNone(extract_media)
        self.assertFalse(stop_on_interrupt)
        self.assertFalse(auto_fork)

    def test_parse_extended_args_with_files_and_stream(self):
        with tempfile.NamedTemporaryFile("w", delete=False) as tf:
            tf.write("test content\nline 2")
            tf_path = tf.name
        try:
            prompt, session, model, files, images, stream, extract_media, stop_on_interrupt, auto_fork = hermes_api.parse_extended_args([
                "review", "-f", tf_path, "--stream", "--session", "sess_1", "--extract-media", "/tmp/out", "--stop-on-interrupt", "--fork"
            ])
            self.assertEqual(prompt, "review")
            self.assertEqual(session, "sess_1")
            self.assertTrue(stream)
            self.assertEqual(extract_media, "/tmp/out")
            self.assertTrue(stop_on_interrupt)
            self.assertTrue(auto_fork)
            self.assertEqual(len(files), 1)
            self.assertEqual(files[0]["content"], "test content\nline 2")
        finally:
            os.remove(tf_path)

    def test_encode_image_file(self):
        with tempfile.NamedTemporaryFile("wb", suffix=".png", delete=False) as tf:
            tf.write(b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR")
            tf_path = tf.name
        try:
            data_url = hermes_api.encode_image_file(tf_path)
            self.assertTrue(data_url.startswith("data:image/png;base64,"))
            raw = base64.b64decode(data_url.split(",")[1])
            self.assertTrue(raw.startswith(b"\x89PNG"))
        finally:
            os.remove(tf_path)

    def test_extract_media_from_text(self):
        sample_b64 = base64.b64encode(b"fake-image-bytes").decode("ascii")
        md = f"Here is the chart: ![my_chart](data:image/png;base64,{sample_b64})"
        with tempfile.TemporaryDirectory() as td:
            saved = hermes_api.extract_media_from_text(md, output_dir=td)
            self.assertEqual(len(saved), 1)
            self.assertTrue(os.path.isfile(saved[0]))
            with open(saved[0], "rb") as f:
                self.assertEqual(f.read(), b"fake-image-bytes")

    def test_build_combined_user_message(self):
        files = [{"name": "foo.py", "content": "print('hello')"}]
        images = ["data:image/png;base64,AAAA"]
        msg = hermes_api.build_combined_user_message("check this", files, images)
        self.assertIn("check this", msg)
        self.assertIn("--- Attachment: foo.py", msg)
        self.assertIn("print('hello')", msg)
        self.assertIn("![image](data:image/png;base64,AAAA)", msg)

    def test_read_text_attachment_validates_size(self):
        with tempfile.NamedTemporaryFile("w", delete=False) as tf:
            tf.write("small text")
            tf_path = tf.name
        try:
            att = hermes_api.read_text_attachment(tf_path)
            self.assertEqual(att["name"], os.path.basename(tf_path))
            self.assertEqual(att["content"], "small text")
        finally:
            os.remove(tf_path)

    def test_read_text_attachment_rejects_missing(self):
        with self.assertRaises(SystemExit):
            hermes_api.read_text_attachment("/nonexistent/file/path.txt")

    def test_format_permission_denied_help(self):
        msg = hermes_api.format_session_permission_denied_msg("sess_123", "desktop")
        self.assertIn("sess_123", msg)
        self.assertIn("desktop", msg)
        self.assertIn("hermes-api fork sess_123", msg)
        self.assertIn("--fork", msg)

if __name__ == "__main__":
    unittest.main()
