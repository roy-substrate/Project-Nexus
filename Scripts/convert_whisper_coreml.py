#!/usr/bin/env python3
"""
Project Nexus — Whisper-Tiny Encoder CoreML Conversion

Converts the encoder portion of OpenAI's Whisper-tiny model to CoreML
for on-device inference in the iOS app.

Usage:
  pip install openai-whisper coremltools torch numpy
  python convert_whisper_coreml.py --output ./models
"""

import argparse
import numpy as np
from pathlib import Path


def convert_whisper_encoder():
    """Convert Whisper-tiny encoder to CoreML."""
    try:
        import torch
        import whisper
        import coremltools as ct
    except ImportError as e:
        print(f"Missing dependency: {e}")
        print("Install: pip install openai-whisper coremltools torch")
        return

    print("Loading Whisper-tiny model...")
    model = whisper.load_model("tiny.en")

    print("Extracting encoder...")
    encoder = model.encoder

    class WhisperEncoderWrapper(torch.nn.Module):
        def __init__(self, encoder):
            super().__init__()
            self.encoder = encoder

        def forward(self, mel):
            return self.encoder(mel)

    wrapper = WhisperEncoderWrapper(encoder)
    wrapper.eval()

    # Whisper-tiny expects: [batch, 80, 3000] mel spectrogram
    dummy_input = torch.randn(1, 80, 3000)

    print("Tracing model...")
    traced = torch.jit.trace(wrapper, dummy_input)

    print("Converting to CoreML...")
    mlmodel = ct.convert(
        traced,
        inputs=[
            ct.TensorType(
                name="mel_spectrogram",
                shape=(1, 80, 3000),
                dtype=np.float32
            )
        ],
        outputs=[
            ct.TensorType(name="encoder_output")
        ],
        compute_units=ct.ComputeUnit.ALL,
        minimum_deployment_target=ct.target.iOS16
    )

    mlmodel.author = "Project Nexus"
    mlmodel.short_description = "Whisper-tiny encoder for adversarial perturbation scoring"
    mlmodel.version = "1.0"

    return mlmodel


def main():
    parser = argparse.ArgumentParser(description="Convert Whisper encoder to CoreML")
    parser.add_argument("--output", type=str, default="./models", help="Output directory")
    args = parser.parse_args()

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    mlmodel = convert_whisper_encoder()
    if mlmodel is None:
        return

    output_path = output_dir / "WhisperTinyEncoder.mlpackage"
    print(f"Saving to {output_path}...")
    mlmodel.save(str(output_path))
    print(f"Done. Model saved to {output_path}")
    print("To use in Xcode: drag the .mlpackage into your project. Xcode will compile it to .mlmodelc.")


if __name__ == "__main__":
    main()
