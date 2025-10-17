# WhispTask IPA Installation Guide

## Method 1: AltStore (Recommended)

### Prerequisites
- Windows/Mac computer
- iPhone/iPad with iOS 12.2+
- USB cable
- iTunes installed

### Step 1: Setup AltStore on Computer
1. **Download AltStore**:
   - Go to https://altstore.io
   - Download for Windows or Mac
   - Install the desktop application

2. **Install iTunes**:
   - Download from Apple's website
   - Required for device communication
   - Restart computer after installation

### Step 2: Install AltStore on iPhone/iPad
1. **Connect device** via USB cable
2. **Open AltStore desktop app**
3. **Click "Install AltStore"**
4. **Select your iPhone/iPad** from the list
5. **Enter Apple ID credentials** when prompted
6. **Wait for installation** to complete

### Step 3: Trust AltStore
1. **Go to Settings** on iPhone/iPad
2. **General > VPN & Device Management**
3. **Find your Apple ID** under "Developer App"
4. **Tap and select "Trust"**
5. **Confirm trust** in the popup

### Step 4: Install WhispTask IPA
1. **Download WhispTask.ipa** from GitHub Actions
2. **Transfer IPA to iPhone/iPad** via:
   - AirDrop from Mac
   - Email attachment
   - Cloud storage (iCloud, Google Drive)
   - iTunes File Sharing

3. **Open AltStore app** on iPhone/iPad
4. **Tap the "+" button** (top-left corner)
5. **Browse and select** WhispTask.ipa file
6. **Tap "Install"**
7. **Wait for installation** (may take a few minutes)

### Step 5: Trust WhispTask App
1. **Go to Settings > General > VPN & Device Management**
2. **Find WhispTask** under "Enterprise App" or your Apple ID
3. **Tap and select "Trust"**
4. **Confirm trust**

### Step 6: Launch WhispTask
1. **Find WhispTask** on home screen
2. **Tap to launch**
3. **Grant permissions** when prompted:
   - Microphone access
   - Notifications
   - Speech recognition

## Method 2: 3uTools (Alternative)

### Prerequisites
- Windows computer
- iPhone/iPad
- USB cable
- iTunes installed

### Steps
1. **Download 3uTools** from https://3u.com
2. **Install and open** 3uTools
3. **Connect iPhone/iPad** via USB
4. **Wait for device detection**
5. **Go to "Apps" section**
6. **Click "Install Local App"**
7. **Select WhispTask.ipa** file
8. **Click "Install"**
9. **Trust developer** in device settings

## Troubleshooting

### Common Issues

#### "Untrusted Enterprise Developer"
- **Solution**: Go to Settings > General > VPN & Device Management > Trust developer

#### "Unable to Install App"
- **Solution**: Check device storage space, restart device, try again

#### "App Won't Launch"
- **Solution**: Ensure all permissions granted, check iOS compatibility

#### "Installation Failed"
- **Solution**: 
  - Verify IPA file integrity
  - Check iOS version compatibility (iOS 12.2+)
  - Restart AltStore/3uTools

### App Expiration (AltStore)

#### Free Apple ID (7-day expiration):
1. **Open AltStore** weekly
2. **Tap "Refresh All"**
3. **Enter Apple ID** credentials
4. **Apps renewed** for another 7 days

#### Paid Developer Account (1-year expiration):
- Apps stay valid for 1 year
- No weekly refresh needed

## Security Notes

### Safe Installation
- ✅ AltStore is open-source and trusted
- ✅ 3uTools is widely used and safe
- ✅ WhispTask IPA built from your own code

### Apple's Restrictions
- iOS doesn't allow direct IPA installation (unlike Android APK)
- Sideloading requires computer-based tools
- Apps may expire and need refresh

## Alternative: TestFlight Distribution

### For Beta Testing (Requires Apple Developer Account)
1. **Upload IPA** to App Store Connect
2. **Create TestFlight build**
3. **Add beta testers** (email addresses)
4. **Send invitations**
5. **Testers install** via TestFlight app

### Benefits of TestFlight
- ✅ No expiration issues
- ✅ Easy distribution to multiple users
- ✅ Automatic updates
- ✅ Built-in feedback system
- ❌ Requires $99/year Apple Developer Account

## Summary

**Easiest Method**: AltStore
**Most Reliable**: TestFlight (with developer account)
**Windows-Friendly**: 3uTools

Choose the method that best fits your needs and technical comfort level!
