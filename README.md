# LumaShell

**Your Mac. Wrong decade. Or the next one.**

LumaShell is a native macOS desktop shell that gives the machine a different desktop personality without replacing macOS underneath.

## v0.2

**0.2.1 launch fix:** LumaShell now uses a long-lived AppKit application lifecycle so the shell does not exit after the initial window flash.


Three built-in environments:

- **Mac OS 9** — platinum-style menu bar, classic desktop language, clock, memory panel, Control Strip-style quick launch.
- **Windows XP** — Start menu, blue taskbar, running-app buttons, system widget, quick launch.
- **Luma Neon** — cyberpunk command deck, neon grid, system HUD, AI assistant.

The themes are intentionally behavioral, not just recolors. Each theme remembers its own enabled widgets.

### Widgets

- Clock
- System status
- Memory
- Quick Launch / Control Strip
- Luma AI

### Luma AI

Luma uses the OpenAI Responses API and a local tool router. In the current private development build it can:

- list and launch installed applications
- change LumaShell themes
- show or hide widgets
- open Home, Desktop, Documents, Downloads, or Applications
- hide LumaShell

For local development, launch LumaShell with an `OPENAI_API_KEY` environment variable. The key is never committed to this repository.

Before public distribution, direct API-key mode should be replaced by an authenticated backend so the app never ships a reusable OpenAI secret.

## Shell features

- Native Swift + AppKit + SwiftUI
- Multi-display shell workspace
- Real app discovery and launching
- Live running-app taskbar
- Real Desktop file visibility
- Custom file browser
- Theme-specific widgets
- Per-theme widget persistence
- Launch at login
- Accessibility permission bridge
- Menu-bar recovery controls
- **⌘⇧Esc** emergency hide
- Optional immersive Dock/menu-bar auto-hide

## Safety model

LumaShell is a shell layer. It does not patch WindowServer, disable SIP, replace Finder binaries, or modify protected macOS system files.

If anything feels wrong:

1. Press **⌘⇧Esc**.
2. Or use the **LS** menu-bar item and choose **Hide LumaShell**.
3. Quit from the LS menu-bar item.

## Build locally

Requirements:

- macOS 13+
- Xcode / Swift 5.9+

Run:

```bash
swift run LumaShell
```

Run with AI enabled for local development:

```bash
OPENAI_API_KEY="your-key" swift run LumaShell
```

Build the universal DMG:

```bash
chmod +x Scripts/build-dmg.sh
./Scripts/build-dmg.sh
```

Output:

```
dist/LumaShell.dmg
```

## CI

Each push uses one macOS runner to:

1. clean previous product output
2. run tests
3. compile arm64
4. compile x86_64
5. create a universal binary
6. build the DMG
7. upload the DMG artifact

New pushes cancel stale in-progress builds. CI artifacts are retained for seven days. Version tags matching `v*` publish the DMG as a GitHub Release.

## Direction

Next high-value work is intentionally limited:

- Accessibility-powered window move/resize/snap
- draggable/repositionable widgets
- a production AI backend
- optional Aqua and Windows 95 themes only if they get their own interaction language

## License

MIT.
