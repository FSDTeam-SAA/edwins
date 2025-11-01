import 'dart:io';
// tool/run_ios_tests.dart

Future<int> runCmd(List<String> args) async {
  final p = await Process.start('xcodebuild', args);
  stdout.addStream(p.stdout);
  stderr.addStream(p.stderr);
  return await p.exitCode;
}

Future<void> main() async {
  final dest = "platform=iOS Simulator,name=iPhone 17";

  var code = await runCmd([
    'test',
    '-workspace',
    'ios/Runner.xcworkspace',
    '-scheme',
    'Runner',
    '-destination',
    dest,
    '-only-testing:RunnerTests',
  ]);

  if (code != 0) {
    stderr.writeln('❌ iOS model test failed');
    exit(1);
  } else {
    print('✅ iOS model test succeeded');
  }
}

// dart run tool/run_ios_tests.dart
