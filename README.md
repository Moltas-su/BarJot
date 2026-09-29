<p align="center">
  <img src="https://moltas-su.github.io/BarJot/screenshot.jpg" alt="BarJot running on macOS" width="780" />
</p>

<h1 align="center">BarJot</h1>

<p align="center">
  A lightweight macOS menu bar scratchpad for quick notes, code snippets, and plain-text capture.
</p>

<p align="center">
  <a href="https://github.com/moltas-su/BarJot/releases/latest">
    <img src="https://img.shields.io/github/v/release/moltas-su/BarJot?label=Download&color=0a7aea" alt="Latest Release" />
  </a>
  <img src="https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9" />
  <img src="https://img.shields.io/github/license/moltas-su/BarJot" alt="License" />
</p>

---

## Overview

BarJot lives in the macOS menu bar and opens on demand — no windows cluttering your desktop, no files to manage. Use it to capture a thought, paste a snippet, or strip rich formatting from text before it goes somewhere else. When you are done, close it and BarJot disappears, optionally clearing everything automatically.

---

## Features

**Quick Access**
Open BarJot from the menu bar icon or with a custom global keyboard shortcut. The window appears instantly, regardless of which application is in focus.

**Auto-Purge**
Content is automatically deleted when the window closes. The delay is configurable from immediate to 30 seconds, with an optional audio cue confirming the clear.

**Clipboard History**
A slide-out drawer retains up to 50 recent clipboard items. Click any entry to insert it directly into your current note.

**Sticky Mode**
Pin the window to keep it floating above all other applications. Useful when you need to reference notes while working in another app.

**Native Themes**
Supports macOS Light and Dark modes. A translucent Liquid Glass theme uses the system's native blur effect to blend naturally with the desktop.

**Keyboard-Centric**
Every action is available via keyboard. Open, close, pin, and navigate clipboard history without reaching for the mouse.

---

## Installation

### Pre-built Binary

1. Download `BarJot.dmg` from the [Latest Releases](../../releases/latest) page.
2. Open the DMG and drag `BarJot.app` into your Applications folder.
3. Launch the app from Applications.

> **macOS Security Note:** BarJot is an independent open-source project and is not notarized through the Mac App Store. On first launch, macOS may display an "Unidentified Developer" warning. To open the app, right-click (or Control-click) `BarJot.app` in your Applications folder, select **Open**, and confirm the prompt. This step is only required once.

---

## Building from Source

Requires Xcode 15 or later.

```bash
git clone https://github.com/moltas-su/BarJot.git
cd BarJot
open BarJot.xcodeproj
```

Select the **BarJot** scheme and build with `Cmd + R`.

---

## Automatic Updates

BarJot uses [Sparkle 2](https://sparkle-project.org) for automatic updates. When a new release is available, the app will notify you and handle the update in the background. You can also check manually via the Settings panel.

---

## License

Released under the [MIT License](LICENSE).
