import 'dart:io';

enum VersionPart { major, minor, patch, build }

void main(List<String> args) {
  final parsedArgs = _parseArgs(args);
  if (parsedArgs.showHelp) {
    _printUsage();
    exit(0);
  }

  final part = parsedArgs.part;
  final pubspec = File('pubspec.yaml');

  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml not found in current directory.');
    exit(1);
  }

  final content = pubspec.readAsStringSync();
  final versionRegex = RegExp(
    r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
    multiLine: true,
  );
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    stderr.writeln(
      'Could not parse version in pubspec.yaml. Expected format: version: x.y.z+n',
    );
    exit(1);
  }

  final major = int.parse(match.group(1)!);
  final minor = int.parse(match.group(2)!);
  final patch = int.parse(match.group(3)!);
  final build = int.parse(match.group(4)!);

  final next = _bumpVersion(
    major: major,
    minor: minor,
    patch: patch,
    build: build,
    part: part,
  );

  final nextVersion =
      'version: ${next.major}.${next.minor}.${next.patch}+${next.build}';
  final updated = content.replaceFirst(versionRegex, nextVersion);
  pubspec.writeAsStringSync(updated);

  stdout.writeln(
    'Updated version: $major.$minor.$patch+$build -> ${next.major}.${next.minor}.${next.patch}+${next.build}',
  );
}

({VersionPart part, bool showHelp}) _parseArgs(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    return (part: VersionPart.patch, showHelp: true);
  }

  var part = VersionPart.patch;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--part') {
      if (i + 1 >= args.length) {
        stderr.writeln('Missing value for --part.');
        _printUsage();
        exit(1);
      }
      part = _parsePart(args[i + 1]);
      i++;
      continue;
    }

    if (arg.startsWith('--part=')) {
      final value = arg.substring('--part='.length);
      part = _parsePart(value);
      continue;
    }

    stderr.writeln('Unknown argument: $arg');
    _printUsage();
    exit(1);
  }

  return (part: part, showHelp: false);
}

VersionPart _parsePart(String value) {
  switch (value) {
    case 'major':
      return VersionPart.major;
    case 'minor':
      return VersionPart.minor;
    case 'patch':
      return VersionPart.patch;
    case 'build':
      return VersionPart.build;
    default:
      stderr.writeln('Invalid --part value: $value');
      _printUsage();
      exit(1);
  }
}

({int major, int minor, int patch, int build}) _bumpVersion({
  required int major,
  required int minor,
  required int patch,
  required int build,
  required VersionPart part,
}) {
  switch (part) {
    case VersionPart.major:
      return (major: major + 1, minor: 0, patch: 0, build: build + 1);
    case VersionPart.minor:
      return (major: major, minor: minor + 1, patch: 0, build: build + 1);
    case VersionPart.patch:
      return (major: major, minor: minor, patch: patch + 1, build: build + 1);
    case VersionPart.build:
      return (major: major, minor: minor, patch: patch, build: build + 1);
  }
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tools/bump_version.dart [--part major|minor|patch|build]',
  );
  stdout.writeln('Default part: patch');
}
