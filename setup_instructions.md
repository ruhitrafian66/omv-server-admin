# Quick Setup Instructions

The easiest way to get this project running:

## Method 1: Create Project in Xcode (5 minutes)

1. **Open Xcode**
2. **File → New → Project**
3. Select **iOS → App**
4. Click **Next**
5. Enter these details:
   - Product Name: `OMVServerAdmin`
   - Team: Select your team
   - Organization Identifier: `com.omvadmin` (or your own)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Uncheck "Include Tests"
6. Click **Next**
7. **Save in the parent directory** (the one containing the OMVServerAdmin folder)
8. Xcode will create the project

9. **Delete Xcode's default files:**
   - In Xcode's file navigator, delete:
     - `ContentView.swift` (select "Move to Trash")
     - `OMVServerAdminApp.swift` (select "Move to Trash")

10. **Add our files:**
    - Right-click the `OMVServerAdmin` folder (blue icon) in Xcode
    - Select **"Add Files to OMVServerAdmin..."**
    - Navigate to the `OMVServerAdmin` folder on disk
    - Select ALL files and folders inside it
    - **IMPORTANT:** Uncheck "Copy items if needed"
    - Check "Create groups"
    - Click **Add**

11. **Replace Info.plist:**
    - In Xcode, select the target → "Info" tab
    - Right-click on Info.plist in the file navigator
    - Select "Delete" → "Remove Reference" (not Move to Trash)
    - Drag our `OMVServerAdmin/Info.plist` into the project
    - Select target → Build Settings → search "Info.plist"
    - Set "Info.plist File" to: `OMVServerAdmin/Info.plist`

12. **Add Capabilities:**
    - Select your target → **Signing & Capabilities** tab
    - Click **"+ Capability"**
    - Add **"Background Modes"**
      - Check ✓ "Background fetch"
      - Check ✓ "Background processing"
    - Click **"+ Capability"** again
    - Add **"Access WiFi Information"**

13. **Build and Run!**
    - Select a simulator or device
    - Press Cmd+R to build and run

## Method 2: Use XcodeGen (Automated)

If you have Homebrew:

```bash
brew install xcodegen
xcodegen generate
open OMVServerAdmin.xcodeproj
```

Then just add the capabilities in step 12 above.

## Troubleshooting

**"No such module" errors:**
- Make sure all .swift files are added to the target
- Check target membership in File Inspector (right panel)

**Build errors:**
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Restart Xcode

**Background monitoring not working:**
- Make sure capabilities are added
- Check Info.plist has BGTaskSchedulerPermittedIdentifiers
- Test on a real device (simulators have limited background support)
