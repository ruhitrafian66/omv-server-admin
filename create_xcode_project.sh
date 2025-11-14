#!/bin/bash

# This script creates a new Xcode project and adds all our files to it

PROJECT_NAME="OMVServerAdmin"
BUNDLE_ID="com.omvadmin.app"

echo "Creating Xcode project..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)

# Create project using xcodegen or manually
cat > project.yml << EOF
name: $PROJECT_NAME
options:
  bundleIdPrefix: com.omvadmin
targets:
  $PROJECT_NAME:
    type: application
    platform: iOS
    deploymentTarget: "16.0"
    sources:
      - OMVServerAdmin
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
      INFOPLIST_FILE: OMVServerAdmin/Info.plist
      SWIFT_VERSION: "5.0"
      TARGETED_DEVICE_FAMILY: "1,2"
    entitlements:
      path: OMVServerAdmin/OMVServerAdmin.entitlements
EOF

echo "Project configuration created."
echo ""
echo "To create the Xcode project, you have two options:"
echo ""
echo "Option 1: Install XcodeGen and run:"
echo "  brew install xcodegen"
echo "  xcodegen generate"
echo ""
echo "Option 2: Create manually in Xcode (see CREATE_PROJECT.md)"
