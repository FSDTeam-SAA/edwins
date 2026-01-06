import 'package:flutter/material.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:language_app/core/widgets/message_bubble.dart';
import 'package:language_app/core/utils/viseme_helper.dart';
import 'package:language_app/core/widgets/avatar_input_field.dart';
import 'package:language_app/app/constants/app_constants.dart';

class AvatarTestPage extends StatefulWidget {
  const AvatarTestPage({super.key});

  @override
  State<AvatarTestPage> createState() => _AvatarTestPageState();
}

class _AvatarTestPageState extends State<AvatarTestPage> {
  late final AvatarController _controller;
  final _visemeHelper = VisemeHelper();

  late List<Map<String, dynamic>> visemes;

  @override
  void initState() {
    super.initState();
    _controller = AvatarController();
    _loadTestVisemes();
  }

  void _loadTestVisemes() async {
    visemes = await _visemeHelper.loadVisemesFromAsset(AppConstants.visemePath);
    messages.add(
      Message(
        text:
            "Hallo! Ich freue mich darauf, heute mit dir zu üben. Was ist dein Lieblingsort zum Essen?",
        isUser: false,
        highlightedWords: ["freue", "Essen"],
        timeStamp: '19:40',
        audioPath: AppConstants.russianSampleAudio,
        visemes: visemes,
        translation:
            "Hello! I'm excited to practice with you today. What's your favorite place to eat?",
        highlightedWordsTranslation: ["excited", "eat"],
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller.disposeView();
    super.dispose();
  }

  List<Message> messages = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                AvatarView(
                  avatarName: AppConstants.avatarKarl,
                  controller: _controller,
                  height: 400,
                  backgroundImagePath: AppConstants.backgroundImage,
                  borderRadius: 0,
                ),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF35C759).withOpacity(0.3),
                    border: const Border(
                      left: BorderSide(
                        color: Color(0xFF35C759),
                        width: 6,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        90, // Platz für das Input-Feld lassen
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final maxBubbleWidth =
                            MediaQuery.of(context).size.width * 0.7;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: msg.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: maxBubbleWidth),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      offset: const Offset(2, 2),
                                      blurRadius: 3,
                                      spreadRadius: 1,
                                    )
                                  ],
                                  color: msg.isUser
                                      ? Colors.blue.shade100
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: msg.isUser
                                        ? const Radius.circular(12)
                                        : const Radius.circular(0),
                                    bottomRight: msg.isUser
                                        ? const Radius.circular(0)
                                        : const Radius.circular(12),
                                  ),
                                ),
                                child: MessageBubble(
                                  message: msg,
                                  avatarController: _controller,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? -30
                  : 0, // NICHT viewInsets.bottom!
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: const AvatarInputField(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
