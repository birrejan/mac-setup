# Toolbar controls

The bar follows the macOS main display. Click **⚙** or press **Option–Shift–T**
to open its tools menu.

| Control | Action |
| --- | --- |
| Presentation mode | Menu toggle or **Option–Shift–P**. Hides app, media, and meeting titles in the toolbar. An orange **PRESENT** indicator stays visible; click it to turn the mode off. |
| Keep awake | Choose 30 minutes, 1 hour, or 2 hours. Prevents idle system and display sleep until the timeout. Click **AWAKE** to open the menu and stop it early. |
| Focus timer | Choose a 25- or 50-minute focus session, or a 5-minute break. A short chime and **DONE** mark completion. Click **DONE** to start the next break/focus session, or stop from the menu. |
| Audio | Scroll volume to adjust; left-click to mute/unmute; right-click to select an output. A filled dot marks the current output. Duplicate names show their connection type. |
| Upcoming meeting | **MTG** appears 30 minutes before a meeting and remains until 5 minutes after its start or its end, whichever comes first. Left-click opens the meeting link; right-click shows its time and the same action. Events without a supported call link open workspace 7 instead. |
| Record with Granola | Click the microphone beside **MTG**, or right-click **MTG** → **Record with Granola**. The tools menu also always offers **Record with Granola**. Choose **Granola · always show record icon · ON** to keep the microphone visible without a calendar event; OFF shows it only alongside **MTG**. This preference survives reloads. |
| Fixed workspaces | Visiting empty **6 Chat**, **7 Calendar**, or **8 Email** opens its assigned apps. Existing matching windows are returned instead of opening duplicates. Ordinary Chrome windows are unaffected. |
| Display profiles | Monitor changes settle for about 10–20 seconds before applying a profile. The laptop bar uses shorter labels and hides media/app names. New laptop profiles use accordion for 3+ windows and tiles for 1–2; wide external displays use tiles. Returning to a display arrangement restores its saved workspace root layouts. |

## Connect Google Calendar

1. In the tools menu choose **Calendar · connect Google account**.
2. Add your Google account in macOS Internet Accounts and enable **Calendars**.
3. Choose **Calendar · allow toolbar access**, then allow **Aero Toolbar** in
   the macOS permission prompt.

The background helper reads calendars synced by macOS every minute, and reacts
to Calendar changes. It includes timed, non-declined events even without
attendees or a call link. All-day entries are omitted. Old cached results are
hidden if the helper stops refreshing. Google Meet, Zoom, Teams, Webex,
Whereby, Jitsi, and Slack huddle HTTPS links are supported.

macOS calls its Calendar read permission “Full Access”; the helper only reads
events and never creates, edits, or deletes them.

The calendar helper is built from `native/ToolbarBridge.swift` into
`~/Library/Application Support/AeroToolbar/ToolbarBridge.app` and starts with
SketchyBar. Settings, timers, and saved layouts live in that same support
directory. A private cache under `~/Library/Caches/AeroToolbar` contains meeting
titles, times, and links for the next day. No credentials are stored in the
dotfiles.

Reloading the bar preserves active timers and presentation mode. Keep-awake
always has an OS-enforced timeout.

## Granola recording

The record action opens the installed Granola app with
`granola://new-document?auto_transcribe=1`. This desktop command was verified
against Granola 7.576.0. It creates a new note and asks Granola to start
transcribing, including for calls without a calendar event. Sign-in and audio
permissions are handled in Granola. The meeting shortcut uses the same action;
it does not attach the toolbar's calendar event to the note or join the call.

Use Granola to pause, resume, or finish. The toolbar microphone is a launcher,
not a recording-status indicator. Enabling its visibility never starts capture.
No API key or Accessibility automation is required. Granola's desktop URL
handling may change in future versions.

## Checks

Run `/usr/bin/python3 ~/.config/sketchybar/tests/test_toolbar.py` for isolated
checks of privacy, meeting selection, app launching, timers, and display
profile restoration.
