# MVVM Architecture Documentation

## Overview

This project now follows the **MVVM (Model-View-ViewModel)** architectural pattern for better separation of concerns, testability, and maintainability.

---

## Architecture Layers

### 1. **Model** (`lib/core/models/`)
- Data structures and business entities
- JSON serialization/deserialization
- No UI dependencies

**Examples:**
- `ConversationModels` - Conversation data structures
- `LearningModels` - Progress and lesson data
- `UserProgress` - User statistics

### 2. **View** (`lib/features/*/views/` or `*.dart` screens)
- UI components (Widgets)
- Displays data from ViewModel
- Handles user interactions
- **No business logic**

**Examples:**
- `ConversationChatRefactored` - Conversation UI
- `FreeVocabularyChat` - Vocabulary quiz UI
- `HomeView` - Home screen UI

### 3. **ViewModel** (`lib/core/viewmodels/`)
- Business logic and state management
- Exposes data to Views
- Handles user actions
- Communicates with Models and Services

**Examples:**
- `ConversationViewModel` - Conversation logic
- `VocabularyViewModel` - Quiz logic
- `LearningProgressViewModel` - Progress tracking

---

## ViewModel Hierarchy

```
BaseViewModel (abstract)
├── ConversationViewModel
├── VocabularyViewModel
├── LearningProgressViewModel
└── (Future ViewModels...)
```

### BaseViewModel Features

All ViewModels extend `BaseViewModel` which provides:

1. **Loading State Management**
   ```dart
   bool get isLoading
   void setLoading(bool loading)
   ```

2. **Error Handling**
   ```dart
   String? get error
   bool get hasError
   void setError(String? error)
   void clearError()
   ```

3. **Safe Async Execution**
   ```dart
   Future<T?> executeAsync<T>(
     Future<T> Function() operation,
     {String? errorMessage, bool showLoading = true}
   )
   ```

4. **Disposal Safety**
   - Prevents notifications after disposal
   - `safeNotifyListeners()` method

---

## Usage Patterns

### In Views (Widgets)

#### 1. Watch for Changes
```dart
@override
Widget build(BuildContext context) {
  final viewModel = context.watch<ConversationViewModel>();
  
  if (viewModel.isLoading) {
    return CircularProgressIndicator();
  }
  
  if (viewModel.hasError) {
    return Text('Error: ${viewModel.error}');
  }
  
  return ListView.builder(
    itemCount: viewModel.messages.length,
    itemBuilder: (context, index) {
      return MessageWidget(viewModel.messages[index]);
    },
  );
}
```

#### 2. Trigger Actions
```dart
void _sendMessage() {
  final viewModel = context.read<ConversationViewModel>();
  viewModel.sendMessage(_textController.text);
  _textController.clear();
}
```

#### 3. Initialize Data
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ConversationViewModel>().loadConversation();
  });
}
```

---

## Dependency Injection

### Current Setup (main.dart)

```dart
MultiProvider(
  providers: [
    // Core Providers
    ChangeNotifierProvider(create: (_) => AvatarProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AudioProvider()),
    
    // Repository Layer
    Provider<ILearningRepository>(
      create: (_) => MockLearningRepository(),
    ),
    
    // ViewModels with Dependencies
    ChangeNotifierProxyProvider<ILearningRepository, LearningProgressViewModel>(
      create: (context) => LearningProgressViewModel(
        context.read<ILearningRepository>(),
      ),
      update: (_, repository, previous) =>
          previous ?? LearningProgressViewModel(repository),
    ),
    
    // Simple ViewModels
    ChangeNotifierProvider(create: (_) => ConversationViewModel()),
    ChangeNotifierProvider(create: (_) => VocabularyViewModel()),
  ],
  child: const MyApp(),
)
```

### Provider Types

1. **Provider** - For services (non-changing)
2. **ChangeNotifierProvider** - For ViewModels/Providers
3. **ProxyProvider** - For dependencies between providers

---

## Benefits of MVVM

### 1. **Separation of Concerns**
- UI logic separated from business logic
- Easier to understand and maintain
- Clear responsibilities for each layer

### 2. **Testability**
```dart
// Easy to test ViewModels without UI
test('should send message correctly', () {
  final viewModel = ConversationViewModel();
  viewModel.sendMessage('Hello');
  
  expect(viewModel.messages.length, 1);
  expect(viewModel.messages.first['text'], 'Hello');
});
```

### 3. **Reusability**
- ViewModels can be reused across different Views
- Business logic not tied to specific UI

### 4. **Better Error Handling**
- Centralized error management in BaseViewModel
- Consistent error display across app

---

## Migration from Providers to ViewModels

### Before (Provider)
```dart
class ConversationProvider extends ChangeNotifier {
  List<Message> messages = [];
  
  void sendMessage(String text) {
    messages.add(Message(text));
    notifyListeners();
  }
}
```

### After (ViewModel)
```dart
class ConversationViewModel extends BaseViewModel {
  List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);
  
  void sendMessage(String text) {
    _messages.add(Message(text));
    safeNotifyListeners();
  }
  
  Future<void> loadMessages() async {
    await executeAsync(
      () async {
        _messages = await repository.fetchMessages();
      },
      errorMessage: 'Failed to load messages',
    );
  }
}
```

### Key Differences
1. ✅ Extends `BaseViewModel` for common functionality
2. ✅ Private fields with public getters (encapsulation)
3. ✅ Built-in loading and error states
4. ✅ Safe async execution with `executeAsync`
5. ✅ Disposal safety with `safeNotifyListeners`

---

## File Structure

```
lib/
├── core/
│   ├── viewmodels/
│   │   ├── base_viewmodel.dart           # Base class
│   │   ├── conversation_viewmodel.dart   # Conversation logic
│   │   ├── vocabulary_viewmodel.dart     # Vocabulary logic
│   │   └── learning_progress_viewmodel.dart # Progress logic
│   ├── providers/                        # Legacy providers (being phased out)
│   ├── models/                           # Data models
│   ├── services/                         # Services (API, TTS, etc.)
│   └── data/                             # Repositories
├── features/
│   └── home/
│       ├── conversation/
│       │   ├── views/
│       │   │   └── conversation_chat.dart
│       │   └── widgets/
│       └── vocabulary/
│           ├── views/
│           │   └── vocabulary_lesson.dart
│           └── widgets/
└── main.dart
```

---

## Best Practices

### 1. **Keep Views Dumb**
- Views should only display data and handle user input
- No business logic in widgets

### 2. **Use Immutable Data**
- Return unmodifiable lists/maps from ViewModels
- Prevents accidental mutations

### 3. **Handle Errors Gracefully**
- Use `executeAsync` for all async operations
- Display user-friendly error messages

### 4. **Dispose Properly**
- ViewModels automatically handle disposal
- Always call `super.dispose()` if overriding

### 5. **Test ViewModels**
- Write unit tests for all ViewModel logic
- Mock dependencies (repositories, services)

---

## Future Enhancements

1. **State Classes with Freezed**
   - Immutable state objects
   - Better type safety

2. **Service Locator (GetIt)**
   - Alternative to Provider for DI
   - Better for complex dependencies

3. **Riverpod Migration**
   - More type-safe than Provider
   - Better compile-time safety

4. **BLoC Pattern**
   - For more complex state management
   - Event-driven architecture

---

## Summary

The MVVM pattern provides:
- ✅ Clear separation of concerns
- ✅ Better testability
- ✅ Improved maintainability
- ✅ Consistent error handling
- ✅ Reusable business logic

All new features should follow this pattern for consistency and quality.
