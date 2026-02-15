# sentiment

A simple Android app that analyzes your journal entries and highlights emotional trends, because tracking patterns can give you insights you might otherwise miss.

## On-device BERT emotion model

The app now integrates on-device sentence emotion inference through `flutter_onnxruntime`.

Required model file for runtime:

- Export your Hugging Face safetensors model to ONNX and place it at `assets/models/bert-emotion.onnx`.

Bundled assets currently expected by the app:

- `assets/models/bert-emotion.onnx` (required at runtime)
- `bert-emotion/vocab.txt`
- `bert-emotion/config.json`
- `bert-emotion/tokenizer_config.json`
- `bert-emotion/special_tokens_map.json`

Without `assets/models/bert-emotion.onnx`, the app still runs, but sentence classification falls back to neutral.

### Export ONNX locally (not committed)

Install exporter dependencies once:

```bash
pip install -r tools/requirements-onnx-export.txt
```

Generate ONNX in one command:

```bash
python tools/export_bert_emotion_to_onnx.py --model-dir bert-emotion --output assets/models/bert-emotion.onnx --check
```

This writes `assets/models/bert-emotion.onnx` with input names:

- `input_ids`
- `attention_mask`
- `token_type_ids`

and output name:

- `logits`

## Versioning workflow

The app version shown in Settings comes from the installed package metadata (`pubspec.yaml` version).

To automatically increment it without manual edits, use:

```bash
dart run tools/bump_version.dart
```

Default behavior bumps `patch` and `build`:

- `1.0.0+1` -> `1.0.1+2`

You can also bump a specific part:

```bash
dart run tools/bump_version.dart --part major
dart run tools/bump_version.dart --part minor
dart run tools/bump_version.dart --part patch
dart run tools/bump_version.dart --part build
```

Recommended release flow:

1. Build with automatic bump:

	```bash
	dart run tools/build_with_version_bump.dart --part patch build apk --release
	```

2. Commit the updated `pubspec.yaml`

## Release automation (GitHub Actions)

Two manual workflows are included:

- `.github/workflows/play-private-release.yml`
	- Bumps version automatically
	- Commits updated `pubspec.yaml`
	- Builds signed Android App Bundle (`.aab`)
	- Uploads to Google Play (internal/alpha/beta/production track)

- `.github/workflows/github-public-split-abi-release.yml`
	- Bumps version automatically
	- Commits updated `pubspec.yaml`
	- Builds signed split-ABI APKs
	- Creates Git tag + GitHub Release and uploads APK assets

### Required repository secrets

Set these in GitHub repository settings (`Settings` -> `Secrets and variables` -> `Actions`):

- `ANDROID_KEYSTORE_BASE64`: base64 content of your upload keystore file
- `ANDROID_KEYSTORE_PASSWORD`: keystore password
- `ANDROID_KEY_ALIAS`: key alias
- `ANDROID_KEY_PASSWORD`: key password
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: full JSON for Play Console service account (only needed for Play workflow)

### Local signing file format

The Android release build now uses `android/key.properties` when present:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=app/upload-keystore.jks
```

In CI, this file and the keystore are generated automatically from secrets.

