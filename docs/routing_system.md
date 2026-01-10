# Routing System Documentation

## Overview

The app now uses a centralized routing system with custom page transitions for a smooth, professional user experience.

---

## File Structure

```
lib/app/
├── app.dart                    # Main app widget with routing config
└── router/
    └── app_router.dart         # Route definitions and transitions
```

---

## Usage Examples

### 1. Navigate to a Route

```dart
// Simple navigation
NavigationHelper.navigateTo(
  context,
  AppRoutes.conversation,
  arguments: {'selectedAvatarName': 'Karl'},
);

// Or using Navigator directly
Navigator.pushNamed(
  context,
  AppRoutes.conversation,
  arguments: {'selectedAvatarName': 'Karl'},
);
```

### 2. Navigate and Replace

```dart
// Replace current screen
NavigationHelper.navigateAndReplace(
  context,
  AppRoutes.home,
  arguments: {'hasStartedLearning': true},
);
```

### 3. Navigate and Clear Stack

```dart
// Clear all previous routes (e.g., after login)
NavigationHelper.navigateAndClearStack(
  context,
  AppRoutes.home,
);
```

### 4. Go Back

```dart
// Simple back navigation
NavigationHelper.goBack(context);

// With result
NavigationHelper.goBack(context, {'success': true});
```

---

## Available Routes

### Auth Routes
- `AppRoutes.login` - Login screen
- `AppRoutes.signUp` - Sign up screen

### Main Routes
- `AppRoutes.home` - Home screen
- `AppRoutes.menu` - Menu screen
- `AppRoutes.onboarding` - Onboarding flow

### Conversation Routes
- `AppRoutes.selectAvatar` - Avatar selection
- `AppRoutes.conversation` - Conversation chat
- `AppRoutes.conversationRefactored` - Refactored conversation
- `AppRoutes.freeConversation` - Free conversation
- `AppRoutes.commonConversation` - Common conversation

### Vocabulary Routes
- `AppRoutes.freeVocabulary` - Free vocabulary
- `AppRoutes.commonVocabulary` - Common vocabulary
- `AppRoutes.vocabularyLessons` - Vocabulary lessons

---

## Page Transition Types

### Available Transitions

1. **Fade** - Smooth fade in/out
2. **Slide** - Slide from right (default)
3. **SlideFromBottom** - Slide up from bottom
4. **SlideFromRight** - Slide from right
5. **Scale** - Scale up animation
6. **Rotation** - Rotate and fade
7. **None** - No animation

### Customizing Transitions

Edit `app_router.dart` to change transition for specific routes:

```dart
case AppRoutes.conversation:
  return CustomPageRoute(
    page: ConversationChat(selectedAvatarName: avatarName),
    transitionType: PageTransitionType.slideFromBottom, // Change this
    duration: Duration(milliseconds: 400), // Adjust duration
  );
```

---

## Migration Guide

### Before (Direct Navigation)

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ConversationChat(
      selectedAvatarName: avatarProvider.selectedAvatarName,
    ),
  ),
);
```

### After (Named Routes)

```dart
NavigationHelper.navigateTo(
  context,
  AppRoutes.conversation,
  arguments: {
    'selectedAvatarName': avatarProvider.selectedAvatarName,
  },
);
```

---

## Benefits

✅ **Centralized routing** - All routes in one place
✅ **Consistent animations** - Same transitions across app
✅ **Type-safe routes** - Constants prevent typos
✅ **Easy to maintain** - Change transitions globally
✅ **Better testing** - Mock navigation easily
✅ **Deep linking ready** - Named routes support deep links

---

## Next Steps

1. Update all `Navigator.push` calls to use `NavigationHelper`
2. Customize transitions per route as needed
3. Add route guards for authentication
4. Implement deep linking if needed
