# BigMouse

[한국어](README.md) · [English](README.en.md)

| Magnifier · Fn | Spotlight · Control |
| --- | --- |
| ![Magnifier · Fn](https://raw.githubusercontent.com/jvisualschool/BIGMOUSE/main/website/assets/demos/zoom.webp) | ![Spotlight · Control](https://raw.githubusercontent.com/jvisualschool/BIGMOUSE/main/website/assets/demos/spotlight.webp) |

<img src="Resources/AppIcon.png" width="96" alt="BigMouse icon">

**A free macOS presentation tool that makes your pointer, clicks, and keystrokes visible.**

Help an audience follow your actions during lessons, online classes, software demonstrations, and screen recordings. BigMouse runs in the menu bar and provides cursor highlighting, click effects, a spotlight, a magnifier, and keystroke display.

**The first official release is ver 0.7, distributed free through GitHub and the developer website. There is no Mac App Store release.** No account, subscription, or paid feature unlock is required.

| Item | Details |
| --- | --- |
| First public version | **ver 0.7** |
| Website | [jvibeschool.org/BIGMOUSE](https://jvibeschool.org/BIGMOUSE/) |
| GitHub | [jvisualschool/BIGMOUSE](https://github.com/jvisualschool/BIGMOUSE/) |
| Downloads | Free download from the [v0.7 official release](https://github.com/jvisualschool/BIGMOUSE/releases/tag/v0.7) |
| macOS target | macOS 13 or later |
| Prepared and verified architecture | Apple Silicon (`arm64`) |
| Interface language | Korean for the South Korea macOS region; English everywhere else |
| Price | Free |

> **Release information:** Version 0.7 / build 15 is for Apple Silicon. It has an ad hoc signature, with no Developer ID signing, Hardened Runtime, or Apple notarization. macOS may block its first launch. Installation on another Mac, Intel support, and physical macOS 13 validation remain unverified.

**[Download the app ZIP](https://github.com/jvisualschool/BIGMOUSE/releases/download/v0.7/BigMouse-0.7-macos-arm64.zip)** · [SHA-256](https://github.com/jvisualschool/BIGMOUSE/releases/download/v0.7/BigMouse-0.7-macos-arm64.zip.sha256) · [Release notes](https://github.com/jvisualschool/BIGMOUSE/releases/tag/v0.7)

**[Visual user guide](https://jvibeschool.org/BIGMOUSE/)** — Follow real settings screenshots, installation and permission steps, feature walkthroughs, and troubleshooting in Korean or English. Website sources are in `website/`.

## Contents

- [Features](#features)
- [Quick start](#quick-start)
- [Installation](#installation)
- [Permissions](#permissions)
- [Using each feature](#usage)
- [Controls at a glance](#shortcuts)
- [Settings and defaults](#defaults)
- [Korean and English](#languages)
- [Presentations and screen sharing](#presentation)
- [Privacy and security](#privacy)
- [FAQ and troubleshooting](#faq)
- [Updating and uninstalling](#maintenance)
- [Building from source](#development)
- [Reporting issues and documentation](#support)
- [Free distribution and licensing](#license)

<a id="features"></a>
## Features

| Feature | What it does |
| --- | --- |
| Cursor highlight | Draws a colored ring with adjustable diameter, border, and fill. |
| Click effects | Briefly sparkles around the clicked position. |
| Spotlight | Dims the screen outside a circular area around the pointer while a key is held. |
| Magnifier | Enlarges the area around the pointer by 1.5–4× while Fn is held. |
| Keystrokes | Shows characters and key combinations such as `⌘C`. |
| Key appearance | Offers fonts, size, continuous/separate boxes, and top/center/bottom positions. |
| Menu bar controls | Toggles features and pauses all effects without opening Settings. |
| Automatic saving | Saves appearance and feature preferences on this Mac immediately. |

BigMouse is a native Swift app using macOS frameworks. Its overlay windows do not intercept mouse clicks or keyboard focus. You can keep working in your current app, and no internet connection is required to use the features.

<a id="quick-start"></a>
## Quick start

After installation:

1. Open BigMouse and find the white BigMouse icon in the menu bar.
2. Open **Settings…**, turn on **Enable**, and move the mouse to check the ring.
3. Hold **Control** and move the pointer to try the spotlight.
4. Grant **Input Monitoring**, double-tap **Option**, and try harmless sample input to check keystrokes.
5. Grant **Screen Recording** and hold **Fn** to try the magnifier.
6. Close Settings and start presenting. Choose **Pause** from the menu bar to hide all effects temporarily.

Keystroke display starts off each time the app launches. Enable it when needed.

<a id="installation"></a>
## Installation

### Choose the right download

Check your chip and macOS version in **Apple menu → About This Mac**.

- **Apple Silicon, including M1/M2/M3:** use the `macos-arm64.zip` app package.
- **Intel:** the arm64 package does not target your Mac. Intel distribution and validation are pending.
- **Windows, Linux, and iPadOS:** not supported.

Download from the [v0.7 official release](https://github.com/jvisualschool/BIGMOUSE/releases/tag/v0.7). The [BigMouse website](https://jvibeschool.org/BIGMOUSE/#download) links to the same GitHub app ZIP and checksum.

| Ver 0.7 file | Purpose |
| --- | --- |
| `BigMouse-0.7-macos-arm64.zip` | Installable app |
| `BigMouse-0.7-macos-arm64.zip.sha256` | App ZIP checksum |
| `BigMouse-0.7-source.zip` | Source for building locally |
| `BigMouse-0.7-source.zip.sha256` | Source ZIP checksum |

Most users need the **app ZIP**. GitHub's automatic `Source code (zip)` download contains source, not the installable app. File version numbers change in later releases.

### Install and launch

1. Double-click the app ZIP to extract it.
2. Move `BigMouse.app` to **Applications**.
3. Open it from Applications.
4. Check that **Enable** is on in the initial Settings window.
5. Grant permissions for the features you want to use.

Keep the app in one stable location. Switching between copies in Downloads, Applications, and development folders can leave permissions associated with a different copy.

### Verify the download

With the ZIP and its matching `.sha256` file in Downloads:

```sh
cd ~/Downloads
shasum -a 256 -c BigMouse-0.7-macos-arm64.zip.sha256
```

The expected result is `BigMouse-0.7-macos-arm64.zip: OK`. If it differs, do not run that file; download it again from an official channel. A checksum compares file contents; obtain both the ZIP and checksum from the official source.

### If macOS blocks the app

This app is not notarized, so macOS may block it. If you have verified the official download and checksum and choose to run it, first try opening the app, then review its entry under **System Settings → Privacy & Security → Open Anyway**. See [Apple’s app-opening guidance](https://support.apple.com/en-us/102445). Stop and report the exact message if macOS instead says the app will damage your computer or is damaged.

**Developer ID signing and Apple notarization** also apply to direct GitHub/website distribution and are separate from Mac App Store listing. [Apple's macOS distribution guidance](https://developer.apple.com/macos/distribution/)

<a id="permissions"></a>
## Permissions

Grant only the permissions needed for your chosen features. Names vary slightly by macOS version.

| Feature | Permission | Location |
| --- | --- | --- |
| Cursor, click effects, spotlight | Neither permission below | Enable the feature in BigMouse |
| Keystrokes | Input Monitoring | System Settings → Privacy & Security → Input Monitoring |
| Fn magnifier | Screen Recording / Screen & System Audio Recording | System Settings → Privacy & Security → the screen recording section |

### Allow keystrokes

1. Find **Keystrokes · Double-tap Option** in Settings.
2. Click **Permissions…** beside the permission message.
3. Enable BigMouse in macOS **Input Monitoring**.
4. Complete any authentication directly in the macOS dialog.
5. Complete **Quit & Reopen** if requested.
6. Turn on **Enable**, then **Show keystrokes on screen**, or double-tap Option.

### Allow the magnifier

1. Click **Permissions…** under **Zoom · Fn**.
2. Enable BigMouse in the macOS screen recording permission list.
3. Relaunch when requested.
4. Enable **Hold Fn to zoom** and hold Fn, or use **3-second preview**.

Even when the permission name includes audio, **BigMouse does not capture audio**. It displays screen frames temporarily in the magnifier and does not create a recording file.

If the permission switch is already on but the feature fails, follow [permission recovery](#permission-repair).

<a id="usage"></a>
## Using each feature

### Cursor highlight

Enable **Show a ring around the cursor**.

- **Highlight color:** yellow, orange, green, blue, purple, black, or white.
- **Ring size:** the circle's diameter.
- **Border width:** the thickness of its outline.
- **Fill:** the opacity of its interior; 0% leaves the outline only.
- **Hide after 2 seconds of inactivity:** hides the stationary ring and restores it on movement. The ring remains visible while the spotlight is active.

The preview at the top of Settings reflects the ring's appearance. This effect does not change the actual macOS pointer size or shape.

### Click effects

Enable **Sparkle around the pointer on click** to show a brief star-like effect at a click. It works with left and right clicks and can be enabled independently of the ring.

### Spotlight

Turn on **Enable spotlight**, then hold the selected **Hold key** combination. The area outside the pointer's circle dims; releasing the keys restores the screen.

Choose **Control** (default), **Option+Shift**, **Control+Option**, or **Control+Shift**. **Bright area** changes the circle diameter; **Dim level** changes the darkness outside it. Use **3-second preview** to inspect the effect without holding the keys.

Extra modifiers, such as Command, prevent the selected combination from matching. Keys still reach your current app, so choose another combination if its shortcuts conflict.

### Magnifier

Enable **Hold Fn to zoom**. Point at a small label, menu, or icon and hold **Fn** to enlarge it in a circular lens. Release Fn to dismiss it.

**Lens size** changes the circle diameter, while **Zoom level** changes the enlargement from 1.5× to 4×. **3-second preview** helps check permissions and appearance. The underlying app's zoom setting is unchanged. On multiple displays, the magnifier captures the display under the pointer. Fn is currently fixed as the activation key.

### Keystrokes

After granting Input Monitoring, use any of these controls:

- Double-tap **Option** to toggle the display.
- Toggle **Show keystrokes on screen** in Settings.
- Choose **Keystrokes · Double-tap ⌥** in the menu bar.

**Keys on** appears briefly when enabled. The display shows characters, numbers, arrows, and combinations such as `⌘C`, `⌘V`, and `⇧⌘S`. Modifier-only presses do not produce separate key boxes.

| Setting | Behavior |
| --- | --- |
| Font | System, System monospaced, or a font family installed on this Mac |
| Size | 18–128pt |
| Continuous | Recent inputs share one box |
| Separate | Each input has its own box |
| Top / Center / Bottom | Vertical placement on the pointer's display; horizontally centered |

Labels disappear about **1.8 seconds** after the last input. Up to 24 recent labels are kept briefly; older labels drop off when space is limited. There is no saved input history.

Keystrokes turn off on launch, pause, sleep, session deactivation, and display reconfiguration. Re-enable them when needed; font, size, mode, and position remain saved.

### Pause and quit

| Action | Result |
| --- | --- |
| Close Settings | The app and effects continue running |
| Menu bar → Settings… | Opens Settings again |
| Pause / turn off Enable | Hides all effects and stops keystroke monitoring and zoom capture |
| Resume / turn on Enable | Restores saved effect preferences; re-enable keystrokes separately |
| Quit BigMouse | Fully exits the app |

<a id="shortcuts"></a>
## Controls at a glance

| Purpose | Default control | Customization |
| --- | --- | --- |
| Toggle keystrokes | Double-tap `⌥ Option` | Fixed |
| Spotlight | Hold `⌃ Control` | Four combinations available |
| Magnifier | Hold `Fn` | Fixed |
| Pause all effects | Menu bar → Pause | No global shortcut |

Tap and release Option twice quickly without holding other keys. A long press, another key, or an intervening mouse click cancels the gesture.

<a id="defaults"></a>
## Settings and defaults

These are fresh-install defaults; saved preferences take precedence. `pt` means macOS screen-coordinate points.

| Setting | Range / choices | Default |
| --- | --- | --- |
| Enable | On / off | On |
| Cursor and click effects | Independent on / off | Both on |
| Color | Seven colors | Yellow |
| Ring diameter | 28–160pt | 56pt |
| Border width | 1–12pt | 2.5pt |
| Fill | 0–60% | 18% |
| Hide ring after 2 seconds | On / off | Off |
| Spotlight | On / off | On |
| Spotlight shortcut | Four combinations | Control |
| Bright area diameter | 120–720pt | 320pt |
| Dim level | 15–90% | 65% |
| Fn zoom | On / off | On |
| Lens diameter | 160–520pt | 300pt |
| Zoom level | 1.5–4× | 2× |
| Keystroke activation | On / off | Off at each launch |
| Key font | System / monospaced / installed | System monospaced |
| Key size | 18–128pt | 28pt |
| Key mode | Continuous / Separate | Continuous |
| Key position | Top / Center / Bottom | Bottom |

Changes apply and save immediately on this Mac. There is no Save button or cross-device sync. An enabled spotlight or magnifier appears only while its keys are held or a preview runs.

<a id="languages"></a>
## Korean and English

BigMouse checks the **macOS region at launch**, independently of preferred system language.

| Region | Interface |
| --- | --- |
| South Korea (`KR`) | Korean |
| Every other region | English |
| Unknown region | English |

An English system with the South Korea region uses Korean. A Korean system with the United States region uses English. Change **System Settings → General → Language & Region → Region**, then quit and relaunch BigMouse. There is no in-app language selector, IP lookup, or GPS/location check.

<a id="presentation"></a>
## Presentations and screen sharing

| Situation | Example setup |
| --- | --- |
| General demonstration | Enable ring and clicks; hold Control for emphasis |
| Shortcut lesson | Separate key boxes at the bottom with a readable font size |
| Small menu or label | Hold Fn briefly over the item |
| Minimal obstruction | Set fill to 0% and enable inactivity hiding |

Before presenting, check the actual shared display: move the pointer onto it, confirm effects are visible, place key labels away from subtitles and controls, and try Control/Fn in the presentation app. Turn off key display before sensitive input and stop sharing when needed.

BigMouse draws effects in separate overlay windows. **Whole-display sharing and single-window sharing may differ.** Check the audience view or a short recording in Zoom, OBS, or your chosen tool. BigMouse does not record or stream by itself.

<a id="privacy"></a>
## Privacy and security

- No account, login, analytics SDK, server connection, or automatic updater.
- A read-only input event monitor is installed while keystroke display is enabled and removed when disabled.
- Keystrokes and screen images are not saved to files or transmitted by the app.
- Magnified screen frames are used in memory; audio capture is disabled.
- Preferences are saved in the local macOS settings store.
- Pause, sleep, and display reconfiguration clear displayed input and image references.
- macOS diagnostic logs contain numeric zoom startup timing, without input text or captured images.

Detected macOS Secure Event Input clears the key display. Not every password field uses secure input, so **disable keystrokes before entering passwords, verification codes, or personal information**. Other recording/sharing software may capture visible overlays.

See [SECURITY.md](SECURITY.md) for processing boundaries and private vulnerability reporting.

<a id="faq"></a>
## FAQ and troubleshooting

### 1. Is it free? Do I need the App Store?

It is free through [GitHub Releases](https://github.com/jvisualschool/BIGMOUSE/releases) and the [website](https://jvibeschool.org/BIGMOUSE/). No App Store installation, account, subscription, or feature purchase is required. The first public version is ver 0.7.

### 2. Why is there no window or Dock icon?

BigMouse is a menu bar app. Click its white app icon in the menu bar and choose **Settings…**. Settings may not open automatically after the first launch. Opening BigMouse again from Applications also brings up Settings.

### 3. Does closing Settings quit the app?

No. Choose **Quit BigMouse** from the menu bar to exit.

### 4. Why did all effects disappear?

Check **Enable** and the menu bar's **Resume** item. A paused state is saved and can persist across launches. Resume the app and check each feature's individual switch.

### 5. Double-tapping Option does nothing.

Check **Enable** and Input Monitoring first. Tap and release Option twice quickly without another key or mouse click between taps. Try **Show keystrokes on screen** directly to distinguish a gesture problem from a permission problem.

<a id="permission-repair"></a>
### 6. Input Monitoring is already on, but the app still requests it.

Updating or rebuilding an ad hoc signed app can leave the old permission entry associated with a different binary. Another copy with the same name can cause similar confusion.

1. Choose the exact `BigMouse.app` you will use: normally in **Applications**, or `dist/BigMouse.app` for development.
2. Choose **Quit BigMouse**.
3. Open **System Settings → Privacy & Security → Input Monitoring**.
4. Select the old **BigMouse** entry and remove it with **−**.
5. Complete any administrator authentication directly in the macOS dialog.
6. Use **+** to add the exact app from step 1 and enable it.
7. Complete **Quit & Reopen**, or launch the app again manually.
8. Turn on **Enable** and **Show keystrokes on screen**, then try harmless input.

Use `⌘⇧G` in the file picker to navigate to the app's folder if needed. Verify that keys actually appear, rather than relying only on the permission switch.

### 7. Why are keystrokes off after sleep or pause?

This prevents input from becoming visible unexpectedly. Re-enable with Option twice after launch, sleep, session changes, pause, or display reconfiguration. Appearance settings remain saved.

### 8. Fn does not magnify anything.

Check **Enable**, **Hold Fn to zoom**, and Screen Recording permission. Try **3-second preview**, read any permission message, and relaunch. If permission is already on, apply the recovery steps above to the screen recording permission list. Restoring Input Monitoring does not also grant Screen Recording.

### 9. Fn also opens emoji or switches input sources.

Check the globe/Fn key action in **System Settings → Keyboard**. Its label varies by macOS and keyboard. BigMouse does not change that system setting. An external keyboard that does not expose Fn to macOS needs separate verification.

### 10. Control also triggers something in my current app.

Keys still reach other apps. Change the spotlight shortcut to Option+Shift, Control+Option, or Control+Shift to avoid a conflict.

### 11. Korean text differs from the final sentence.

The display shows individual key events, not the final composed IME text or document contents. Latin letters are shown in uppercase.

### 12. Long inputs disappear or large text does not fit the preview.

The display is for brief demonstrations. Labels expire about 1.8 seconds after the last input, and older labels drop off when space runs out. Reduce the size or switch modes. Settings has a narrower preview than the actual display.

### 13. What happens with multiple monitors?

Keystrokes appear on the pointer's display, which is also the magnifier's capture target. Re-enable keys after display connection changes. Check full-screen apps and monitor layouts in your actual setup.

### 14. Effects do not appear in screen sharing or recording.

Sharing a single app window may exclude BigMouse's separate overlay. Check the selected sharing target and the actual audience view or a short recording. Whole-display sharing may also expose other windows, so review what is visible.

### 15. Why is the app in English while I am in Korea?

It follows the **macOS region**, not your physical location. Set the region to South Korea, then quit and relaunch. There is currently no manual in-app language selector.

### 16. Does it work offline? Does it save my input?

Yes, it works offline. The app does not save or transmit input or screen frames. Preferences are saved locally. Other recording software can still record visible effects.

### 17. Can I type passwords with key display enabled?

Disable it first. Secure Input detection does not guarantee protection for every app's password fields.

### 18. Does it launch at login or update automatically?

The app has no built-in login-item registration or automatic updater. Download updates manually from an official channel.

### 19. Can it replace the pointer, draw annotations, or automate clicks?

It draws presentation effects around the pointer. Pointer replacement/resizing, screen annotation, click automation, macros, and recording-file creation are not provided.

### 20. Is there a reset-to-defaults button?

Not currently. Use the [defaults table](#defaults) to adjust values. Reinstalling the app may retain saved preferences.

<a id="maintenance"></a>
## Updating and uninstalling

To update, download the new app ZIP and checksum from an official channel, quit BigMouse, and replace the app in the same location. Relaunch and check the ring, keys, and Fn zoom. Follow [permission recovery](#permission-repair) if permission messages return. Preferences normally survive app replacement; keystrokes start off again.

To uninstall, quit BigMouse and move the app from Applications to Trash. Remove its entries from Input Monitoring and Screen Recording if desired. Deleting the app does not necessarily delete local preferences, which may reappear on reinstall.

<a id="development"></a>
## Building from source

Most users can use the app ZIP. Developers need macOS and Swift from Apple Command Line Tools. No external package manager is used.

If Command Line Tools are missing, run this and complete the installer:

```sh
xcode-select --install
```

Extract the source ZIP or download the [repository](https://github.com/jvisualschool/BIGMOUSE/), then run from the folder containing `build.sh`:

```sh
bash build.sh
open dist/BigMouse.app
```

The script builds for the host architecture, not a Universal binary. Apple Silicon has been checked. Compilation, resource copying, and signing happen in a fresh staging bundle before replacing the previous output. Local builds are ad hoc signed; **rebuilding may require reconnecting permissions**. Keep a stable execution path and recheck keys/Fn.

```sh
bash test.sh
codesign --verify --strict dist/BigMouse.app
bash scripts/package-release.sh
```

Overlay checks require a logged-in macOS desktop session. After building the 0.7 source, packaging writes the app ZIP and checksum to `dist/releases/v0.7/`. It rejects unexpected bundle files, symlinks, and overwriting an existing archive. Preserve existing artifacts elsewhere before repackaging the same version.

Successful signature verification does not establish Developer ID signing or notarization. See the [distribution guide](docs/DISTRIBUTION.md).

### Development and commit conventions

- **Write all commit messages in English.** Example: `Update installation instructions and troubleshooting FAQ`.
- Update both Korean and English translations when changing interface text.
- Preserve region-based language selection: Korean for South Korea, English elsewhere.
- Do not write keystrokes or captured images to files, logs, or the network.

See [CONTRIBUTING.md](CONTRIBUTING.md) for change and validation guidelines.

### Project structure

```text
Sources/                    App, menus, settings, overlays, input, capture
Resources/                  Icons, localization, third-party notices
Tests/                      Behavior checks
scripts/package-release.sh  ZIP and checksum creation
build.sh                    Local app build
test.sh                     Check runner
docs/                       Distribution, release, and security documentation
dist/                       Generated apps and packages; Git-ignored
.build/                     Build cache and temporary files; Git-ignored
```

<a id="support"></a>
## Reporting issues and documentation

Use [GitHub Issues](https://github.com/jvisualschool/BIGMOUSE/issues) for bugs and feature requests. Include the app version and download source, macOS version, chip, monitor count, region, interface language, affected feature, permission state, reproduction steps, expected/actual results, and exact error message.

Do not attach private input or credentials. Follow [SECURITY.md](SECURITY.md) to report security details privately.

- [Korean README](README.md)
- [GitHub and website distribution](docs/DISTRIBUTION.md)
- [Changelog](CHANGELOG.md)
- [ver 0.7 release notes](docs/releases/v0.7.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Security review of development build 0.3.6](docs/security-review-2026-10-18.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

<a id="license"></a>
## Free distribution and licensing

**BigMouse is provided free through GitHub Releases and the developer website.** The app has no payment, subscription, or paid feature restriction.

The app is free to use. No separate open-source license has been assigned to the source code; it is not labeled as MIT or another specific license. Contact the repository owner about modification or redistribution of source code or the app icon.

Lucide icons retain their separate [ISC/MIT license](Resources/Lucide/LICENSE), included in the app.
