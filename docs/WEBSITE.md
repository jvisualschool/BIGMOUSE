# BigMouse visual guide website

The public guide lives at <https://jvibeschool.org/BIGMOUSE/>. The standalone static site is in `website/`; it has no build step, external scripts, analytics, or account requirement.

## Content

- Korean and English instructions for installation, permissions, cursor/click effects, keystrokes, spotlight and magnification.
- Actual BigMouse 0.7 settings captures, image enlargement, a presentation checklist and 11 FAQs.
- A generated voxel hero; see [image provenance and prompt](HERO-IMAGE.md).
- Links to the v0.7 GitHub app, checksum, release notes and source repository, with a visible unnotarized-build notice.

Initial web language follows the region in the browser locale: `KR` uses Korean; other or unspecified regions use English. The language buttons override this and remember the choice in local storage. This is a browser preference, not IP geolocation. The native app separately uses the macOS region.

## Light and dark modes

The header offers Light mode and Dark mode in both languages. On the first visit the guide follows the device's color scheme, including changes while the page is open. A manual choice takes priority and is saved under `bigmouse-guide-theme` in local storage, independently of the language choice. Other open tabs receive the updated choice. When storage is unavailable, the switch still works for the current page.

`theme.js` runs before the stylesheet to apply the initial mode without flashing the opposite background. It also updates the browser theme color and the buttons' `aria-pressed` state. The external script complies with the existing content security policy. Theme colors cover the header, text, panels, buttons, FAQ, download area and image dialog; screenshots and hero artwork retain their original colors.

## Screenshots

The website shows two user-supplied feature captures directly below the shortcut guide and before the installation steps. They sit side by side on desktop and stack on mobile; selecting either opens the existing image dialog. Captions and accessibility labels follow the selected language. These images contain no language-specific text, so both locales share the same assets. The Korean and English READMEs and the v0.7 release notes also show both images at the top.

| File in `website/assets/demos/` | Content | Dimensions | Size |
| --- | --- | --- | --- |
| `zoom.webp` | Magnifier around the pointer | 1440 × 966 | 90,446 bytes |
| `spotlight.webp` | Spotlight around the pointer | 1440 × 966 | 76,444 bytes |

The supplied 1826 × 1224 PNGs were resized and encoded using `cwebp -resize 1440 0 -q 85 -alpha_q 100 -m 6 -sharp_yuv -metadata none`. The WebP encoder rounds the proportional output height to 966 pixels. Transparency is preserved, and the original files remain unchanged. The two deployed images total 166,890 bytes. GitHub embeds use the public repository's raw WebP URLs.

Korean screenshots are 1000 × 1644 pixels; English screenshots are 1120 × 1644 pixels because the English settings window is wider. They are native window captures, not images with translated text painted over them.

| File in `website/assets/screenshots/` | Content |
| --- | --- |
| `settings-cursor.png` | Ring color, diameter, border, fill and click effects |
| `settings-keys.png` | Key settings and the built-in appearance preview, temporarily using 28pt text |
| `settings-spotlight-zoom.png` | Spotlight and zoom controls after successful permission reconnection |
| `zoom-permission-needed.png` | The actual screen-recording permission warning for troubleshooting |

Korean files remain at the paths above. English counterparts use the same base names with a `.jpg` extension under `website/assets/screenshots/en/`. The selected page language determines all three feature images and the troubleshooting image, including their enlarged views, alt text and captions.

The original Korean capture restored the user’s key font size to 98pt afterward. English images were captured from the current production `SettingsView` and translation resources in a separate documentation preview, with an app-specific `en_US` locale and 28pt key preview. This preview starts no overlay, keystroke monitor or screen-capture session, and its ungranted permissions appear naturally in the screenshots. The spotlight/zoom capture also supplies the English permission-warning example. It does not change the running app, its preferences or permissions. Permission UI captures do not establish that the magnifier works.

## Editing and preview

Edit `index.html` for structure, `style.css` for layout, `content.js` for translations, `app.js` for language selection and image dialogs, and `theme.js` for color-mode selection. Use full borders on rounded cards; do not add one-sided colored accents.

```sh
python3 -m http.server 8732 --bind 127.0.0.1 --directory website
```

Open `http://127.0.0.1:8732/`. Keep the two downloadable README copies synchronized with the repository roots before deploying. Check desktop and mobile layouts (including horizontal overflow against `document.documentElement.clientWidth`), both languages and color modes, image-language switching and enlarged images after reload, system-theme changes before a manual choice, saved-theme persistence after reload, every image, the image dialog including Escape/focus restoration, FAQs, and the download status.

## Deploying

Commit locally before publishing. Deploy only the contents of `website/` to the existing server's `/var/www/html/BIGMOUSE/`. Check the destination first, preserve a private backup when replacing an existing deployment, upload to a temporary directory, and move it into place. Do not upload the repository, `.git`, local work logs, app builds, private server configuration or credentials.

Keep `.htaccess` with the upload. It preserves the required `noindex, nofollow` policy, disables directory listings, restricts script/resource origins and denies sensitive file types. Verify HTTPS status, assets, browser console, response security headers and protected paths on the live site. No other project or root server configuration needs to change.

The download area links directly to GitHub v0.7 assets. Keep the release and signing status consistent with the actual release. Verify asset checksums after publication. Use the same version and bytes on the website and GitHub.

## Verified deployment — 2026-10-18

The guide was published to the existing `/BIGMOUSE/` path. HTTPS returned 200 for the page and all 12 public files; fetched bytes matched the deployed files. The `X-Robots-Tag`, CSP and other configured headers were present. `.htaccess` and directory listing requests returned 403.

Desktop and 390px mobile views were visually checked; 320px layouts in both languages had no horizontal overflow. All screenshots loaded. Language switching, KR/non-KR initial selection, FAQ expansion, image enlargement, Escape and focus restoration passed. The live browser reported no errors or warnings. This validates the guide, not app distribution or native Fn operation.

## Color-mode validation — 2026-10-18

Local browser checks passed for light/dark modes in Korean and English at 320, 768, 900, 1024 and 1440px viewport widths. The hero margins were adjusted to eliminate small horizontal overflow at intermediate widths. Initial system preference, system changes before an override, keyboard selection, saved selection after reload and language independence were checked. Both image-dialog themes were visually inspected, with Escape and focus restoration verified. The browser console reported no errors or warnings.

## Native permission recovery — 2026-10-18

After explicit user authorization for each permission, the current local 0.7 app was re-added to Screen Recording and Input Monitoring and restarted. Both permission warnings cleared. Zoom received real frames (first-frame timings of approximately 84–160ms in the initial checks), and a captured magnifier overlay visibly contained enlarged screen content. Key labels were also observed on the actual overlay. The key display was restored to off and the font size to 98pt.

The normal spotlight/zoom settings image was refreshed after recovery. The separate permission-warning image is retained as a troubleshooting example. Physical Fn input was not synthesized by the automation tool; magnification was exercised through the app’s 3-second preview. No app rebuild was needed for this permission repair.

## GitHub official release — 2026-10-18

The download section now links to the v0.7 Apple Silicon app, SHA-256 file, release notes and public source repository. Korean and English copy explicitly states the lack of Developer ID signing and Apple notarization. Installation on another Mac remains unverified. The earlier pending-download descriptions above record the initial guide publication state.
