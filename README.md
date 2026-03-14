# Project Nexus

**ASR Jamming App** — Adversarial audio perturbation engine for speech privacy protection.

Defeats real-time transcription tools (Granola, Otter.ai, Fireflies) by injecting imperceptible adversarial perturbations into the audio environment.

## Architecture

### Two-Tier Attack System

**Tier 1 — Psychoacoustic Noise Injection** (no ML required)
- Spectral notch noise: Band-passed white noise (300Hz-4kHz) with formant-aligned notches preserving human intelligibility
- Babble noise: Multi-layer speech-like noise with randomized pitch/timing, exploiting ASR confusion with overlapping speech patterns
- Frequency sweeps: Randomized chirp signals disrupting mel-spectrogram feature extraction across multiple filter banks

**Tier 2 — ML Adversarial Perturbations**
- Pre-computed Universal Adversarial Perturbations (UAPs) generated against multi-model ensemble
- Surrogate models: Whisper-tiny, DeepSpeech2, wav2vec2-base
- Transfer-based black-box attacks effective against unknown commercial ASR (Deepgram, AssemblyAI)
- On-device refinement via CoreML encoder + CMA-ES optimization

### Audio Pipeline

```
[Mic Input] --tap--> [PsychoacousticMasker] --> masking threshold
                                                        |
                                                        v
[Tier1 Generators] + [UAP Generator] --> [Mixer] --> [Speaker Output]
                                                        |
                                                        v
                                              [Air gap / Room]
                                                        |
                                                        v
                                              [Target ASR Device]
```

- AVAudioEngine with lock-free real-time render callbacks
- 48kHz / Float32 mono / 1024-sample buffer (~21ms latency)
- Psychoacoustic masking keeps perturbations below audibility threshold (ISO 11172-3)
- Codec survival pre-filter ensures perturbations survive Opus/AAC compression

## Tech Stack

- **Swift 6** / SwiftUI with Liquid Glass design language (iOS 26)
- **AVAudioEngine** — Real-time audio processing pipeline
- **Accelerate / vDSP** — FFT, spectral processing, vector math
- **CoreML** — On-device surrogate model inference
- **Zero third-party dependencies** — Full control over real-time audio path

## Project Structure

```
ProjectNexus/
├── App/              # Entry point, AppState, Info.plist
├── Audio/
│   ├── Engine/       # AVAudioEngine pipeline, session config
│   ├── DSP/          # Tier 1: spectral notch, babble, sweep, masking, codec sim
│   ├── ML/           # Tier 2: UAP manager, surrogate ensemble, optimizer
│   └── Routing/      # Speaker playback + VoIP stub
├── UI/
│   ├── Screens/      # Main control, settings, routing, diagnostics
│   ├── Components/   # Spectrum viz, waveform, particles, glass cards
│   └── Design/       # Theme, glass modifiers
├── Models/           # Data types
├── Services/         # Perturbation orchestration, metrics
├── Resources/        # UAPs, babble corpus, ML models
└── Extensions/       # Buffer + DSP helpers
Scripts/
├── generate_uaps.py          # Offline UAP generation (PyTorch)
└── convert_whisper_coreml.py  # Model conversion to CoreML
```

## Setup

### iOS App
1. Open `ProjectNexus.xcodeproj` in Xcode 16+
2. Set deployment target to iOS 26
3. Build and run on device (audio features require physical device)

### Generate UAPs (optional)
```bash
pip install numpy scipy
python Scripts/generate_uaps.py --output ProjectNexus/Resources/UAPs/
```

### Convert Whisper Model (optional)
```bash
pip install openai-whisper coremltools torch
python Scripts/convert_whisper_coreml.py --output ProjectNexus/Resources/MLModels/
```

## Research Foundation

Based on peer-reviewed adversarial audio research:

- **AudioShield** (USENIX Security 2025) — Latent-space transferable UAPs
- **ZQ-Attack** (ACM CCS 2024) — Zero-query black-box ASR attacks
- **Muting Whisper** (EMNLP 2024) — Universal adversarial prefix attacks
- **UniAP** (IEEE TDSC 2023) — Universal non-targeted adversarial perturbations
- Psychoacoustic masking model based on ISO/IEC 11172-3 (MPEG-1)

## License

MIT
