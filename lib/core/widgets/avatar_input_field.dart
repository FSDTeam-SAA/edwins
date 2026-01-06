import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:language_app/app/constants/app_constants.dart';

class AvatarInputField extends StatefulWidget {
  const AvatarInputField({super.key});

  @override
  State<AvatarInputField> createState() => _AvatarInputFieldState();
}

enum _RecordState {
  idle,
  holding,
  locked,
  cancelled,
}

class _AvatarInputFieldState extends State<AvatarInputField> {
  final TextEditingController _controller = TextEditingController();

  DateTime? _listeningStartedAt;
  Duration _currentDuration = Duration.zero;
  Timer? _durationTimer;

  String get _durationString {
    final totalSeconds = _currentDuration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  late stt.SpeechToText _speech;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: true, // wichtig für Logs
      );
      debugPrint('Speech available: $_speechAvailable');
      debugPrint('Has permission: ${_speech.hasPermission}');
      setState(() {});
    } catch (e, st) {
      debugPrint('Speech init failed: $e');
      debugPrint('$st');
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('STT status: $status, isListening: ${_speech.isListening}');
  }

  void _onSpeechError(stt.SpeechRecognitionError error) {
    debugPrint('STT error: ${error.errorMsg}, permanent: ${error.permanent}');
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      debugPrint('Speech not available, aborting listen');
      return;
    }

    debugPrint('Starting listen...');
    _listeningStartedAt = DateTime.now();
    _currentDuration = Duration.zero;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _listeningStartedAt == null) return;
      setState(() {
        _currentDuration = DateTime.now().difference(_listeningStartedAt!);
      });
    });

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        autoPunctuation: true,
      ),
    );

    debugPrint('Listen called, isListening: ${_speech.isListening}');
  }

  Future<void> _stopListening() async {
    print("Stop Listening");
    _durationTimer?.cancel();
    _durationTimer = null;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> _cancelListening() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _currentDuration = Duration.zero;
    _listeningStartedAt = null;

    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    // Erkannten Text ins TextField schreiben
    print("Result");
    print(result.recognizedWords);
    setState(() {
      _controller.text = result.recognizedWords;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  _RecordState _recordState = _RecordState.idle;

  Offset? _longPressStartPosition;
  double _dragDx = 0;
  double _dragDy = 0;

  // Tresholds für Gesten
  static const double _lockThreshold = -120; // nach oben
  static const double _cancelThreshold = -80; // nach links

  @override
  void dispose() {
    _durationTimer?.cancel();
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _recordState = _RecordState.holding;
      _longPressStartPosition = details.globalPosition;
      _dragDx = 0;
      _dragDy = 0;
    });
    _startListening();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_recordState != _RecordState.holding) return;
    if (_longPressStartPosition == null) return;

    final current = details.globalPosition;
    _dragDx = current.dx - _longPressStartPosition!.dx;
    _dragDy = current.dy - _longPressStartPosition!.dy;

    // Nach oben ziehen → locken
    if (_dragDy < _lockThreshold) {
      setState(() {
        _recordState = _RecordState.locked;
      });
      // TODO: "recording locked" – Finger kann losgelassen werden
      return;
    }

    // Nach links ziehen → abbrechen
    if (_dragDx < _cancelThreshold) {
      _cancelListening();
      setState(() {
        _recordState = _RecordState.cancelled;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _recordState = _RecordState.idle;
          _dragDx = 0;
          _dragDy = 0;
        });
      });
      return;
    }

    setState(() {}); // für Animation (z.B. Slide der Hints)
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    print("Stop Long");
    // Wenn locked: Finger loslassen ignorieren, Aufnahme läuft weiter
    if (_recordState == _RecordState.locked) {
      return;
    }

    // Wenn noch im holding-State und weder gelockt noch cancelled:
    if (_recordState == _RecordState.holding) {
      _stopListening();
    }

    setState(() {
      _recordState = _RecordState.idle;
      _dragDx = 0;
      _dragDy = 0;
      _longPressStartPosition = null;
    });
  }

  void _stopLockedRecording() {
    print("Stop Locked");
    _stopListening();
    setState(() {
      _recordState = _RecordState.idle;
      _dragDx = 0;
      _dragDy = 0;
    });
  }

  bool get _isRecording =>
      _recordState == _RecordState.holding ||
      _recordState == _RecordState.locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 34 : 18,
          left: 12,
          right: 12,
          top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(2, 2),
            blurRadius: 4,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Inhalt (TextField / Recording UI)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _recordState != _RecordState.idle
                        ? _buildRecordingHint()
                        : Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: TextField(
                              enableSuggestions: false,
                              autocorrect: false,
                              keyboardAppearance: Brightness.light,
                              keyboardType: TextInputType.text,
                              cursorColor: Colors.red,
                              key: const ValueKey('textField'),
                              controller: _controller,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: AppConstants.messageHint,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButton()
              ],
            ),
          ),

          // Lock-Symbol (rechts oben, fährt mit Animation rein)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _recordState == _RecordState.holding ? 1.0 : 0.0,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Transform.translate(
                    offset: Offset(0, (_dragDy.clamp(-180, -50))),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 18),
                        SizedBox(width: 4),
                        Text(
                          AppConstants.slideToLock,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingHint() {
    return SizedBox(
      key: const ValueKey('recordingHint'),
      height: 48,
      child: Stack(
        clipBehavior: Clip.hardEdge, // alles außerhalb wird abgeschnitten
        children: [
          // 1) Cancel-Hint (liegt "unten", wird vom Mic-Container überdeckt)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _recordState == _RecordState.holding ? 1.0 : 0.0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: Offset(
                  _dragDx.clamp(-80, 0), // nach links ziehen
                  0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppConstants.slideToCancel,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              color: Colors.white,
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4),
                  const PulsingMic(size: 26, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    _durationString,
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final bool isWriting = _controller.text.isNotEmpty;
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: isWriting ? _buildSendButton() : _buildMicButton());
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade400),
        child: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Icon(
            Icons.send,
            key: ValueKey('stopIcon'),
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    final bool isLocked = _recordState == _RecordState.locked;
    final bool isHolding = _recordState == _RecordState.holding;

    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      onTap: isLocked ? _stopLockedRecording : null,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLocked || isHolding
              ? Colors.red.shade400
              : Colors.grey.shade200,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: isLocked
              ? const Icon(
                  Icons.stop,
                  key: ValueKey('stopIcon'),
                  size: 22,
                  color: Colors.white,
                )
              : const Icon(
                  Icons.mic,
                  key: ValueKey('micIcon'),
                  size: 22,
                  color: Colors.black87,
                ),
        ),
      ),
    );
  }
}

class PulsingMic extends StatefulWidget {
  const PulsingMic({super.key, this.size = 26, this.color = Colors.red});

  final double size;
  final Color color;

  @override
  State<PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<PulsingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.95,
      upperBound: 1.15,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Icon(
        Icons.mic,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
