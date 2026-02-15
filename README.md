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

