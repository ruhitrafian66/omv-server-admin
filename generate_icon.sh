#!/bin/bash

# Script to convert SVG to PNG using macOS built-in tools

SVG_FILE="OMVServerAdmin/Assets.xcassets/AppIcon.appiconset/app-icon.svg"
OUTPUT_DIR="OMVServerAdmin/Assets.xcassets/AppIcon.appiconset"

echo "Converting SVG to PNG using qlmanage..."

# Use qlmanage (Quick Look) to render SVG to PNG
qlmanage -t -s 1024 -o "$OUTPUT_DIR" "$SVG_FILE" 2>/dev/null

# Rename the output file
if [ -f "${OUTPUT_DIR}/app-icon.svg.png" ]; then
    mv "${OUTPUT_DIR}/app-icon.svg.png" "${OUTPUT_DIR}/app-icon-1024.png"
    echo "✅ Icon generated: ${OUTPUT_DIR}/app-icon-1024.png"
    echo ""
    echo "Next steps:"
    echo "1. Open Xcode"
    echo "2. Select Assets.xcassets → AppIcon"
    echo "3. Drag app-icon-1024.png into the 1024pt slot"
    echo ""
else
    echo "❌ Conversion failed. Please use one of these alternatives:"
    echo ""
    echo "Option 1: Use Safari"
    echo "  - Open app-icon.svg in Safari"
    echo "  - Right-click → Save As → PNG"
    echo ""
    echo "Option 2: Use online converter"
    echo "  - Go to https://cloudconvert.com/svg-to-png"
    echo "  - Upload app-icon.svg"
    echo "  - Set size to 1024x1024"
    echo "  - Download and add to Xcode"
    echo ""
    echo "Option 3: Use Preview"
    echo "  - Open app-icon.svg in Safari"
    echo "  - File → Export as PDF"
    echo "  - Open PDF in Preview"
    echo "  - File → Export → PNG (1024x1024)"
fi
