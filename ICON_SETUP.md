# App Icon Setup Instructions

The SVG logo has been created at `OMVServerAdmin/Assets.xcassets/AppIcon.appiconset/app-icon.svg`

## Option 1: Use Online Converter (Easiest)

1. Open the SVG file in a web browser or text editor
2. Go to https://www.appicon.co or https://appicon.build
3. Upload the `app-icon.svg` file
4. Download the generated icon set
5. In Xcode:
   - Select `Assets.xcassets` → `AppIcon`
   - Drag all the generated PNG files into the appropriate slots
   - Or use "App Icon Source" and select the 1024x1024 PNG

## Option 2: Use macOS Preview (Quick)

1. Open `app-icon.svg` in Safari
2. Take a screenshot or export as PNG at 1024x1024
3. In Xcode:
   - Select `Assets.xcassets` → `AppIcon`
   - Drag the 1024x1024 PNG into the "1024pt" slot
   - Xcode will auto-generate all other sizes

## Option 3: Use Xcode's Single Size Feature (Recommended)

1. Convert SVG to 1024x1024 PNG using any method
2. In Xcode:
   - Select your target → General tab
   - Under "App Icons and Launch Screen"
   - Click the icon placeholder
   - Select "Single Size" from the dropdown
   - Drag your 1024x1024 PNG

## Option 4: Install ImageMagick and Convert

```bash
# Install ImageMagick
brew install imagemagick librsvg

# Convert SVG to PNG
cd OMVServerAdmin/Assets.xcassets/AppIcon.appiconset/
rsvg-convert -w 1024 -h 1024 app-icon.svg -o app-icon-1024.png
```

Then follow Option 2 or 3 above.

## Temporary Workaround

For now, Xcode will use the default blue icon. The app will still work perfectly.
You can add the icon later without affecting functionality.
