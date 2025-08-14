# Fairy Bluetooth App - Build & Permission Guide

## What We Fixed

### iOS Issues:
1. ✅ **Updated Info.plist** with proper permission descriptions
2. ✅ **Enhanced permission handling** with iOS-specific messages
3. ✅ **Added location permission** handling (required for Bluetooth on iOS)

### Android Issues:
1. ✅ **Added missing permissions** in AndroidManifest.xml
2. ✅ **Enhanced permission handling** for Android 12+
3. ✅ **Added background location** and notification permissions
4. ✅ **Improved error messages** with Android-specific guidance

## Build Instructions

### 1. Clean and Get Dependencies
```bash
cd fairy_app
flutter clean
flutter pub get
```

### 2. Build for Both Platforms

#### Android:
```bash
flutter build apk --release
# or for debug
flutter build apk --debug
```

#### iOS:
```bash
flutter build ios
# Open in Xcode if needed
open ios/Runner.xcworkspace
```

## Permission Requirements

### Android Permissions:
- **BLUETOOTH** (legacy, pre-Android 12)
- **BLUETOOTH_ADMIN** (legacy, pre-Android 12)
- **BLUETOOTH_SCAN** (Android 12+)
- **BLUETOOTH_CONNECT** (Android 12+)
- **ACCESS_FINE_LOCATION** (required for Bluetooth scanning)
- **ACCESS_COARSE_LOCATION** (required for Bluetooth scanning)
- **ACCESS_BACKGROUND_LOCATION** (recommended for better functionality)
- **NOTIFICATION** (recommended for background service)

### iOS Permissions:
- **NSBluetoothAlwaysUsageDescription** (Bluetooth access)
- **NSBluetoothPeripheralUsageDescription** (Bluetooth peripheral access)
- **NSLocationWhenInUseUsageDescription** (Location when in use)
- **NSLocationAlwaysAndWhenInUseUsageDescription** (Location always)

## Testing the App

### First Launch:
1. App will request all necessary permissions
2. Grant permissions when prompted
3. If denied, use the Settings button to enable manually

### Permission Issues:
1. **Tap the shield icon** to see detailed permission status
2. **Use "Refresh Permissions"** button after enabling in Settings
3. **Check Settings** for any denied permissions

### Android Settings Path:
- **Settings > Apps > Fairy Bluetooth > Permissions**
- **Bluetooth**: Allow
- **Location**: Allow all the time (recommended)
- **Notifications**: Allow

### iOS Settings Path:
- **Settings > Privacy & Security > Bluetooth**
- **Settings > Privacy & Security > Location Services**

## Troubleshooting

### Common Issues:

#### "Bluetooth permission is required"
- Check if permissions are granted in device settings
- Use the "Refresh Permissions" button
- Reinstall the app if needed

#### "Location permission is required"
- This is normal on both iOS and Android
- Bluetooth scanning requires location access
- Grant location permission when prompted

#### App crashes on permission request
- Check if all permissions are properly declared
- Ensure Info.plist (iOS) and AndroidManifest.xml (Android) are correct
- Try clearing app data and reinstalling

### Debug Steps:
1. Check console logs for permission status
2. Verify all permission keys are present
3. Test on different Android/iOS versions
4. Check if device supports Bluetooth LE

## Key Files Modified

### iOS:
- `ios/Runner/Info.plist` - Permission descriptions
- `lib/main.dart` - Initial permission requests
- `lib/controllers/bluetooth_controller.dart` - Permission handling

### Android:
- `android/app/src/main/AndroidManifest.xml` - Permission declarations
- `lib/main.dart` - Android-specific permission requests
- `lib/controllers/bluetooth_controller.dart` - Android permission handling

### Both:
- `lib/screens/permission_status_screen.dart` - Permission status display
- `lib/screens/bluetooth_screen.dart` - Enhanced UI for permission issues

## Expected Behavior

### After Fixes:
1. ✅ App properly requests all permissions on first launch
2. ✅ Clear error messages when permissions are denied
3. ✅ Easy access to Settings for manual permission enabling
4. ✅ Permission status screen shows detailed information
5. ✅ App works on both iOS and Android devices

### User Experience:
1. **Permission Request**: Clear dialogs explaining what's needed
2. **Permission Denied**: Helpful messages with action buttons
3. **Settings Access**: Easy navigation to device settings
4. **Status Monitoring**: Real-time permission status display
5. **Error Recovery**: Simple steps to resolve permission issues

## Support

If you still encounter issues:
1. Check the console logs for detailed error messages
2. Verify all files were updated correctly
3. Test on a clean device/emulator
4. Ensure Flutter and dependencies are up to date 