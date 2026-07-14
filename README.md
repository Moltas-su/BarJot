BarJot** is a native macOS menu bar scratchpad designed for quick notes, code snippets, and stripping text formatting without cluttering your desktop with temporary files.

---

## Features

* **Quick Access:** Open BarJot directly from the macOS menu bar or via a custom global keyboard shortcut.
* **Auto-Purge:** Automatically clears text after the window closes (configurable from immediate to 30 seconds) with an optional audio cue.
* **Clipboard History:** A slide-out drawer stores up to 50 recent clipboard items. Click any item to insert it into your active note.
* **Sticky Mode:** Pin the window to stay on top of other applications for continuous reference.
* **Native Themes:** Supports system Light and Dark modes, including a translucent blur theme that integrates with the macOS aesthetic.
* **Keyboard-Centric:** Fully controllable via keyboard shortcuts to summon and dismiss the interface without a mouse.

---

## Installation

### Pre-built Binary

1. Download `BarJot.dmg` from the [Latest Releases](https://www.google.com/search?q=../../releases/latest) page.
2. Open the DMG file and drag `BarJot.app` into your Applications folder.

> **macOS Security Note:** As an independent open-source project, BarJot may trigger an "Unidentified Developer" warning on first launch. To bypass this, right-click (or Control-click) `BarJot.app` in your Applications folder, select **Open**, and confirm the prompt. This step is only required once.

---

## Building from Source

Building BarJot locally requires Xcode.

1. Clone the repository and navigate to the directory:
```bash
git clone https://github.com/yourusername/BarJot.git
cd BarJot
