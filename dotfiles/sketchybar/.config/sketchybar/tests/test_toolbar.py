import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("toolbar", Path(__file__).resolve().parents[1] / "plugins/toolbar.py")
t = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t)


class ToolbarTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        for attr, path in (("DATA", root), ("CACHE", root), ("STATE", root / "features.json"),
                           ("PRIVATE", root / "presentation"), ("COMPACT", root / "compact")):
            p = patch.object(t, attr, path)
            p.start()
            self.addCleanup(p.stop)
        self.calls = []
        def run(*args, **kwargs):
            self.calls.append(args)
            return "{}"
        self.runner = patch.object(t, "run", side_effect=run).start()
        self.addCleanup(patch.stopall)
        self.popen = patch.object(t.subprocess, "Popen").start()

    def cache(self, events, updated=10000, status="ready"):
        t.write(t.CACHE / "calendar.json", {"updated": updated, "status": status, "events": events})

    def event(self, start, end=None, title="Private project"):
        return {"start": start, "end": end or start + 1800, "title": title, "url": "https://meet.google.com/abc-defg-hij"}

    def test_meeting_window(self):
        self.cache([self.event(11801), self.event(10600), self.event(11200)])
        self.assertEqual(t.meeting({}, 10000)["start"], 10600)

    def test_meeting_excludes_stale_ended_and_old(self):
        self.cache([self.event(9699), self.event(9990, 9999), self.event(11801)])
        self.assertIsNone(t.meeting({}, 10000))
        self.cache([self.event(10600)], updated=9700)
        self.assertIsNone(t.meeting({}, 10000))
        self.cache([self.event(10600)], status="permission_denied")
        self.assertIsNone(t.meeting({}, 10000))

    def test_join_link_validation(self):
        for good in ("https://meet.google.com/a", "https://company.zoom.us/j/12", "https://teams.microsoft.com/l/meetup-join/a"):
            self.assertTrue(t.safe_meeting_url(good))
        for bad in (None, "", "file:///etc/passwd", "https://zoom.us.evil.test/j", "https://user:pass@zoom.us/j", "javascript:alert(1)"):
            self.assertFalse(t.safe_meeting_url(bad))

    def test_meeting_click_opens_link_as_one_argument(self):
        self.cache([self.event(10600)])
        with patch.object(t.time, "time", return_value=10000):
            t.open_meeting({})
        self.assertEqual(self.calls[-1], ("/usr/bin/open", "https://meet.google.com/abc-defg-hij"))

    def test_meeting_without_link_opens_calendar_workspace(self):
        event = self.event(10600)
        del event["url"]
        self.cache([event])
        with patch.object(t.time, "time", return_value=10000), patch.object(t, "workspace") as workspace:
            t.open_meeting({})
        workspace.assert_called_once_with({}, "7")

    def test_stale_meeting_never_opens_old_link(self):
        self.cache([self.event(10600)], updated=9000)
        with patch.object(t.time, "time", return_value=10000):
            t.open_meeting({})
        self.assertFalse(any(call[0] == "/usr/bin/open" for call in self.calls))

    def test_granola_visibility_and_render_never_start_recording(self):
        for always, has_meeting in ((False, False), (True, False), (False, True), (True, True)):
            with self.subTest(always=always, meeting=has_meeting):
                self.cache([self.event(10600)] if has_meeting else [])
                with patch.object(t.time, "time", return_value=10000):
                    t.render({"granola_always_show": always})
                call = self.calls[-1]
                self.assertEqual(call[call.index("granola") + 1],
                                 "drawing=on" if always or has_meeting else "drawing=off")
        self.assertFalse(any(call[0] == "/usr/bin/open" for call in self.calls))

    def test_granola_setting_persists_without_recording(self):
        for enabled in (True, False):
            with patch.object(t.sys, "argv", ["toolbar.py", "granola-toggle"]):
                t.main()
            self.assertEqual(t.read(t.STATE)["granola_always_show"], enabled)
        self.assertFalse(any(call[0] == "/usr/bin/open" for call in self.calls))

    def test_granola_records_without_calendar_and_debounces_clicks(self):
        state = {}
        with patch.object(t.time, "time", return_value=10000):
            t.record_with_granola(state)
            t.record_with_granola(state)
        opens = [call for call in self.calls if call[0] == "/usr/bin/open"]
        self.assertEqual(opens, [("/usr/bin/open", "-a", "Granola",
                                  "granola://new-document?auto_transcribe=1")])

    def test_granola_failed_launch_can_retry_immediately(self):
        state = {}
        with patch.object(t, "close_popups"), \
             patch.object(t, "run", side_effect=OSError), self.assertRaises(OSError):
            t.record_with_granola(state)
        self.assertNotIn("granola_last_launch", state)

    def test_meeting_record_rechecks_cache(self):
        self.cache([self.event(10600)], updated=9000)
        with patch.object(t.time, "time", return_value=10000):
            t.record_with_granola({}, meeting_only=True)
        self.assertFalse(any(call[0] == "/usr/bin/open" for call in self.calls))
        self.cache([self.event(10600)])
        with patch.object(t.time, "time", return_value=10000):
            t.record_with_granola({}, meeting_only=True)
        self.assertEqual(self.calls[-1], ("/usr/bin/open", "-a", "Granola", t.GRANOLA_RECORD_URL))

    def test_granola_actions_available_in_both_menus(self):
        t.controls_popup({})
        self.assertIn("label=Record with Granola", self.calls[-1])
        self.assertIn("label=Granola · always show record icon · OFF", self.calls[-1])
        self.cache([self.event(10600)])
        with patch.object(t.time, "time", return_value=10000):
            t.meeting_popup({})
        self.assertIn("label=Record with Granola", self.calls[-1])
        self.assertIn("click_script=" + t.command("meeting-record"), self.calls[-1])

    def test_permission_worker_restarts_only_its_calendar_reader(self):
        def run(*args, **kwargs):
            self.calls.append(args)
            return "123" if args[0] == "/usr/bin/pgrep" else ""
        self.runner.side_effect = run
        with patch.object(t, "identity", side_effect=["reader", "reader", ""]), \
             patch.object(t.os, "kill") as kill, patch.object(t.subprocess, "run") as process:
            t.calendar_authorization()
        kill.assert_called_once_with(123, t.signal.SIGTERM)
        process.assert_called_once()
        self.assertEqual(self.calls[-1], ("/usr/bin/open", "-gj", str(t.APP), "--args", "watch"))

    def test_presentation_survives_refresh_and_hides_titles(self):
        self.cache([self.event(10600)])
        t.PRIVATE.touch()
        state = {"media": {"state": "playing", "title": "Secret song", "artist": "Artist"}}
        with patch.object(t.time, "time", return_value=10000):
            t.render(state)
            t.meeting_popup(state)
        call = self.calls[0]
        self.assertIn("label=10m", call)
        self.assertNotIn("label=10m Private project", call)
        self.assertIn("label=Upcoming meeting", self.calls[-1])
        self.assertNotIn("label=Private project", self.calls[-1])
        # Hidden media must also avoid retaining its title in the displayed label.
        media = call.index("media")
        self.assertEqual(call[media + 1], "drawing=off")

    def test_compact_restored_on_every_render(self):
        t.COMPACT.touch()
        t.render({})
        call = self.calls[-1]
        self.assertIn("padding_left=8", call)
        self.assertIn("label.drawing=off", call)
        self.assertIn("icon.drawing=off", call)
        self.assertIn("label.max_chars=8", call)

    def test_timer_completion_signals_once(self):
        state = {"timer": {"kind": "focus", "until": 9999}}
        with patch.object(t.time, "time", return_value=10000):
            t.render(state)
            t.render(state)
        self.assertTrue(state["timer"]["done"])
        self.assertEqual(self.popen.call_count, 1)
        self.assertIn("label=DONE", self.calls[-1])

    def test_timer_countdown(self):
        with patch.object(t.time, "time", return_value=10000):
            t.render({"timer": {"kind": "break", "until": 10061}})
        self.assertIn("label=01:01", self.calls[-1])
        self.assertIn("update_freq=1", self.calls[-1])

    def test_awake_never_kills_reused_pid(self):
        state = {"awake": {"pid": 123, "identity": "old process", "until": 5}}
        with patch.object(t, "identity", return_value="unrelated process"), patch.object(t.os, "kill") as kill:
            t.stop_awake(state)
        kill.assert_not_called()
        self.assertNotIn("awake", state)

    def test_awake_stops_owned_process(self):
        with patch.object(t, "identity", return_value="owned"), patch.object(t.os, "kill") as kill:
            t.stop_awake({"awake": {"pid": 123, "identity": "owned"}})
        kill.assert_called_once_with(123, t.signal.SIGTERM)

    def workspace_runner(self, occupied=0, windows=None, focus="6"):
        def run(*args, **kwargs):
            self.calls.append(args)
            if "list-workspaces" in args:
                return focus
            if "--count" in args:
                return str(occupied)
            if "list-windows" in args:
                return json.dumps(windows or [])
            return ""
        self.runner.side_effect = run

    def test_empty_chat_launches_once(self):
        self.workspace_runner()
        state = {}
        t.workspace(state, "6")
        t.workspace(state, "6")
        opens = [call for call in self.calls if call[0] == "/usr/bin/open"]
        self.assertEqual([call[-1] for call in opens], t.APPS["6"])

    def test_occupied_workspace_does_not_launch(self):
        self.workspace_runner(occupied=1)
        t.workspace({}, "6")
        self.assertFalse(any(call[0] == "/usr/bin/open" for call in self.calls))

    def test_existing_app_moves_without_duplicate_launch(self):
        self.workspace_runner(windows=[{"window-id": 42, "app-bundle-id": t.APPS["6"][0]}])
        t.workspace({}, "6")
        self.assertIn((t.AS, "move-node-to-workspace", "6", "--window-id", "42"), self.calls)
        opens = [call for call in self.calls if call[0] == "/usr/bin/open"]
        self.assertEqual(len(opens), 1)
        self.assertEqual(opens[0][-1], t.APPS["6"][1])

    def test_late_workspace_callback_does_not_launch(self):
        self.workspace_runner(focus="1")
        t.workspace({}, "6", False)
        self.assertFalse(any(call[0] == "/usr/bin/open" for call in self.calls))

    def test_display_profiles_round_trip(self):
        external = {"id": 4, "index": 1, "main": True, "builtin": False, "width": 3440, "height": 1440}
        laptop = {"id": 1, "index": 1, "main": True, "builtin": True, "width": 1512, "height": 982}
        screens = [external]
        layout = ["v_tiles"]
        def run(*args, **kwargs):
            self.calls.append(args)
            if "screens" in args:
                return json.dumps(screens)
            if "list-workspaces" in args:
                return json.dumps([{"workspace": "1", "monitor-appkit-nsscreen-screens-id": 1, "workspace-root-container-layout": layout[0]}])
            if "list-windows" in args:
                return json.dumps([{"workspace": "1"}] * 3)
            if "layout" in args:
                layout[0] = args[-1]
            return ""
        self.runner.side_effect = run
        state = {"profile": t.profile_key(screens)}
        screens[:] = [laptop]
        t.update_profile(state, 100)
        self.assertEqual(layout[0], "v_tiles")  # debounce
        t.update_profile(state, 111)
        self.assertEqual(layout[0], "h_accordion")
        self.assertTrue(t.COMPACT.exists())
        screens[:] = [external]
        t.update_profile(state, 122)
        t.update_profile(state, 133)
        self.assertEqual(layout[0], "v_tiles")  # user's saved docked layout
        self.assertFalse(t.COMPACT.exists())

    def test_audio_device_names_are_data(self):
        def run(*args, **kwargs):
            self.calls.append(args)
            if "audio-list" in args:
                return json.dumps([{"id": 4, "name": "Output $(touch /tmp/unwanted)", "selected": True}])
            return "{}"
        self.runner.side_effect = run
        t.audio_popup()
        self.assertIn("label=●  Output $(touch /tmp/unwanted)", self.calls[-1])
        click = next(arg for arg in self.calls[-1] if str(arg).startswith("click_script="))
        self.assertNotIn("touch", click)
        self.assertTrue(click.endswith("audio-set 4"))


if __name__ == "__main__":
    unittest.main()
