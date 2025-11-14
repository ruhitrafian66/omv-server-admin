# How to Create the Xcode Project

Since Xcode project files are complex binary/XML structures, here's how to create the project properly:

## Option 1: Create in Xcode (Recommended)

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Click "Next"
5. Fill in:
   - Product Name: `OMVServerAdmin`
   - Team: (your team)
   - Organization Identifier: `com.yourname` (or any reverse domain)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Uncheck "Include Tests"
6. Click "Next" and save in the current directory
7. **Delete the default files** Xcode creates:
   - Delete `ContentView.swift` (we have our own)
   - Delete `OMVServerAdminApp.swift` (we have our own)
   - Delete `Assets.xcassets` if you want (optional)
8. **Add our files to the project:**
   - Right-click on the OMVServerAdmin folder in Xcode
   - Choose "Add Files to OMVServerAdmin..."
   - Select all the files in the `OMVServerAdmin` folder
   - Make sure "Copy items if needed" is UNCHECKED
   - Click "Add"

## Option 2: Use Existing Files Structure

The files are already organized correctly. Just:

1. Open Xcode
2. File → New → Project
3. iOS → App → Next
4. Product Name: `OMVServerAdmin`
5. Save to a DIFFERENT location temporarily
6. Close Xcode
7. Copy the `.xcodeproj` folder from the new location to this directory
8. Open the project
9. Remove the default files Xcode created
10. Add our existing files

## Required Capabilities

After creating the project, add these capabilities:

1. Select your target → "Signing & Capabilities" tab
2. Click "+ Capability" and add:
   - **Background Modes** (check "Background fetch" and "Background processing")
   - **Access WiFi Information**

## Files Structure

All source files are already in place:
```
OMVServerAdmin/
├── OMVServerAdminApp.swift (main app entry)
├── ContentView.swift
├── Info.plist
├── Models/
│   ├── ConnectionManager.swift
│   ├── DataModels.swift
│   └── OMVAPIClient.swift
├── ViewModels/
│   └── DashboardViewModel.swift
├── Views/
│   ├── ConnectionView.swift
│   ├── DashboardView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── CircularProgressView.swift
│       └── CPUHistoryChart.swift
└── Services/
    └── BackgroundMonitoringService.swift
```
