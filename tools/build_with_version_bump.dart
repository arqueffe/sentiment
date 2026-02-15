import 'dart:io';

void main(List<String> args) {
  final showHelp = args.contains('--help') || args.contains('-h');
  if (showHelp) {
    _printUsage();
    return;
  }

  var part = 'patch';
  final flutterArgs = <String>[];

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--part') {
      if (i + 1 >= args.length) {
        stderr.writeln('Missing value for --part.');
        _printUsage();
        exit(1);
      }
      part = args[++i];
      continue;
    }

    if (arg.startsWith('--part=')) {
      part = arg.substring('--part='.length);
      continue;
    }

    flutterArgs.add(arg);
  }

  final bumpResult = Process.runSync('dart', [
    'run',
    'tools/bump_version.dart',
    '--part',
    part,
  ], runInShell: true);

  stdout.write(bumpResult.stdout);
  stderr.write(bumpResult.stderr);
  if (bumpResult.exitCode != 0) {
    exit(bumpResult.exitCode);
  }

  final effectiveFlutterArgs = flutterArgs.isEmpty
      ? ['build', 'apk']
      : flutterArgs;

  final flutterExecutable = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final buildResult = Process.runSync(
    flutterExecutable,
    effectiveFlutterArgs,
    runInShell: true,
  );

  stdout.write(buildResult.stdout);
  stderr.write(buildResult.stderr);
  exit(buildResult.exitCode);
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tools/build_with_version_bump.dart [--part major|minor|patch|build] [flutter build args]',
  );
  stdout.writeln('Examples:');
  stdout.writeln(
    '  dart run tools/build_with_version_bump.dart --part patch build apk --release',
  );
  stdout.writeln(
    '  dart run tools/build_with_version_bump.dart --part build build appbundle',
  );
  stdout.writeln('Default build command when omitted: flutter build apk');
}
