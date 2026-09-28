# LumaShell

**Your Mac. Wrong decade. Or the next one.**

LumaShell is a native macOS desktop shell that gives the machine a different desktop personality without replacing macOS underneath.

Version 0.1 ships three built-in environments:

- **Mac OS 9**: platinum-style top menu, classic desktop behavior, Macintosh HD / Trash language.
- **Windows XP**: Start menu, blue taskbar, running-app buttons, My Computer / Recycle Bin language.
- **Luma Neon**: a cyberpunk command shell with a neon grid, command index, terminal-like typography, and status telemetry styling.

No Apple or Microsoft artwork is bundled. The historical themes are original, era-inspired UI treatments.

## What works in 0.1

- Native Swift + AppKit + SwiftUI app.
- Full-screen shell workspace on every connected display.
- App discovery from /Applications and ~/Applications.
- Real app launching through NSWorkspace.
- Live running-app taskbar.
- Custom desktop icons and file browser.
- Theme engine where layout and labels can change with the theme, not only colors.
- LumaShell settings panel.
- Launch-at-login support through ServiceManagement.
- Accessibility permission request for later window-control modules.
- Menu-bar recovery control.
- **⌘⇧Esc** emergency hide shortcut.
- Optional immersive mode that auto-hides the macOS Dock and menu bar while LumaShell is active.
- GitHub Actions DMG build.

## Safety model

LumaShell is intentionally a shell layer. It does not patch WindowServer, disable SIP, modify protected macOS files, or replace Finder binaries.

If anything feels wrong:

1. Press **⌘⇧Esc**.
2. Or use the **LS** menu-bar item and choose **Hide LumaShell**.
3. Quit normally from the LS menu-bar item.

## Build locally

Requirements:

- macOS 13+
- Xcode / Swift 5.9+

Run:

```bash
swift run LumaShell
```

Run tests:

```bash
swift test
```

Build a DMG:

```bash
chmod +x Scripts/build-dmg.sh
./Scripts/build-dmg.sh
```

The DMG is written to:

```
dist/LumaShell.dmg
```

## GitHub build

Every push to `main` builds a DMG and uploads it as the **LumaShell-DMG** Actions artifact.

Tags matching `v*` also publish the DMG to a GitHub Release.

## Architecture

```
LumaShellCore
  Theme model
  Theme catalog

LumaShell
  App / shell lifecycle
  Multi-display shell windows
  App registry
  Running-app bridge
  Desktop
  Launcher
  Taskbar / classic menu bar
  File browser
  Settings
  macOS permission bridges
```

## Next modules

The current architecture leaves clean insertion points for:

- Accessibility-powered move / resize / minimize / focus controls.
- Windows-style snap layouts.
- A true shell-owned always-on-top taskbar mode.
- Custom wallpapers, icon packs, cursors, startup sounds, and UI sound sets.
- Theme packages loaded from disk instead of only built-in themes.
- Classic Mac control strip.
- XP-style Run dialog and system tray modules.
- Cyberpunk widgets, system telemetry, media controls, and command palette.
- Signed/notarized release builds.

## License

MIT.
