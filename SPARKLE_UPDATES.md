# Sparkle Updates Guide

This document explains how the automatic update system works in BarJot using the **Sparkle 2** framework, and provides a tutorial on how to release new updates.

## How the Architecture Works

1. **The Appcast Feed:** Sparkle relies on an RSS feed called an "appcast" (`docs/appcast.xml`). This file tells the app what the latest version is, where to download the `.dmg`, and includes a cryptographic signature to prove the update is authentic.
2. **GitHub Pages:** The `docs` folder is served publicly via GitHub Pages at `https://moltas-su.github.io/BarJot/appcast.xml`. When users click "Check for Updates" inside BarJot, Sparkle checks this URL.
3. **EdDSA Cryptography:** To prevent malicious actors from spoofing an update, every `.dmg` is cryptographically signed using an Ed25519 private key. This key was securely generated and is stored permanently in your Mac's **Keychain** (under "Sparkle EdDSA Private Key" or "https://sparkle-project.org"). Sparkle's `sign_update` tool uses this Keychain item to sign the `.dmg`.
4. **App Sandbox:** App Sandbox is explicitly disabled (`ENABLE_APP_SANDBOX = NO`) in the Xcode project. If Sandboxed, macOS would block Sparkle's network requests unless specific entitlements were configured.
5. **Info.plist:** Xcode dynamically merges `QuickNotepad/Info.plist` during the build process (`INFOPLIST_FILE = QuickNotepad/Info.plist`), injecting the `SUFeedURL` (where to check for updates) and `SUPublicEDKey` (the public key to verify signatures) into the compiled app.

## Releasing a New Update

To release a new update to your users, you should **never do it manually**. Always use the automated script: `release_update.sh`.

### Step-by-Step Tutorial

1. **Write your Code:** Make your changes, add new features, or fix bugs in Xcode or your editor.
2. **Bump the Version (Manual):**
   - Open `BarJot.xcodeproj` in Xcode.
   - Go to your Target Settings -> General.
   - Increment the **Version** (e.g., from `1.4.1` to `1.5`).
   - Increment the **Build** number (e.g., from `4` to `5`).
3. **Update the Release Script:**
   - Open `release_update.sh`.
   - Update the hardcoded version strings inside the script to match your new version (e.g., change `1.4.1` to `1.5`, and `version="6"` to `version="7"`).
4. **Run the Script:**
   Open your terminal in the root folder of BarJot and run:
   ```bash
   ./release_update.sh
   ```
5. **Authorize Keychain Access:**
   During the script's execution, you will see a prompt from macOS asking for your Touch ID or password. This is macOS allowing the `sign_update` tool to access your private Sparkle key to sign the `.dmg`.
6. **Done!**
   The script will automatically:
   - Perform a clean `xcodebuild` with ad-hoc signing (`Sign to Run Locally`).
   - Package the app into a `.dmg` file.
   - Generate the cryptographic signature using your Keychain.
   - Rewrite `docs/appcast.xml` with the new version and signature.
   - Push the code changes to the `main` branch.
   - Publish a GitHub Release attaching the `.dmg`.

Any older versions of BarJot in the wild will now see the new update in the appcast feed, download it, verify the signature, and apply the update automatically!
