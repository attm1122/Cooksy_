# Mobile UX Consistency

This document outlines mobile-specific UX considerations for Cooksy across iOS and Android.

## Platform Support

Cooksy uses Expo and React Native, providing a consistent experience across:
- **iOS** (iPhone & iPad)
- **Android** (phones & tablets)
- **Web** (responsive fallback)

## Navigation Patterns

### iOS
- **Swipe back gesture**: Enabled on all screens except cooking mode
- **Modal presentations**: Edit and Grocery use iOS-style bottom sheets
- **Full-screen transitions**: Cooking mode uses full-screen modal

### Android
- **Back button**: Fully supported via React Navigation
- **Fade transitions**: Android uses bottom-up fade animations
- **Card presentations**: Standard card-based navigation

### Universal
- **Header hidden**: All screens use in-screen headers for brand consistency
- **Bottom nav**: Persistent tab bar on main screens
- **Gesture handling**: react-native-gesture-handler enabled

## Safe Areas

All screens respect device safe areas:
- **Notch/Dynamic Island**: Content avoids top safe area
- **Home indicator**: Bottom nav clears home indicator
- **Status bar**: Managed by expo-status-bar with dark style

Components:
- `ScreenContainer` wraps content in `SafeAreaView`
- `KeyboardAvoidingView` enabled on form screens

## Haptic Feedback

Haptics provide tactile feedback on supported devices:

```bash
# Install for mobile builds
npx expo install expo-haptics
```

### Usage
All buttons include haptic feedback by default:
- `PrimaryButton`: Medium impact
- `SecondaryButton`: Light impact  
- `TertiaryButton`: Light impact
- `IconButton`: Configurable (default light)

To disable: `<PrimaryButton haptic={false}>`

### Programmatic Use
```typescript
import { useHaptics } from "@/hooks/use-haptics";

const haptics = useHaptics();
haptics.success(); // Completion feedback
haptics.error();   // Error feedback
haptics.selection(); // Picker selection
```

## Keyboard Handling

Forms handle keyboard appearance gracefully:
- **iOS**: `keyboardVerticalOffset` pushes content above keyboard
- **Android**: Window resizes to accommodate keyboard
- **Scroll views**: Auto-scroll to focused inputs

Enable on forms: `<ScreenContainer keyboardAvoiding>`

## Screen-Specific Mobile Behaviors

### Recipe Detail
- Swipe back to return to recipes list
- "Save Recipe" shows saved state
- "Fix Recipe" navigates to edit screen

### Cooking Mode
- Full-screen modal (no swipe to dismiss)
- X button in header for exit
- Large touch targets for step navigation
- High contrast for kitchen visibility

### Edit Recipe
- Modal presentation on iOS
- Keyboard avoiding behavior
- Cancel button to discard changes

### Grocery List
- Modal presentation on iOS
- Check items with tap
- Back button to return to recipe

### Processing
- No swipe back (prevents accidental cancellation)
- Retry button appears on error
- Progress stages animate smoothly

## Touch Targets

All interactive elements meet minimum touch targets:
- **Buttons**: 44x44pt minimum
- **List items**: Full width, 56pt height
- **Icons**: 44x44pt touch area
- **Cards**: Entire card tappable with visual feedback

## Visual Feedback

### Press States
- Buttons: `active:opacity-80` (dim on press)
- Cards: Scale down slightly on press (0.985)
- List items: Background color change

### Loading States
- Activity indicators on buttons
- Disabled state with 50% opacity
- Skeleton screens for thumbnails

## Testing on Mobile

### iOS Simulator
```bash
npx expo run:ios
```

### Android Emulator
```bash
npx expo run:android
```

### Physical Device
```bash
npx expo start
# Scan QR code with Expo Go app
```

### Test Checklist
- [ ] Swipe back works on all screens except cooking mode
- [ ] Keyboard doesn't cover form inputs
- [ ] Bottom nav clears home indicator/gesture bar
- [ ] Haptic feedback on button presses (physical device)
- [ ] Safe areas respected on notch devices
- [ ] Back button works on Android
- [ ] Modal presentations feel native
- [ ] Touch targets are easy to hit

## Platform-Specific Files

Currently no platform-specific files needed. If required:
- `Component.ios.tsx` for iOS-specific implementation
- `Component.android.tsx` for Android-specific implementation
- `Component.native.tsx` for both mobile platforms
- `Component.tsx` for web (or shared fallback)

## Responsive Considerations

While primarily a mobile app, Cooksy handles:
- **Tablets**: Uses max-width containers (1120px)
- **Landscape**: Scroll views adapt to available height
- **Web**: Full responsive layout with mouse hover states
