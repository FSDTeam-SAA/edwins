import 'package:flutter/material.dart';
import 'package:language_app/core/providers/avatar_provider.dart';
import 'package:language_app/core/providers/audio_provider.dart';
import 'package:language_app/core/providers/conversation_provider.dart';
import 'package:language_app/core/providers/vocabulary_provider.dart';
import 'package:language_app/core/providers/learning_progress_provider.dart';
import 'package:provider/provider.dart';
import 'package:language_app/core/providers/theme_provider.dart';
import 'package:language_app/core/data/repository.dart';
import 'package:language_app/app/app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Core Providers
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Audio Provider - centralized TTS management
        ChangeNotifierProvider(create: (_) => AudioProvider()),

        // Repository - data layer
        Provider<ILearningRepository>(
          create: (_) => MockLearningRepository(),
        ),

        // Learning Progress Provider - depends on repository
        ChangeNotifierProxyProvider<ILearningRepository,
            LearningProgressProvider>(
          create: (context) => LearningProgressProvider(
            context.read<ILearningRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? LearningProgressProvider(repository),
        ),

        // Conversation Provider - manages conversation state
        ChangeNotifierProvider(create: (_) => ConversationProvider()),

        // Vocabulary Provider - manages vocabulary quiz state
        ChangeNotifierProvider(create: (_) => VocabularyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
