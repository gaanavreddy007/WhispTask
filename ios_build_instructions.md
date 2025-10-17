# iOS Build Instructions for WhispTask

## Prerequisites (Mac Required)
- macOS 12.0+ 
- Xcode 14.0+
- Flutter SDK 3.35.6+
- iOS Simulator or Physical Device

## Build Commands

### 1. Debug Build (for testing)
```bash
# Run on iOS Simulator
flutter run -d ios

# Build debug version
flutter build ios --debug
```

### 2. Release Build (equivalent to APK)
```bash
# Build iOS app bundle
flutter build ios --release --no-codesign

# Build IPA file (installable package)
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### 3. Manual IPA Creation
```bash
# After building iOS app
cd build/ios/iphoneos
zip -r WhispTask.ipa Runner.app
```

## File Locations After Build

### iOS App Bundle
- Location: `build/ios/iphoneos/Runner.app`
- Usage: For Simulator testing

### IPA File  
- Location: `build/ios/ipa/whisptask.ipa`
- Usage: For device installation (like APK)

## Installation Methods

### 1. iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Install on simulator
xcrun simctl install <device-id> build/ios/iphoneos/Runner.app

# Launch app
xcrun simctl launch <device-id> com.computepool.whisptask
```

### 2. Physical Device (requires Apple Developer Account)
- Use Xcode to install
- Or use TestFlight for distribution
- Or use third-party tools like 3uTools

## Current App Configuration

✅ **Bundle ID**: com.computepool.whisptask
✅ **Display Name**: WhispTask  
✅ **Version**: 1.0.0+1
✅ **Permissions Configured**:
   - Microphone access
   - Speech recognition
   - Notifications
   - Background processing

✅ **Firebase Integration**:
   - Google Sign-In configured
   - All Firebase services ready

✅ **Dependencies**:
   - All packages iOS compatible
   - Vosk Flutter for offline speech recognition

## Troubleshooting

### Common Issues:
1. **Code signing errors**: Use `--no-codesign` flag
2. **Missing iOS deployment target**: Set in ios/Runner.xcodeproj
3. **Plugin compatibility**: All plugins in pubspec.yaml are iOS compatible

### Build Verification:
```bash
# Check iOS setup
flutter doctor -v

# Analyze iOS-specific issues
flutter analyze

# Clean and rebuild
flutter clean
flutter pub get
flutter build ios --release --no-codesign
```

## Alternative: GitHub Actions Build

The project includes `.github/workflows/ios-build.yml` for automatic iOS builds:
- Triggers on push to main/develop
- Builds unsigned IPA
- Uploads as artifact for download
- No Mac required locally
