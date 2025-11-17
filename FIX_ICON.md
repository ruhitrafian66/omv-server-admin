# Fix App Icon Not Showing

The icon file is valid and properly configured, but Xcode sometimes needs manual intervention.

## Quick Fix Steps:

### 1. Clean Xcode Derived Data
```bash
# In Terminal, run:
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 2. In Xcode:
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. **Close Xcode completely**
3. **Reopen the project**
4. **Build and Run** (Cmd+R)

### 3. If Still Not Working - Manual Icon Setup:

1. In Xcode, select **Assets.xcassets** in the file navigator
2. Click on **AppIcon** 
3. You should see the icon slots
4. If the icon isn't showing:
   - Drag `app-icon-1024.png` from Finder directly into the **1024pt** slot
   - Or right-click the 1024pt slot → **Show in Finder** → replace the file

### 4. Alternative: Use Xcode's Single Size Feature

1. Select your **target** → **General** tab
2. Under **App Icons and Launch Screen**
3. Click the **App Icon** dropdown
4. Select **"Use Asset Catalog"** if not already selected
5. Make sure **AppIcon** is selected

### 5. Delete the App from Device/Simulator

Sometimes the old icon is cached:
1. **Delete the app** from your device/simulator
2. **Clean Build Folder** (Cmd+Shift+K)
3. **Build and Run** again

### 6. Check Build Settings

1. Select your target
2. Go to **Build Settings**
3. Search for **"Asset Catalog Compiler"**
4. Make sure **"Asset Catalog App Icon Set Name"** is set to **"AppIcon"**

## Verify Icon File

The icon file exists and is valid:
- Location: `OMVServerAdmin/Assets.xcassets/AppIcon.appiconset/app-icon-1024.png`
- Size: 1024x1024 pixels
- Format: PNG RGBA
- File size: 827KB

## Still Not Working?

If none of the above works, the icon will appear when you:
1. Archive the app for distribution
2. Install via TestFlight
3. Install via App Store

The icon might not show in debug builds but will appear in release builds.
