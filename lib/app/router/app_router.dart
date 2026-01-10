import 'package:flutter/material.dart';
import 'package:language_app/features/home/free/free_conversation.dart';
import 'package:language_app/features/home/home_view.dart';
import 'package:language_app/features/home/conversation/conversation_chat.dart';
import 'package:language_app/features/home/conversation/conversation_chat_refactored.dart';
import 'package:language_app/features/menu/settings/change_avatar/select_avatar.dart';
import 'package:language_app/features/home/free/free_vocabulary.dart';
import 'package:language_app/features/home/free/common_conversation.dart';
import 'package:language_app/features/home/free/common_vocabulary.dart';
import 'package:language_app/features/home/vocabulary/vocabulary_lessons.dart';
import 'package:language_app/features/menu/menu_view.dart';
import 'package:language_app/features/auth/login.dart';
import 'package:language_app/features/auth/sign_up.dart';
import 'package:language_app/features/splash/splash.dart';
// import 'package:language_app/features/onboarding/onboarding_view.dart';

/// Route names as constants for type safety
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Auth routes
  static const String login = '/login';
  static const String signUp = '/signup';

  // Splash & Onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // Main app routes
  static const String home = '/home';
  static const String menu = '/menu';

  // Conversation routes
  static const String selectAvatar = '/select-avatar';
  static const String conversation = '/conversation';
  static const String conversationRefactored = '/conversation-refactored';
  static const String freeConversation = '/free-conversation';
  static const String commonConversation = '/common-conversation';

  // Vocabulary routes
  static const String vocabulary = '/vocabulary';
  static const String freeVocabulary = '/free-vocabulary';
  static const String commonVocabulary = '/common-vocabulary';
  static const String vocabularyLessons = '/vocabulary-lessons';
}

/// Page transition animations
enum PageTransitionType {
  fade,
  slide,
  scale,
  rotation,
  slideFromBottom,
  slideFromRight,
  none,
}

/// Custom page route with animations
class CustomPageRoute extends PageRouteBuilder {
  final Widget page;
  final PageTransitionType transitionType;
  final Duration duration;

  CustomPageRoute({
    required this.page,
    this.transitionType = PageTransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              animation,
              secondaryAnimation,
              child,
              transitionType,
            );
          },
        );

  static Widget _buildTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    PageTransitionType type,
  ) {
    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case PageTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case PageTransitionType.none:
        return child;
    }
  }
}

/// Route generator with custom transitions
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      // Auth routes
      case AppRoutes.login:
        return CustomPageRoute(
          page: const LoginPage(),
          transitionType: PageTransitionType.fade,
        );

      case AppRoutes.signUp:
        return CustomPageRoute(
          page: const SignUpPage(),
          transitionType: PageTransitionType.slideFromBottom,
        );

      // Splash Screen
      case AppRoutes.splash:
        return CustomPageRoute(
          page: const SplashScreen(),
          transitionType: PageTransitionType.fade,
        );

      // Onboarding
      case AppRoutes.onboarding:
        // TODO: Create OnboardingView
        return CustomPageRoute(
          page: const Scaffold(
            body: Center(child: Text('Onboarding - Coming Soon')),
          ),
          transitionType: PageTransitionType.fade,
        );

      // Main app
      case AppRoutes.home:
        final hasStartedLearning =
            args?['hasStartedLearning'] as bool? ?? false;
        return CustomPageRoute(
          page: HomeView(initialHasStartedLearning: hasStartedLearning),
          transitionType: PageTransitionType.fade,
        );

      case AppRoutes.menu:
        return CustomPageRoute(
          page: const MenuView(),
          transitionType: PageTransitionType.slideFromRight,
        );

      // Conversation routes
      case AppRoutes.selectAvatar:
        return CustomPageRoute(
          page: const SelectAvatar(),
          transitionType: PageTransitionType.slideFromBottom,
        );

      case AppRoutes.conversation:
        final avatarName = args?['selectedAvatarName'] as String? ?? 'Clara';
        return CustomPageRoute(
          page: ConversationChat(selectedAvatarName: avatarName),
          transitionType: PageTransitionType.slide,
        );

      case AppRoutes.conversationRefactored:
        final avatarName = args?['selectedAvatarName'] as String? ?? 'Clara';
        return CustomPageRoute(
          page: ConversationChatRefactored(selectedAvatarName: avatarName),
          transitionType: PageTransitionType.slide,
        );

      case AppRoutes.freeConversation:
        // TODO: Create FreeConversationChat or use existing
        final avatarName = args?['selectedAvatarName'] as String? ?? 'Clara';
        return CustomPageRoute(
          page: FreeConversationChat(selectedAvatarName: avatarName),
          transitionType: PageTransitionType.slide,
        );

      case AppRoutes.commonConversation:
        final avatarName = args?['selectedAvatarName'] as String? ?? 'Clara';
        return CustomPageRoute(
          page: CommonConversationChat(selectedAvatarName: avatarName),
          transitionType: PageTransitionType.slide,
        );

      // Vocabulary routes
      case AppRoutes.freeVocabulary:
        final avatarName = args?['selectedAvatarName'] as String? ?? 'Clara';
        return CustomPageRoute(
          page: FreeVocabularyChat(selectedAvatarName: avatarName),
          transitionType: PageTransitionType.slide,
        );

      case AppRoutes.commonVocabulary:
        final avatarName = args?['selectedAvatarName'] as String? ?? 'Clara';
        return CustomPageRoute(
          page: CommonVocabularyChat(selectedAvatarName: avatarName),
          transitionType: PageTransitionType.slide,
        );

      case AppRoutes.vocabularyLessons:
        final avatarName = args?['selectedAvatarName'] as String? ?? 'Clara';
        return CustomPageRoute(
          page: VocabularyLessons(selectedAvatarName: avatarName),
          transitionType: PageTransitionType.slide,
        );

      // Default/Unknown route
      default:
        return CustomPageRoute(
          page: Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          transitionType: PageTransitionType.fade,
        );
    }
  }
}

/// Navigation helper methods
class NavigationHelper {
  // Prevent instantiation
  NavigationHelper._();

  /// Navigate to a route with arguments
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and replace current route
  static Future<T?> navigateAndReplace<T>(
    BuildContext context,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, void>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and clear stack
  static Future<T?> navigateAndClearStack<T>(
    BuildContext context,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Check if can go back
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }
}
