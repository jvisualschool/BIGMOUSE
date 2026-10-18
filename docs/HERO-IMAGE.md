# Website hero image

Created on 2026-10-18 with the built-in `image_gen.imagegen` tool.

- Final asset: [bigmouse-hero-voxel.webp](../website/assets/illustrations/bigmouse-hero-voxel.webp)
- Actual dimensions: 1672 × 941 pixels, transparent WebP.
- Generated as PNG and converted with `cwebp -q 85 -alpha_q 100 -m 6 -sharp_yuv -metadata none`. The alpha channel is lossless and pixel-identical to the PNG. File size dropped from 885,923 to 134,564 bytes (84.8% smaller); dimensions are unchanged.
- The deployed site redirects the former PNG URL to the WebP file. The PNG is removed from the current source tree and public deployment; the original remains recoverable from Git history.
- Purpose: the right side of the BigMouse website hero, with a blue pointer, golden highlight, magnifier, keyboard and friendly mouse.
- This is an illustrative image, not a screenshot of the app. All settings images in `website/assets/screenshots/` are actual native app captures.

## Generation prompt

Use case: stylized-concept. Asset type: hero illustration for BigMouse, a free macOS tool for teaching that highlights the pointer, displays keys, and magnifies the screen. Create a cute, polished 3D isometric voxel diorama: a tiny friendly computer mouse peripheral beside a compact ivory desktop monitor and chunky keyboard, with one oversized vivid blue cursor arrow as the main visual, a golden circular cursor highlight on the screen, a small magnifying lens and a few simple floating keycaps. The software theme must be clear at a glance. True orthographic isometric projection, equal scale, 45 degree yaw and about 35.264 degree elevation, no perspective convergence. Cubic voxel construction with subtly softened edges, soft studio light and delicate contact shadows, sky blue and cobalt accents, warm ivory, a small touch of golden yellow. Balanced centered composition with generous empty padding on every side, designed to occupy the right half of a website hero. Wide 16:9 canvas, ideally 2048x1152. Genuine transparent background. No text, no letters, no watermark, no logos, no photographic people, no busy environment. Charming but clear product illustration, not a screenshot.

