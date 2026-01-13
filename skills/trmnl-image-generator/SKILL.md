---
name: trmnl-image-generator
description: Generates TRMNL-compatible e-ink display images. Use when creating images for TRMNL devices, converting images to 1-bit format, or uploading content to e-ink displays. Triggers on "TRMNL", "e-ink", "e-paper", "terminal display".
allowed-tools:
  - Bash
  - Write
  - Read
  - Edit
---

# TRMNL Image Generator

Generate images compatible with TRMNL e-ink displays.

## Quick Start

Generate an HTML template, screenshot it, convert to 1-bit, upload:

```bash
# 1. Screenshot HTML at 800x480
npx playwright screenshot template.html raw.png --viewport-size=800,480

# 2. Convert to 1-bit monochrome
magick raw.png -monochrome -colors 2 -depth 1 -strip png:output.png

# 3. Upload to TRMNL
curl -X POST --data-binary @output.png \
  -H 'Content-Type: image/png' \
  'https://usetrmnl.com/api/plugin_settings/{PLUGIN_UUID}/image'
```

## Image Requirements

TRMNL devices require specific image formatting:

| Property | Requirement |
|----------|-------------|
| Size | 800x480 pixels |
| Depth | 1-bit (monochrome) |
| Colors | 2 (black and white) |
| Format | PNG or BMP3 |

## ImageMagick Conversions

### Standard 1-bit PNG

```bash
magick input.png -monochrome -colors 2 -depth 1 -strip png:output.png
```

### With Floyd-Steinberg dithering (better gradients)

```bash
magick input.png -dither FloydSteinberg -remap pattern:gray50 -depth 1 -strip png:output.png
```

### BMP3 format (alternative)

```bash
magick input.png -monochrome -colors 2 -depth 1 -strip bmp3:output.bmp
```

### 2-bit grayscale (FW 1.6.0+ only)

```bash
# Create colormap first
magick -size 4x1 xc:#000000 xc:#555555 xc:#aaaaaa xc:#ffffff +append -type Palette colormap-2bit.png

# Convert with colormap
magick input.png -resize 800x480\! -dither FloydSteinberg -remap colormap-2bit.png \
  -define png:bit-depth=2 -define png:color-type=0 output.png
```

## HTML Template Design

For best e-ink results:

- Use high-contrast black/white design
- Avoid gradients and anti-aliasing
- Use bold, sans-serif fonts (min 14px)
- Keep layouts simple with clear hierarchy
- Test with actual device (screens vary)

### Example Template Structure

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      width: 800px;
      height: 480px;
      font-family: system-ui, sans-serif;
      background: white;
      color: black;
      padding: 24px;
    }
    h1 { font-size: 48px; font-weight: 900; }
    .content { font-size: 18px; }
  </style>
</head>
<body>
  <h1>TITLE</h1>
  <div class="content">Content here</div>
</body>
</html>
```

## Upload API

### Plugin Image Endpoint

```bash
curl -X POST --data-binary @image.png \
  -H 'Content-Type: image/png' \
  'https://usetrmnl.com/api/plugin_settings/{PLUGIN_UUID}/image'
```

Response on success:
```json
{"data":{"message":"Image uploaded successfully"}}
```

### Finding Plugin UUID

1. Go to TRMNL dashboard
2. Navigate to your plugin settings
3. UUID is in the URL: `/plugin_settings/{UUID}`

## Verification

Check image properties with ImageMagick:

```bash
magick identify -verbose output.png | grep -E "(Geometry|Depth|Colors|Type)"
```

Expected output:
```
Geometry: 800x480+0+0
Type: Bilevel
Depth: 1-bit
Colors: 2
```

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Image not showing | Wrong bit depth | Use `-monochrome -colors 2 -depth 1` |
| Gray areas | 8-bit grayscale | Convert to 1-bit |
| Wrong size | Not 800x480 | Add `-resize 800x480\!` |
| Fuzzy text | Anti-aliasing | Use `-monochrome` (no dither) for text |
