#!/bin/bash
# IconGen - Generate macOS app icon assets from Leonardo.ai images
# Usage: ./icon-gen.sh /path/to/generated-image.png

set -e

INPUT_IMAGE="$1"
if [ -z "$INPUT_IMAGE" ]; then
    echo "Usage: ./icon-gen.sh /path/to/generated-image.png"
    exit 1
fi

# Check for ImageMagick
if ! command -v sips &> /dev/null; then
    echo "Error: sips is required (built into macOS)"
    exit 1
fi

# Create Assets.xcassets directory structure
ASSETS_DIR="Textcavator/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ASSETS_DIR"

# Function to resize image
resize_to() {
    local width=$1
    local height=$2
    local output=$3
    sips -z "$height" "$width" "$INPUT_IMAGE" --out "$output" 2>/dev/null || \
    convert "$INPUT_IMAGE" -resize "${width}x${height}" "$output"
}

echo "Generating icon sizes..."

# Generate all required sizes for macOS app icons
# Note: Using nearest-neighbor for pixel-perfect scaling where possible

# macOS icon sizes (in points, @1x and @2x)
sizes=(
    "16:16:AppIcon-16.png"
    "32:32:AppIcon-16@2x.png"
    "32:32:AppIcon-32.png"
    "64:64:AppIcon-32@2x.png"
    "128:128:AppIcon-128.png"
    "256:256:AppIcon-128@2x.png"
    "256:256:AppIcon-256.png"
    "512:512:AppIcon-256@2x.png"
    "512:512:AppIcon-512.png"
    "1024:1024:AppIcon-512@2x.png"
)

for size in "${sizes[@]}"; do
    IFS=':' read -r w h name <<< "$size"
    echo "  Creating ${w}x${h} -> $name"
    resize_to "$w" "$h" "$ASSETS_DIR/$name"
done

# Create Contents.json for Xcode
cat > "$ASSETS_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "AppIcon-16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "AppIcon-32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "AppIcon-32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "AppIcon-128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "AppIcon-128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "AppIcon-256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "AppIcon-256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "AppIcon-512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "AppIcon-512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo "✅ Icon assets generated in $ASSETS_DIR/"
echo ""
echo "Next steps:"
echo "1. Open Textcavator.xcodeproj in Xcode"
echo "2. Select project -> General -> App Icon"
echo "3. Click 'AppIcon' and select 'AppIcon' from asset catalog"
echo "4. Build and run!"