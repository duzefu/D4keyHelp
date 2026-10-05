# D4keyHelp

<div align="center">

[简体中文](README.md) · **English**

</div>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-green.svg)](https://www.autohotkey.com/)
[![Release](https://img.shields.io/github/v/release/duzefu/D4keyHelp?label=Release)](https://github.com/duzefu/D4keyHelp/releases)

A **Diablo IV** keyboard/mouse macro tool with a GUI and customizable profiles. Built on AutoHotkey v2.0; all hotkeys only work while the Diablo IV window is active.

**Demo video** (1 min 38 s, covers every feature and how to get started)

https://github.com/user-attachments/assets/26f0ba7f-a3bc-4468-b734-fce76c4f680c

| Light theme | Dark theme |
| :---: | :---: |
| ![mainPage](mainPage.png) | ![mainPage-dark](mainPage-dark.png) |

---

## Table of Contents

- [Quick Start](#quick-start)
- [UI Overview](#ui-overview)
- [Hotkeys](#hotkeys)
- [Features](#features)
- [Limitations](#limitations)
- [Project Structure](#project-structure)
- [About](#about)

---

## Quick Start

### Option 1: Download the exe (recommended, no AHK needed)

Grab `D4keyHelp.exe` from [Releases](https://github.com/duzefu/D4keyHelp/releases) and double-click it.

### Option 2: Run from source

1. Install the **latest AutoHotkey v2.0** (note: **not** the more common v1.3, the two are incompatible)
2. Double-click `macro_script_v3.ahk` (the modular version, recommended)

### Three steps to get going

1. After launching, pick a **Mode** and an **Interval** for each skill under **Skill Macro**
2. Switch back to the game and press **F1** to start (press it again to stop)
3. Closing the window or clicking **Save settings** writes `settings.ini`; your setup is restored on the next launch

---

## UI Overview

The window is made up of three cards. In the top-right corner you can switch between light/dark theme and switch the UI language (Chinese / English, Chinese by default). Both actions reload the script, so stop the macro first.

### UI language

- Every UI string comes from the language table in `utils/Lang.ahk`; the top-right button shows the language you will switch **to** (a Chinese UI shows `English`, an English UI shows `中文`)
- The language is stored in `settings.ini` under `[UI] Language` (`zh` = Chinese, `en` = English); an invalid value falls back to Chinese
- Default profile names follow the UI language (`配置1` ⇄ `Profile 1`); names you renamed yourself are kept as-is
- Only UI text switches language; the run details in `debugd4.log` stay in Chinese so the same keywords still work when troubleshooting

### 1. Skill Macro

Six rows: **Skill 1–4** + **LMB skill** + **RMB skill**. Each row has:

| Column | Description |
| --- | --- |
| Key | Skills 1-4 accept any key; the mouse skills are fixed to the left/right mouse button |
| Mode | `Off` / `Repeat` / `Keep buff` / `Hold` |
| Interval (ms) | Time between two triggers, 300 by default |
| Delay (ms) | Delay between press and release, 10 by default |
| Random delay | Adds random jitter to the delay, on by default |

How the modes differ:

- **Repeat** — triggers over and over at a fixed interval, good for damage skills
- **Keep buff** — samples the skill icon's pixels first and only re-casts once the buff has dropped, instead of mashing the key
- **Hold** — keeps the key held down, good for channeled skills



### 2. Extra Settings


| Feature | Default key | Default interval | Description |
| -------- | --- | -------- | ----------------------- |
| Hold Shift | —   | —        | Every macro key press is sent with Shift (attack in place) |
| Dodge | Space | 1000 ms  | Automatic dodge |
| Potion | Q   | 15000 ms | Drinks automatically; tick **HP check** to drink based on the health globe instead (see below) |
| HP check | —   | —        | Detects the health globe and estimates your HP, drinking only below the **HP threshold**; no manual point picking needed |
| Skip if shielded | —   | —        | A shield covering the globe hides your real HP: checked = skip (default), unchecked = drink anyway |
| Force move | ``` | 50 ms    | Automatic force move |
| Auto mouse move | —   | 1000 ms  | Six-point screen movement pattern, for AFK compass farming |
| Pause on click | —   | 3000 ms  | Pauses the macro for a while after you click manually, handy for looting or using the UI |
| Compass mode | —   | 65000 ms | Clicks the offering at your feet on a timer to start the next run automatically |
| Upgrade rares | —   | —        | Also upgrades rare items to Legendary while auto-transmuting |
| Test globe | —   | —        | Detects the globe once, 3 seconds after clicking (time to switch back to the game); the center, current HP and verdict show up in the status bar below |
| HP threshold | —   | 50 %     | Drink only below this HP percentage (50 is exactly the middle of the globe) |
| Debug log | —   | —        | When off, `debugd4.log` is no longer written; the adjacent **Clear log** deletes the existing logs |
| Clear log | —   | —        | Deletes `debugd4.log` and the rotated `debugd4.old.log` |




### 3. Bottom Bar

- **Status**: Not running / Running / Paused / Temp paused
- **Toggle key**: can be a keyboard hotkey, or Middle / Side 1 / Side 2 mouse button (left and right buttons are not allowed)
- **Start/Stop** button: turns into a red "Stop" while running
- **Save settings**: manual save; changing a control also auto-saves, and the settings are saved once more on exit

### 4. Profiles

The top of the window holds four independent profiles, **Profile 1–4** by default; click one to switch, **right-click a profile name to rename it**. Everything is persisted in `settings.ini` (UTF-16), and defaults are generated on the first launch. Profiles you have not renamed follow the UI language.

---

## Hotkeys

> Every hotkey only works while the Diablo IV window is active.

| Hotkey | Action |
| :---: | --- |
| **F1** | Start / stop the combat macro (rebindable from the bottom bar) |
| **F3** | Auto transmute; press again while running to cancel |
| **Tab** | Pauses the macro while the map is open, resumes when it closes (may not always work) |
| **LMB / RMB** | With **Pause on click** enabled, a manual click pauses the macro temporarily |

---

## Features

### F3 auto transmute

At the **Horadric Cube** screen, press F3: it scans the 11 × 3 item grid at the bottom right (a single screenshot, then pixel reads from that screenshot), identifies Legendary items by the orange/red glow on their border, skips Rare (yellow), Magic (blue) and empty slots, then right-clicks each Legendary in turn and clicks transmute/reforge. Press F3 again at any time to cancel.

### Upgrade rares

When ticked, auto transmute handles rare items first: it adds an affix to the rare (or randomly rerolls one if it already has four), upgrades it to Legendary, and then transmutes it.

### Keep buff

Uses pixel color detection on the skill icon to see whether the effect is still up, and only re-casts once it has dropped. **Only verified at 2K resolution** so far, and it requires the in-game UI to have the action bar centered at the bottom. Other resolutions should work in theory but are untested — verify for yourself.

### Conditional potion (HP check)

By default the potion key is just pressed on a timer. With **HP check** ticked, the macro reads the health globe and decides:

1. It derives the globe's region from the screen size, then locates the orb center, radius and liquid surface inside that region (no manual point picking)
2. The liquid level is converted into an HP percentage using the area of a circular segment, matching how the globe reads in-game
3. The potion key is only pressed below the **HP threshold**; pressing it at high HP does nothing anyway, so no potions are wasted

A few notes:

- **Threshold**: 50% is exactly the middle line of the globe. Raise it to drink earlier (70%, say), lower it to save potions
- **Interval**: setting the potion interval to 1000–2000 ms is recommended; when HP check is enabled and the interval is above 5 seconds, the macro changes it to 1500 ms for you
- **Shields**: a shield covering the globe hides the real HP (the whole orb turns purple). "Skip if shielded" is on by default because the shield is already absorbing damage; if your build keeps a shield up permanently, untick it and the macro will drink as usual
- **Measured**: full HP = 100%, the low-HP reference screenshot = 26%, the shield reference screenshot = "shielded", and each detection takes about 15–50 ms at a normal resolution
- When the globe cannot be detected (covered by UI, not in game, …) it falls back to the original "drink on a timer" behaviour instead of skipping potions

### Debug log

- `debugd4.log` records state changes, saves, pixel tests and errors; enabled by default
- Once the file exceeds 2 MB it rotates to `debugd4.old.log` (only one generation is kept), so it no longer grows forever
- Per-keypress details are off by default; to troubleshoot, set `DebugLogVerbose` to 1 under `[General]` in `settings.ini`
- If you don't want logs at all, untick **Debug log** in the UI, or click **Clear log** to delete them



### Auto mouse move + Compass mode

**Auto mouse move** was made for the compass: combined with force move, it walks you in circles so you collect souls and fight automatically. As long as a teammate picks the offering, you can AFK the whole run.

**Compass mode** was originally designed to pick the offering fully automatically: about once a minute of fighting it clicks the offering at your feet and starts the next run by itself. This only suits builds that need no positioning and are immune to everything, otherwise it will cause trouble.

Illustration

---



## Limitations

- Requires **AutoHotkey v2.0**; incompatible with v1.3
- The pixel-detection features (Keep buff, auto transmute) are tuned for a **2K resolution** and the default UI layout
- HP check derives the globe's position from the screen size; other resolutions should work but are untested. If detection looks off, click **Test globe** and check that the reported center lands on the globe in the status bar
- When a shield covers the globe the HP cannot be read; this is handled by the "Skip if shielded" setting
- All hotkeys **only work while the Diablo IV window is active**; the macro pauses automatically when you switch away
- Tab pausing may not always work
- Debug logs are written to `debugd4.log` (rotated to `debugd4.old.log` past 2 MB)

---



## Project Structure

```
macro_script_v3.ahk         # Main entry point (modular version)
├── core/                   # Globals, window management, timers, macro control, hotkeys
├── gui/                    # Main window, skill controls, extra settings, modern UI widgets
├── functions/              # Skill system, mouse actions, utility keys + auto transmute, condition checks
├── utils/                  # Logging, settings I/O, UI language table (Chinese / English)
└── hotkeys/                # In-game hotkey definitions
```

There is no build/test step — just run it. No external dependencies beyond the AutoHotkey v2.0 runtime.

---

## About

### Background

It started as an attempt to tweak [@WeijieH/D3keyHelper](https://github.com/WeijieH/D3keyHelper), but no matter how I changed it, AHK 1.3 had a weird "mouse gets stuck" issue in Diablo IV (pressing F1 to pause could leave the mouse frozen while the macro kept running). Porting it to AHK 2.0 made the problem disappear. I didn't feel like porting the old macro to AHK 2.0 either, so I just wrote a small one — this is it.

### Notes

1. This script uses pixel sampling (for the Keep buff feature); I have no idea whether it can get you banned
2. Personally I have played several seasons without ever being banned (Steam, international server), including heavy use of overlays, so I don't think a ban is likely
3. That said, a mouse macro like this is often worse than a controller macro — anyone who has used Steam's controller macros will know what I mean — so it isn't all that powerful either

### License

[MIT](https://opensource.org/licenses/MIT)

---

## Star History

<a href="https://star-history.com/#duzefu/D4keyHelp&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=duzefu/D4keyHelp&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=duzefu/D4keyHelp&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=duzefu/D4keyHelp&type=Date" />
  </picture>
</a>
