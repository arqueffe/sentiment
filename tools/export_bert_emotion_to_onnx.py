from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import onnx
import torch
from transformers import AutoModelForSequenceClassification, AutoTokenizer


class ExportWrapper(torch.nn.Module):
    def __init__(self, model: Any) -> None:
        super().__init__()
        self.model = model

    def forward(
        self,
        input_ids: torch.Tensor,
        attention_mask: torch.Tensor,
        token_type_ids: torch.Tensor,
    ) -> torch.Tensor:
        try:
            outputs = self.model(
                input_ids=input_ids,
                attention_mask=attention_mask,
                token_type_ids=token_type_ids,
            )
        except TypeError:
            outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
        return outputs.logits


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export Hugging Face BERT emotion model to ONNX.",
    )
    parser.add_argument(
        "--model-dir",
        type=Path,
        default=Path("bert-emotion"),
        help="Directory containing HF model files.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("assets/models/bert-emotion.onnx"),
        help="Output ONNX file path.",
    )
    parser.add_argument(
        "--opset",
        type=int,
        default=17,
        help="ONNX opset version.",
    )
    parser.add_argument(
        "--max-length",
        type=int,
        default=512,
        help="Max sequence length used for export sample inputs.",
    )
    parser.add_argument(
        "--allow-download",
        action="store_true",
        help="Allow Hugging Face download if files are missing locally.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Run ONNX checker after export.",
    )
    return parser.parse_args()


def load_model_assets(model_dir: Path, local_only: bool):
    tokenizer = AutoTokenizer.from_pretrained(
        model_dir.as_posix(),
        local_files_only=local_only,
    )
    model = AutoModelForSequenceClassification.from_pretrained(
        model_dir.as_posix(),
        local_files_only=local_only,
    )
    model.eval()
    return tokenizer, model


def build_dummy_inputs(tokenizer, max_length: int):
    encoded = tokenizer(
        "I feel calm and hopeful about today.",
        return_tensors="pt",
        truncation=True,
        padding="max_length",
        max_length=max_length,
    )
    input_ids = encoded["input_ids"]
    attention_mask = encoded["attention_mask"]
    token_type_ids = encoded.get("token_type_ids")
    if token_type_ids is None:
        token_type_ids = torch.zeros_like(input_ids)
    return input_ids, attention_mask, token_type_ids


def export_to_onnx(
    model: AutoModelForSequenceClassification,
    output_path: Path,
    input_ids: torch.Tensor,
    attention_mask: torch.Tensor,
    token_type_ids: torch.Tensor,
    opset: int,
) -> None:
    wrapper = ExportWrapper(model)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        torch.onnx.export(
            wrapper,
            (input_ids, attention_mask, token_type_ids),
            output_path.as_posix(),
            input_names=["input_ids", "attention_mask", "token_type_ids"],
            output_names=["logits"],
            dynamic_axes={
                "input_ids": {0: "batch", 1: "sequence"},
                "attention_mask": {0: "batch", 1: "sequence"},
                "token_type_ids": {0: "batch", 1: "sequence"},
                "logits": {0: "batch"},
            },
            opset_version=opset,
            do_constant_folding=True,
        )
    except ModuleNotFoundError as error:
        if error.name == "onnxscript":
            raise RuntimeError(
                "Missing dependency 'onnxscript'. "
                "Install exporter dependencies with: "
                "pip install -r tools/requirements-onnx-export.txt"
            ) from error
        raise


def maybe_check_onnx(output_path: Path) -> None:
    model = onnx.load(output_path.as_posix())
    onnx.checker.check_model(model)


def print_label_order(model_dir: Path) -> None:
    config_path = model_dir / "config.json"
    if not config_path.exists():
        return
    config = json.loads(config_path.read_text(encoding="utf-8"))
    id2label = config.get("id2label", {})
    ordered = [id2label[key] for key in sorted(id2label.keys(), key=int)]
    if not ordered:
        return
    print("Label order from config:")
    for idx, label in enumerate(ordered):
        print(f"  {idx}: {label}")


def main() -> None:
    args = parse_args()
    model_dir: Path = args.model_dir
    output_path: Path = args.output

    tokenizer, model = load_model_assets(
        model_dir=model_dir,
        local_only=not args.allow_download,
    )
    input_ids, attention_mask, token_type_ids = build_dummy_inputs(
        tokenizer=tokenizer,
        max_length=args.max_length,
    )

    export_to_onnx(
        model=model,
        output_path=output_path,
        input_ids=input_ids,
        attention_mask=attention_mask,
        token_type_ids=token_type_ids,
        opset=args.opset,
    )

    if args.check:
        maybe_check_onnx(output_path)

    print(f"ONNX export complete: {output_path.as_posix()}")
    print_label_order(model_dir)


if __name__ == "__main__":
    main()
