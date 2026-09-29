"""Local controls for SketchyBar. External names and URLs never become shell code."""
import contextlib
import fcntl
import json
import math
import os
from pathlib import Path
import re
import shlex
import signal
import subprocess
import sys
import time
from urllib.parse import urlparse

CONFIG = Path(os.environ.get("CONFIG_DIR", Path.home() / ".config/sketchybar"))
DATA = Path.home() / "Library/Application Support/AeroToolbar"
CACHE = Path.home() / "Library/Caches/AeroToolbar"
APP = DATA / "ToolbarBridge.app"
BRIDGE = APP / "Contents/MacOS/ToolbarBridge"
SCRIPT = CONFIG / "plugins/toolbar.sh"
SB = "/opt/homebrew/bin/sketchybar"
AS = "/opt/homebrew/bin/aerospace"
STATE = DATA / "features.json"
PRIVATE = DATA / "presentation"
COMPACT = DATA / "compact"
ACCENT = os.environ.get("ACCENT_COLOR", "0xffff9d4d")
MUTED = os.environ.get("MUTED_COLOR", "0xff8b9bb1")
WHITE = os.environ.get("WHITE", "0xffd7e0ee")
# Verified in Granola 7.576.0's desktop deep-link handler. Granola owns capture,
# permissions and stop/pause; launching this URL is not proof it is recording.
GRANOLA_RECORD_URL = "granola://new-document?auto_transcribe=1"
APPS = {
    "6": ["com.tinyspeck.slackmacgap", "com.google.Chrome.app.pommaclcbfghclhalboakcipcmmndhcj"],
    "7": ["com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep"],
    "8": ["com.google.Chrome.app.fmgjjmmmlfnkbppncabfkddbjimcfncm"],
}


def run(*args, check=True):
    return subprocess.run([str(a) for a in args], check=check, capture_output=True,
                          text=True, timeout=12).stdout.strip()


def read(path, default=None):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {} if default is None else default


def write(path, data):
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(data))
    temp.chmod(0o600)
    temp.replace(path)


def mark(path, enabled):
    if enabled:
        path.touch(mode=0o600)
    else:
        path.unlink(missing_ok=True)


@contextlib.contextmanager
def locked():
    for directory in (DATA, CACHE):
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (DATA / "controls.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = read(STATE)
        yield state
        write(STATE, state)


def command(*args):
    return shlex.join([str(SCRIPT)] + [str(a) for a in args])


def clean(text, limit=100):
    return " ".join(str(text).split())[:limit]


def set_item(args, name, **values):
    args.extend(["--set", name] + [f"{key}={value}" for key, value in values.items()])


def popup_row(args, name, parent, label, action=None, accent=False):
    args.extend(["--add", "item", name, "popup." + parent])
    set_item(args, name, label=label, **{
        "icon.drawing": "off", "label.color": ACCENT if accent else WHITE,
        "label.font": "SF Pro:Regular:13.0", "label.padding_left": 14,
        "label.padding_right": 14, "background.drawing": "off",
        "click_script": command(*action) if action else command("close"),
    })


def close_popups():
    run(SB, "--set", "controls", "popup.drawing=off",
        "--set", "volume", "popup.drawing=off",
        "--set", "meeting", "popup.drawing=off")


def controls_popup(state):
    visible = json.loads(run(SB, "--query", "controls")).get("popup", {}).get("drawing") == "on"
    close_popups()
    if visible:
        return
    args = ["--remove", "/^controls[.]row[.].*/"]
    rows = [
        ("Presentation mode · " + ("ON" if PRIVATE.exists() else "OFF"), ("presentation",)),
        ("Keep awake · 30 minutes", ("awake", "30")),
        ("Keep awake · 1 hour", ("awake", "60")),
        ("Keep awake · 2 hours", ("awake", "120")),
        ("Stop keeping awake", ("awake", "0")),
        ("Focus · 25 minutes", ("timer", "focus", "25")),
        ("Focus · 50 minutes", ("timer", "focus", "50")),
        ("Break · 5 minutes", ("timer", "break", "5")),
        ("Stop timer", ("timer", "stop")),
        ("Record with Granola", ("granola-record",)),
        ("Granola · always show record icon · " +
         ("ON" if state.get("granola_always_show", False) else "OFF"), ("granola-toggle",)),
        ("Calendar · connect Google account", ("calendar-connect",)),
        ("Calendar · allow toolbar access", ("calendar-authorize",)),
    ]
    status = read(CACHE / "calendar.json").get("status", "permission_needed")
    calendar_label = {"ready": "Calendar connected", "permission_needed": "Calendar access needed",
                      "permission_denied": "Calendar access disabled", "no_calendars": "Add a calendar account"}.get(status, "Calendar unavailable")
    rows.append((calendar_label, None))
    profile = state.get("profile_name", "Automatic")
    rows.append(("Display profile · " + profile, None))
    for i, (label, action) in enumerate(rows):
        popup_row(args, f"controls.row.{i}", "controls", label, action, i == 0 and PRIVATE.exists())
    args.extend(["--set", "controls", "popup.drawing=on"])
    run(SB, *args)


def audio_popup():
    visible = json.loads(run(SB, "--query", "volume")).get("popup", {}).get("drawing") == "on"
    close_popups()
    if visible:
        return
    devices = json.loads(run(BRIDGE, "audio-list"))
    args = ["--remove", "/^audio[.]output[.].*/"]
    for device in devices:
        device_id = int(device["id"])
        name = clean(device["name"])
        if sum(d["name"] == device["name"] for d in devices) > 1:
            name += " · " + clean(device.get("connection", "Output"))
        popup_row(args, f"audio.output.{device_id}", "volume",
                  ("●  " if device["selected"] else "○  ") + name,
                  ("audio-set", device_id), device["selected"])
    if not devices:
        popup_row(args, "audio.output.none", "volume", "No audio outputs available")
    args.extend(["--set", "volume", "popup.drawing=on"])
    run(SB, *args)


def identity(pid):
    try:
        return run("/bin/ps", "-p", str(int(pid)), "-o", "lstart=", "-o", "command=")
    except (ValueError, subprocess.SubprocessError):
        return ""


def stop_awake(state):
    awake = state.pop("awake", {})
    if awake.get("identity") and identity(awake.get("pid")) == awake["identity"]:
        try:
            os.kill(awake["pid"], signal.SIGTERM)
        except ProcessLookupError:
            pass


def start_awake(state, minutes):
    if minutes not in (0, 30, 60, 120):
        raise ValueError("Unsupported awake duration")
    stop_awake(state)
    if minutes:
        process = subprocess.Popen(["/usr/bin/caffeinate", "-di", "-t", str(minutes * 60)],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                   start_new_session=True)
        state["awake"] = {"pid": process.pid, "until": time.time() + minutes * 60,
                          "identity": identity(process.pid)}


def meeting(state, now):
    data = read(CACHE / "calendar.json")
    if data.get("status") != "ready" or now - data.get("updated", 0) > 180:
        return None
    candidates = [event for event in data.get("events", [])
                  if now - 300 < event.get("start", 0) <= now + 1800
                  and event.get("end", 0) > now]
    return min(candidates, key=lambda event: event["start"]) if candidates else None


def safe_meeting_url(value):
    try:
        url = urlparse(value)
        domains = ("meet.google.com", "zoom.us", "teams.microsoft.com", "teams.live.com",
                   "teams.cloud.microsoft", "webex.com", "whereby.com", "meet.jit.si", "huddles.slack.com")
        return url.scheme == "https" and not url.username and not url.password and any(
            url.hostname == domain or (url.hostname or "").endswith("." + domain) for domain in domains)
    except (TypeError, ValueError):
        return False


def calendar_authorization():
    """Wait outside the UI lock, then replace readers with cached permission state."""
    pattern = re.escape(str(BRIDGE) + " watch")
    pids = run("/usr/bin/pgrep", "-fx", pattern, check=False).split()
    readers = {int(pid): identity(pid) for pid in pids}
    subprocess.run(["/usr/bin/open", "-W", "-n", str(APP), "--args", "authorize"], check=True)
    for pid, before in readers.items():
        if before and identity(pid) == before:
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
    # Give Launch Services a moment to register the old process exit.
    for _ in range(20):
        if not any(identity(pid) == before for pid, before in readers.items() if before):
            break
        time.sleep(0.1)
    run("/usr/bin/open", "-gj", str(APP), "--args", "watch")


def open_meeting(state):
    current = meeting(state, time.time())
    close_popups()
    if current and safe_meeting_url(current.get("url")):
        run("/usr/bin/open", current["url"])
    elif current:
        workspace(state, "7")


def meeting_popup(state):
    current = meeting(state, time.time())
    close_popups()
    if not current:
        return
    args = ["--remove", "/^meeting[.]row[.].*/"]
    title = "Upcoming meeting" if PRIVATE.exists() else clean(current["title"], 70)
    popup_row(args, "meeting.row.title", "meeting", title)
    popup_row(args, "meeting.row.time", "meeting",
              time.strftime("%H:%M", time.localtime(current["start"])) + " – " +
              time.strftime("%H:%M", time.localtime(current["end"])))
    popup_row(args, "meeting.row.open", "meeting",
              "Open meeting link" if safe_meeting_url(current.get("url")) else "Open Calendar",
              ("meeting-open",), True)
    popup_row(args, "meeting.row.record", "meeting", "Record with Granola",
              ("meeting-record",), True)
    args.extend(["--set", "meeting", "popup.drawing=on"])
    run(SB, *args)


def record_with_granola(state, meeting_only=False):
    close_popups()
    now = time.time()
    if meeting_only and not meeting(state, now):
        return
    # Ignore accidental double clicks, without inventing a recording state.
    if now - state.get("granola_last_launch", 0) < 3:
        return
    run("/usr/bin/open", "-a", "Granola", GRANOLA_RECORD_URL)
    state["granola_last_launch"] = now


def workspace(state, name, switch=True):
    if name not in APPS:
        if switch:
            run(AS, "workspace", name)
        return
    if switch:
        run(AS, "workspace", name)
    if run(AS, "list-workspaces", "--focused") != name:
        return
    if int(run(AS, "list-windows", "--workspace", name, "--count")):
        return
    launches = state.setdefault("launches", {})
    if time.time() - launches.get(name, 0) < 20:
        return
    launches[name] = time.time()
    windows = json.loads(run(AS, "list-windows", "--all", "--format", "%{window-id} %{app-bundle-id}", "--json"))
    for bundle in APPS[name]:
        existing = [window for window in windows if window.get("app-bundle-id") == bundle]
        if existing:
            for window in existing:
                run(AS, "move-node-to-workspace", name, "--window-id", str(window["window-id"]))
        else:
            run("/usr/bin/open", "-g", "-b", bundle)


def profile_key(screens):
    # CoreGraphics numeric display IDs may change after reconnecting a cable.
    return json.dumps(sorted((s["builtin"], s["width"], s["height"], s["main"]) for s in screens))


def layout_default(screen, count):
    if screen["height"] > screen["width"]:
        return "v_tiles"
    return "h_accordion" if screen["builtin"] and count >= 3 else "h_tiles"


def update_profile(state, now):
    if now - state.get("profile_checked", 0) < 10:
        return
    state["profile_checked"] = now
    screens = json.loads(run(BRIDGE, "screens"))
    if not screens:
        return
    key = profile_key(screens)
    if key == state.get("profile"):
        return
    # Wait for monitor assignments to settle; transient disconnects do not reset layouts.
    if state.get("pending_profile") != key:
        state["pending_profile"] = key
        return
    workspaces = json.loads(run(AS, "list-workspaces", "--all", "--format",
                                "%{workspace} %{monitor-appkit-nsscreen-screens-id} %{workspace-root-container-layout}", "--json"))
    counts = json.loads(run(AS, "list-windows", "--all", "--format", "%{workspace}", "--json"))
    profiles = state.setdefault("layouts", {})
    if state.get("profile"):
        profiles[state["profile"]] = {w["workspace"]: w["workspace-root-container-layout"] for w in workspaces}
    saved = profiles.get(key, {})
    for ws in workspaces:
        screen = next((s for s in screens if s["index"] == ws["monitor-appkit-nsscreen-screens-id"]), None)
        if screen:
            name = ws["workspace"]
            target = saved.get(name, layout_default(screen, sum(w["workspace"] == name for w in counts)))
            if target != ws["workspace-root-container-layout"]:
                run(AS, "layout", "--workspace", name, "--root", target)
    main = next((screen for screen in screens if screen["main"]), screens[0])
    compact = main["builtin"] or main["width"] < 1800
    state["profile"] = key
    state["profile_name"] = "Docked" if any(not s["builtin"] for s in screens) else "Laptop"
    state["compact"] = compact
    mark(COMPACT, compact)
    run("/bin/bash", CONFIG / "plugins/notch_apply.sh")
    run(SB, "--bar", "display=main", "padding_left=" + ("8" if compact else "14"),
        "padding_right=" + ("8" if compact else "14"),
        "--set", "volume", "label.drawing=" + ("off" if compact else "on"),
        "--set", "calendar", "icon.drawing=" + ("off" if compact else "on"),
        "--set", "meeting", "label.max_chars=" + ("8" if compact else "32"),
        "--trigger", "aerospace_workspace_change")


def render(state):
    now = time.time()
    private = PRIVATE.exists()
    compact = COMPACT.exists()
    args = []
    # Reapply density after a bar reload even when display topology is unchanged.
    args.extend(["--bar", "display=main", "padding_left=" + ("8" if compact else "14"),
                 "padding_right=" + ("8" if compact else "14")])
    set_item(args, "volume", **{"label.drawing": "off" if compact else "on"})
    set_item(args, "calendar", **{"icon.drawing": "off" if compact else "on"})
    set_item(args, "meeting", **{"label.max_chars": 8 if compact else 32})
    set_item(args, "presentation", drawing="on" if private else "off")
    set_item(args, "controls", **{"icon.color": ACCENT if private else MUTED})
    try:
        front_app = clean((CACHE / "front_app.txt").read_text())
    except OSError:
        front_app = ""
    show_app = bool(front_app) and not private and not compact
    set_item(args, "front_app", drawing="on" if show_app else "off", label=front_app if show_app else "")
    awake = state.get("awake", {})
    if awake and (awake["until"] <= now or identity(awake["pid"]) != awake.get("identity")):
        stop_awake(state)
        awake = {}
    set_item(args, "awake", drawing="on" if awake else "off",
             label=f'{math.ceil((awake["until"] - now) / 60)}m' if awake else "")
    timer = state.get("timer", {})
    if timer:
        remaining = max(0, math.ceil(timer["until"] - now))
        if not remaining and not timer.get("done"):
            timer["done"] = True
            subprocess.Popen(["/usr/bin/afplay", "/System/Library/Sounds/Glass.aiff"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        label = f"{remaining // 60:02}:{remaining % 60:02}" if remaining else "DONE"
        set_item(args, "focus", drawing="on", label=label, icon="FOCUS" if timer["kind"] == "focus" else "BREAK")
    else:
        set_item(args, "focus", drawing="off")
    # Poll once per second only while a timer is active.
    set_item(args, "controls", update_freq=1 if timer and not timer.get("done") else 5)
    current = meeting(state, now)
    set_item(args, "granola", drawing="on" if current or state.get("granola_always_show", False) else "off")
    if current:
        minutes = math.ceil((current["start"] - now) / 60)
        countdown = f"{minutes}m" if minutes > 0 else "NOW"
        title = "" if private or compact else " " + clean(current["title"], 28)
        set_item(args, "meeting", drawing="on", label=countdown + title)
    else:
        set_item(args, "meeting", drawing="off")
    media = state.get("media", {})
    show_media = not private and not compact and media.get("state") == "playing"
    set_item(args, "media", drawing="on" if show_media else "off",
             label=clean(" – ".join(media.get(field) or "" for field in ("title", "artist"))) if show_media else "")
    run(SB, *args)


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "tick"
    sender = os.environ.get("SENDER", "")
    if action == "calendar-permission-worker":
        calendar_authorization()
        return
    if action == "event":
        if sender == "mouse.exited.global":
            close_popups()
            return
        action = "menu" if sender == "mouse.clicked" else "tick"
    with locked() as state:
        if action == "menu":
            controls_popup(state)
        elif action == "close":
            close_popups()
        elif action == "presentation":
            mark(PRIVATE, not PRIVATE.exists())
            close_popups()
            run(SB, "--remove", "/^meeting[.]row[.].*/", "--trigger", "aerospace_workspace_change")
        elif action == "awake":
            start_awake(state, int(sys.argv[2]))
            close_popups()
        elif action == "timer":
            kind = sys.argv[2]
            state.pop("timer", None)
            if kind in ("focus", "break"):
                minutes = int(sys.argv[3])
                if minutes not in (5, 25, 50):
                    raise ValueError("Unsupported timer duration")
                state["timer"] = {"kind": kind, "until": time.time() + minutes * 60}
            close_popups()
        elif action == "timer-click":
            timer = state.get("timer", {})
            if timer.get("done"):
                kind = "break" if timer["kind"] == "focus" else "focus"
                state["timer"] = {"kind": kind, "until": time.time() + (300 if kind == "break" else 1500)}
            else:
                controls_popup(state)
        elif action == "audio":
            audio_popup()
        elif action == "audio-set":
            run(BRIDGE, "audio-set", str(int(sys.argv[2])))
            close_popups()
        elif action in ("workspace", "ensure-workspace"):
            workspace(state, sys.argv[2], action == "workspace")
        elif action == "media":
            state["media"] = json.loads(os.environ.get("INFO") or "{}")
        elif action == "meeting-open":
            open_meeting(state)
        elif action == "meeting-menu":
            meeting_popup(state)
        elif action in ("granola-record", "meeting-record"):
            record_with_granola(state, meeting_only=action == "meeting-record")
        elif action == "granola-toggle":
            state["granola_always_show"] = not state.get("granola_always_show", False)
            close_popups()
        elif action == "calendar-connect":
            close_popups()
            run("/usr/bin/open", "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension")
        elif action == "calendar-authorize":
            close_popups()
            if read(CACHE / "calendar.json").get("status") == "permission_denied":
                run("/usr/bin/open", "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
            else:
                subprocess.Popen([str(SCRIPT), "calendar-permission-worker"],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                 start_new_session=True)
        elif action == "refresh":
            pass
        elif action == "tick":
            try:
                update_profile(state, time.time())
            except (OSError, ValueError, subprocess.SubprocessError):
                # A display transition must not interrupt timers or privacy mode.
                state["profile_checked"] = 0
        else:
            raise ValueError("Unknown toolbar action")
        render(state)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        # Do not include event titles, meeting URLs, or command arguments in logs.
        print("Toolbar action could not finish: " + type(error).__name__, file=sys.stderr)
        sys.exit(1)
