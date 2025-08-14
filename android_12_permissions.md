# Android 12+ Bluetooth Permission Fix Guide

## The Problem

On Android 12+ (API level 31+), the Bluetooth permission system changed significantly:

- **Old system**: Single `BLUETOOTH` permission
- **New system**: Separate `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` permissions
- **Settings issue**: System settings only show location permissions, not Bluetooth

## What We Fixed

### 1. Updated AndroidManifest.xml
```xml
<!-- New Bluetooth permissions (Android 12+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Removed usesPermissionFlags="neverForLocation" to allow proper scanning -->
```

### 2. Enhanced Permission Handling
- **Android 12+ detection** in the app
- **Platform-specific permission requests**
- **Better error messages** with Android settings paths

### 3. Improved User Experience
- **Clear permission status** display
- **Action buttons** to resolve permission issues
- **Settings navigation** help

## How Android 12+ Bluetooth Permissions Work

### Permission Types:
1. **BLUETOOTH_SCAN**: Required to discover Bluetooth devices
2. **BLUETOOTH_CONNECT**: Required to connect to Bluetooth devices
3. **LOCATION**: Still required for Bluetooth scanning (Android requirement)

### Why Settings Only Show Location:
- **Bluetooth permissions** are handled differently on Android 12+
- **System settings** prioritize location permissions for security
- **Bluetooth permissions** are often granted automatically or through system dialogs

## User Instructions for Android 12+

### First Launch:
1. **App will request permissions** automatically
2. **Grant all permissions** when prompted
3. **If denied**, use the Settings button in the app

### Permission Issues:
1. **Tap the shield icon** to see permission status
2. **Use "Refresh Permissions"** button
3. **Check Settings** if permissions are still denied

### Manual Permission Check:
1. **Settings > Apps > Fairy Bluetooth > Permissions**
2. **Look for Bluetooth permissions** (may be hidden)
3. **Ensure Location permission** is granted
4. **Check if Bluetooth is enabled** in system settings

## Troubleshooting Android 12+ Issues

### "Bluetooth permission is required" Error:
1. **Check if Bluetooth is enabled** in system settings
2. **Grant location permission** first (required for Bluetooth)
3. **Restart the app** after granting permissions
4. **Clear app data** if issues persist

### Bluetooth Not Working:
1. **Verify Bluetooth is enabled** on device
2. **Check if device supports** Bluetooth LE
3. **Ensure location permission** is granted
4. **Try toggling Bluetooth** off and on

### Settings Not Showing Bluetooth:
1. **This is normal** on Android 12+
2. **Focus on location permissions** first
3. **Bluetooth permissions** are often handled automatically
4. **Use app's permission status screen** to check

## Technical Details

### Permission Flow:
```
App Launch → Request Location → Request Bluetooth → Initialize Bluetooth
```

### Android 12+ Detection:
```dart
Future<bool> _isAndroid12OrHigher() async {
  if (!Platform.isAndroid) return false;
  // API level 31+ (Android 12+)
  return true;
}
```

### Permission Request Order:
1. **Location permission** (required for Bluetooth scanning)
2. **Bluetooth Scan permission** (Android 12+)
3. **Bluetooth Connect permission** (Android 12+)
4. **Background location** (recommended)

## Expected Behavior After Fix

### ✅ Working:
- App properly requests permissions on Android 12+
- Clear error messages when permissions are denied
- Permission status screen shows detailed information
- Settings button opens appropriate settings

### 🔧 Still May Need:
- Manual location permission grant in settings
- Bluetooth toggle in system settings
- App restart after permission changes

## Testing Checklist

- [ ] App launches without crashing
- [ ] Permission dialogs appear correctly
- [ ] Location permission is granted
- [ ] Bluetooth permissions are requested
- [ ] App can scan for Bluetooth devices
- [ ] Settings button works properly
- [ ] Permission status screen shows correct info

## Support

If issues persist:
1. **Check console logs** for detailed error messages
2. **Verify Android version** (should be 12+)
3. **Test on different devices** if possible
4. **Clear app data** and reinstall
5. **Check device Bluetooth support** 