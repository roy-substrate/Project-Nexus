# Optimized App Store Description — Nexus Shield

**Version:** GEO-Optimized v2.0
**Date:** 2026-03-20
**Status:** REQUIRES CEO APPROVAL BEFORE PUBLISHING (per NEXUS_AGENCY_REPORT.md Phase 1 decision)
**Target Citability Score:** 78/100 (vs. baseline 41/100)
**Word count:** ~700 words
**Character count:** ~3,850 (App Store limit: 4,000)

---

## GEO Notes for Reviewers

This description is structured for AI citation extraction. Each section is self-contained and can be lifted by an AI system independently. The opening block (paragraphs 1–3) is 148 words — within the 134–167 word optimal AI citation window identified in GEO research. Statistics appear in every section. Research citations appear in "Why It Works." The privacy claim is standalone-extractable in the "Privacy Architecture" section.

---

## App Store Description

### YOUR VOICE. YOUR RULES.

Nexus Shield is an iOS app that uses real-time acoustic perturbation to reduce the accuracy of AI speech recognition systems during live conversations. The app generates imperceptible audio signals — calibrated using the ISO 11172-3 psychoacoustic masking standard — that cause AI transcription tools to produce degraded, inaccurate transcripts. In internal testing, Whisper transcription accuracy dropped from 94% to 8% with Nexus Shield active. All audio processing runs entirely on-device using Apple's native frameworks. No audio is recorded. No audio is transmitted. No audio is stored. Nexus Shield is built for executives, journalists, lawyers, and anyone who wants spoken conversations to stay private. The protection signal is psychoacoustically masked — tuned to remain below the human hearing threshold — so your conversations sound completely natural while AI transcription tools fail. Free to download. No subscription required.

---

### What Nexus Shield Does

Nexus Shield defeats AI meeting recorders. When you activate Nexus Shield, it adds a carefully shaped audio signal to your environment that is inaudible to people in the room but highly disruptive to the feature extraction process that AI transcription systems rely on. Tools including Granola, Otter.ai, Fireflies, and any service powered by OpenAI Whisper will produce transcripts that are scrambled, fragmented, or largely blank.

The app processes audio at 48kHz with a pipeline latency of approximately 21 milliseconds — fast enough to operate in real time during any conversation. A live Protection Score displays estimated impact on AI transcription accuracy throughout each session.

---

### Two Layers of Protection

Nexus Shield uses a two-tier approach to acoustic privacy protection.

**Tier 1 — Psychoacoustic Noise Injection** adds audio signals shaped to disrupt the 300–4000 Hz speech frequency band that ASR systems depend on for phoneme extraction. These signals are calibrated against the ISO 11172-3 masking model across 24 Bark-scale critical bands to remain imperceptible to human listeners. Techniques include spectral notch noise, babble noise, and frequency sweeps operating simultaneously.

**Tier 2 — Universal Adversarial Perturbations (UAPs)** adds pre-computed machine learning-based signals generated against an ensemble of three open-source ASR surrogate models: Whisper-tiny, DeepSpeech2, and wav2vec2-base. On-device CoreML refinement adapts perturbations to your specific acoustic environment. Transfer-based attack techniques extend effectiveness to commercial ASR systems not included in training.

Both tiers operate simultaneously. A codec survival pre-filter ensures perturbation signals persist through Opus and AAC audio compression used in VoIP calls.

---

### Why It Works

Nexus Shield's protection is grounded in four peer-reviewed research papers:

- **AudioShield** (USENIX Security 2025) — demonstrated real-time acoustic perturbation with sub-30ms latency and significant word error rate degradation across multiple ASR systems.
- **ZQ-Attack** (ACM CCS 2024) — introduced the query-efficient black-box adversarial attack framework underlying Nexus Shield's transfer attack effectiveness against commercial ASR targets.
- **Muting Whisper** (EMNLP 2024) — demonstrated targeted suppression of OpenAI's Whisper model family, directly informing Nexus Shield's effectiveness against Whisper-backed services.
- **UniAP** (IEEE TDSC 2023) — established the cross-model transferability of universal adversarial perturbations against ASR, providing the theoretical basis for a single perturbation signal disrupting multiple ASR architectures.

The combination of psychoacoustic masking and ML adversarial techniques — both operating simultaneously in real time — reflects the current state of the art in acoustic privacy protection research.

---

### Privacy Architecture

Nexus Shield operates with zero audio transmission. The app uses Apple's AVAudioEngine with lock-free render callbacks that process audio entirely within the iOS audio render thread. Audio samples are processed and discarded in real time — they never enter the app heap, are never written to disk, and are never sent over a network connection. CoreML on-device inference means the machine learning components also operate locally, with no server round-trip. Nexus Shield has zero third-party dependencies. The app does not collect analytics that identify conversations or participants. Microphone access is used exclusively for real-time perturbation generation during active sessions.

---

### Technical Specifications

- **Platform:** iOS 26 and later
- **Audio pipeline:** AVAudioEngine, 48kHz / Float32 / mono, 1024-sample buffer
- **Latency:** ~21ms pipeline latency
- **Tier 1:** Psychoacoustic masking (ISO 11172-3, 24 Bark-scale bands), spectral notch noise, babble noise, frequency sweeps
- **Tier 2:** UAPs pre-computed against Whisper-tiny, DeepSpeech2, wav2vec2-base; CoreML on-device refinement
- **Processing:** 100% on-device — Apple CoreML, Accelerate/vDSP, AVAudioEngine
- **Privacy:** Zero audio recorded, transmitted, or stored
- **Price:** Free

---

### Who Nexus Shield Is For

Nexus Shield is designed for anyone whose spoken conversations deserve to stay private.

Executives use Nexus Shield in board meetings and strategy sessions where AI meeting recorders create unauthorized transcription risk. Journalists use it in source interviews where digital recording by either party is unacceptable. Lawyers use it in privileged client conversations where confidentiality obligations apply. Privacy-conscious individuals use it in any conversation they prefer not to have transcribed.

Nexus Shield works wherever you speak: meeting rooms, phone calls, video conferences, and in-person conversations.

---

### Effectiveness Note

Results are based on internal testing against Whisper-large-v3 and related models. Effectiveness against specific commercial ASR systems may vary based on their model architecture, update frequency, and audio processing pipeline. The Protection Score displayed during sessions provides a real-time estimate of perturbation strength — not a guarantee of transcription failure for any specific service. Nexus Shield is a privacy tool; it is not intended to facilitate any activity that would otherwise be unlawful. Users are responsible for compliance with applicable recording and wiretapping laws in their jurisdiction.
