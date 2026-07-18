import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


HOOK = Path(__file__).with_name("runcat-hook.py")


def run_hook(output, transcript):
    subprocess.run(
        [HOOK],
        input=json.dumps({"model": "test-model", "transcript_path": str(transcript)}),
        text=True,
        check=True,
        capture_output=True,
        env={**os.environ, "RUNCAT_OUT_FILE": str(output)},
    )


class RunCatHookTest(unittest.TestCase):
    def test_missing_token_count_preserves_last_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            output = directory / "usage.json"
            transcript = directory / "empty.jsonl"
            previous = {"title": "Codex", "metrics": [{"title": "7d left", "formattedValue": "94%"}]}
            output.write_text(json.dumps(previous), encoding="utf-8")
            transcript.write_text("", encoding="utf-8")

            run_hook(output, transcript)

            self.assertEqual(json.loads(output.read_text(encoding="utf-8")), previous)

    def test_model_without_rate_limit_preserves_last_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            output = directory / "usage.json"
            transcript = directory / "session.jsonl"
            previous = {"title": "Codex", "metrics": [{"title": "7d left", "formattedValue": "94%"}]}
            output.write_text(json.dumps(previous), encoding="utf-8")
            transcript.write_text(
                json.dumps(
                    {
                        "payload": {
                            "type": "token_count",
                            "info": {"last_token_usage": {"total_tokens": 25}, "model_context_window": 100},
                            "rate_limits": {},
                        }
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            run_hook(output, transcript)

            self.assertEqual(json.loads(output.read_text(encoding="utf-8")), previous)

    def test_rate_limit_is_remaining_percentage(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            output = directory / "usage.json"
            transcript = directory / "session.jsonl"
            transcript.write_text(
                json.dumps(
                    {
                        "payload": {
                            "type": "token_count",
                            "info": {"last_token_usage": {"total_tokens": 25}, "model_context_window": 100},
                            "rate_limits": {
                                "primary": {"used_percent": 6, "window_minutes": 10080},
                                "secondary": None,
                            },
                        }
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            run_hook(output, transcript)
            snapshot = json.loads(output.read_text(encoding="utf-8"))

            self.assertIn(
                {"title": "7d left", "formattedValue": "94%", "normalizedValue": 0.94},
                snapshot["metrics"],
            )
            self.assertEqual(snapshot["metricsBarValue"], "94%")


if __name__ == "__main__":
    unittest.main()
