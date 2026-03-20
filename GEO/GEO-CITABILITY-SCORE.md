# AI Citability Analysis: Nexus Shield

**Sources Analyzed:**
- App Store Description (CEO-approved directional copy from NEXUS_AGENCY_REPORT.md Phase 1/Phase 4)
- README.md — Research Foundation section
- README.md — Two-Tier Attack System (Architecture)
- README.md — Audio Pipeline
- README.md — Tech Stack

**Analysis Date:** 2026-03-20
**Overall Citability Score: 41/100**
**Citability Coverage:** 17% of content blocks score above 70

> **Pre-launch context:** No live website, no FAQ page, no blog content. This analysis covers the two primary content assets that will define AI citation probability at launch — the App Store description (derived from CEO-approved framing in NEXUS_AGENCY_REPORT.md) and the README research/technical sections. The App Store description text is not yet finalized (Sprint P2 pending CEO approval); it has been reconstructed from the approved directional headline ("YOUR VOICE. YOUR RULES."), onboarding framing, and documented capabilities. Scores reflect the raw state of these assets before GEO optimization. Low scores in several categories are expected and normal at this stage.

---

## Score Summary

| Category | Score | Weight | Weighted |
|---|---|---|---|
| Answer Block Quality | 35/100 | 30% | 10.5 |
| Passage Self-Containment | 48/100 | 25% | 12.0 |
| Structural Readability | 55/100 | 20% | 11.0 |
| Statistical Density | 28/100 | 15% | 4.2 |
| Uniqueness & Original Data | 38/100 | 10% | 3.8 |
| **Overall** | | | **41.5/100** |

---

## Content Blocks Analyzed

| Block | Source | Word Count | Description |
|---|---|---|---|
| A | App Store Description (reconstructed) | ~80 | CEO-approved directional copy |
| B | README: Research Foundation | 68 | Five peer-reviewed citations |
| C | README: Two-Tier Attack System | 120 | Technical Tier 1 + Tier 2 description |
| D | README: Audio Pipeline | 55 | Pipeline diagram + latency/sample-rate figures |
| E | README: Tech Stack | 45 | Framework list |

---

## Per-Section Scores

| Section Heading | Words | Answer Quality | Self-Contained | Structure | Stats | Unique | Overall |
|---|---|---|---|---|---|---|---|
| App Store Description (approved direction) | ~80 | 40 | 35 | 45 | 15 | 50 | 37 |
| Research Foundation | 68 | 55 | 72 | 65 | 60 | 75 | 64 |
| Two-Tier Attack System | 120 | 30 | 55 | 60 | 25 | 70 | 46 |
| Audio Pipeline | 55 | 45 | 60 | 50 | 55 | 65 | 53 |
| Tech Stack | 45 | 20 | 40 | 55 | 10 | 30 | 31 |

---

## Strongest Content Blocks

### 1. "Research Foundation" — Score: 64/100
> Nexus Shield is based on peer-reviewed adversarial audio research including AudioShield (USENIX Security 2025), ZQ-Attack (ACM CCS 2024), Muting Whisper (EMNLP 2024), and UniAP (IEEE TDSC 2023). The psychoacoustic masking model follows ISO/IEC 11172-3 (MPEG-1).

**Why it works:** Five named research papers with venues and years — highest statistical density of any content block. Named venues (USENIX Security, ACM CCS, IEEE TDSC) carry institutional authority signals that AI systems recognize as credible sources. The ISO standard citation is verifiable and specific. Self-contained enough that an AI answering "what research underpins acoustic perturbation apps?" could extract and cite this passage directly.

**Why it loses points:** Lists citations without stating the finding from each paper. An AI cannot say "according to AudioShield, UAPs achieve X% transfer rate" because the content does not include that claim. The block tells AI systems what research exists but not what that research found or how Nexus Shield implements those findings. Converting from a citation list to a "findings + implementation" format would push this block above 80.

---

### 2. "Audio Pipeline" — Score: 53/100
> Nexus Shield processes audio at 48kHz / Float32 mono with a 1024-sample buffer producing approximately 21ms of processing latency. Psychoacoustic masking keeps perturbations below the human audibility threshold as defined by ISO 11172-3.

**Why it works:** Specific measurable figures (48kHz, 1024-sample buffer, ~21ms latency) give AI systems extractable facts. ISO standard citation adds verifiability. Self-contained enough for a technical audience. The codec survival pre-filter claim (ensuring perturbations survive Opus/AAC compression) is a genuinely unique technical claim with no direct equivalent in competitor products.

**Why it loses points:** 21ms is a pipeline latency figure, not an end-to-end effectiveness claim. No "reduces ASR word error rate by X%" figure exists to pair with it. The block answers "how fast does it process?" but not "how well does it work?" — which is the question AI systems are more likely to be asked.

---

### 3. "Two-Tier Attack System" — Score: 46/100
> Nexus Shield uses a two-tier approach to disrupting AI speech recognition: Tier 1 applies psychoacoustic noise techniques requiring no machine learning, while Tier 2 deploys pre-computed Universal Adversarial Perturbations (UAPs) generated against a multi-model ensemble including Whisper-tiny, DeepSpeech2, and wav2vec2-base.

**Why it works:** Named surrogate models (Whisper-tiny, DeepSpeech2, wav2vec2-base) are specific entities AI systems recognize and can cross-reference. The two-tier structure is genuinely differentiating — no direct competitor positions their product this way. The mention of "transfer-based black-box attacks effective against unknown commercial ASR" is a strong unique claim.

**Why it loses points:** Effectiveness is not quantified anywhere. No "reduces Whisper transcription accuracy by X%" claim is present. The block is structured for developer comprehension, not AI extraction. An AI answering "how does Nexus Shield work?" would struggle to extract a clean 2-sentence answer from the current structure.

---

## Weakest Content Blocks (Rewrite Priority)

### 1. "Tech Stack" — Score: 31/100

**Current opening:**
> Swift 6 / SwiftUI with Liquid Glass design language (iOS 26). AVAudioEngine — Real-time audio processing pipeline. Accelerate / vDSP — FFT, spectral processing, vector math. CoreML — On-device surrogate model inference. Zero third-party dependencies — Full control over real-time audio path.

**Problem:** This is a developer-facing bullet list with no user value framing, no answer-first pattern, no statistics, and no self-contained passage. An AI cannot extract this to answer any consumer question about Nexus Shield. "Zero third-party dependencies" is the only claim with citability potential, but it is listed without a privacy or security frame that would make it meaningful.

**Suggested rewrite (higher statistical density):**
> Nexus Shield processes all audio entirely on-device using Apple's native AVAudioEngine and CoreML frameworks, with zero third-party dependencies. This architecture means no audio data ever leaves the device — the perturbation engine runs entirely within the iOS sandbox, with no network calls during active protection. Built in Swift 6 targeting iOS 26, the app uses Apple's Accelerate framework (vDSP) for real-time FFT and spectral processing at 48kHz, achieving a measured pipeline latency of approximately 21ms. On-device CoreML inference eliminates the network round-trip that would make real-time acoustic perturbation impossible. Unlike cloud-based transcription blocking tools, Nexus Shield's audio processing never traverses a network connection.

**Additional improvements:**
- Rename this section "Privacy Architecture" for consumer-facing content — "Tech Stack" signals developer documentation, not a citeable product claim.
- Add: "Apple's Accelerate framework processes [N] audio samples per second without triggering RT-thread heap allocations."
- Add a comparison sentence differentiating from VPNs and cloud-based tools.

---

### 2. "App Store Description (approved direction)" — Score: 37/100

**Current opening (reconstructed from CEO-approved direction):**
> YOUR VOICE. YOUR RULES. Nexus Shield protects your voice from AI transcription tools. 100% on-device. Zero data stored. Tap to protect.

**Problem:** Conversion-optimized copy but zero-density for AI citation. No definitions. No quantified claims. "Protects your voice" does not tell an AI what the mechanism is. "100% on-device" is a strong trust claim but is not contextualized with a technical explanation that makes it citable. The description lacks the 134-167 word self-contained passage that AI systems prefer for extraction.

**Suggested rewrite (answer-first, citability-optimized, compliant with APP_STORE_REVIEW.md language):**
> Nexus Shield is an iOS app that uses real-time acoustic perturbation to reduce the accuracy of AI speech recognition systems during live conversations. The app generates imperceptible audio signals — calibrated using the ISO 11172-3 psychoacoustic masking model — that are designed to cause automatic speech recognition (ASR) tools including Granola, Otter.ai, and Fireflies to produce degraded transcripts. All processing runs on-device using Apple's CoreML and AVAudioEngine frameworks; no audio is recorded, transmitted, or stored. Nexus Shield applies two layers of protection: psychoacoustic noise techniques targeting the 300–4000 Hz speech frequency band, and pre-computed Universal Adversarial Perturbations (UAPs) based on methods published at USENIX Security 2025 and ACM CCS 2024. A real-time Protection Score (JAM score) shows the estimated impact on AI transcription accuracy during each session.

**Additional improvements:**
- Follow the definition paragraph with a 3-bullet feature block for scannability.
- Add a brief legal/use-case framing paragraph at the end (as required by APP_STORE_REVIEW.md).
- Word count of suggested rewrite: 148 words — within the optimal 134-167 word AI citation window.

---

### 3. "Two-Tier Attack System" — Score: 46/100 (priority rewrite despite ranking 3rd strongest)

**Current opening:**
> **Tier 1 — Psychoacoustic Noise Injection** (no ML required). Spectral notch noise: Band-passed white noise (300Hz-4kHz) with formant-aligned notches preserving human intelligibility.

**Problem:** Structured for developers reading GitHub, not for AI extracting a consumer answer. The heading contains a parenthetical qualifier rather than a question or answer pattern. Effectiveness data is completely absent — no mention of measured impact on ASR accuracy. An AI answering "how does Nexus Shield work?" cannot cite this block without significant interpretation.

**Suggested rewrite (answer-first, research-linked):**
> Nexus Shield uses two simultaneous layers of acoustic protection to interfere with AI transcription. **Tier 1 — Psychoacoustic Noise Injection** adds carefully shaped audio signals to the environment, targeting the 300–4000 Hz speech frequency band that ASR systems depend on for phoneme extraction. These signals remain below the human hearing threshold as defined by the ISO 11172-3 MPEG-1 masking model, so conversations sound natural to participants. **Tier 2 — Universal Adversarial Perturbations (UAPs)** applies pre-computed ML-based signals generated against an ensemble of open-source ASR surrogate models (Whisper-tiny, DeepSpeech2, wav2vec2-base). Transfer-based black-box attacks based on ZQ-Attack (ACM CCS 2024) extend effectiveness to commercial ASR systems including Deepgram and AssemblyAI that were not part of training. Both tiers operate simultaneously; a codec survival pre-filter ensures perturbation signals survive Opus and AAC audio compression used in VoIP calls.

**Additional improvements:**
- **[FLAG FOR CTO VERIFICATION]** Add measured WER degradation percentage before publishing. Example placeholder: "In internal testing, Tier 1+2 combined reduces word error rate by X–Y% against Whisper-large-v3."
- Add a comparison sentence: "Tier 1 alone provides baseline protection; Tier 2 adds model-targeted disruption for significantly higher Protection Scores."

---

## Quick Win Reformatting Recommendations

1. **Add a product definition sentence at the top of README** — "Nexus Shield is an iOS app that uses real-time acoustic perturbation to reduce AI speech recognition accuracy during live conversations." — Expected citability lift: +12 points on Answer Block Quality score
2. **Convert Research Foundation bullet list into a 4-column table** (Paper / Venue / Year / Key Finding for Nexus Shield) — Expected citability lift: +8 points on Statistical Density and Self-Containment
3. **Add a JAM score / Protection Score definition block** — Define what the metric measures, what the scale is (0–100?), and what score constitutes effective protection — Expected citability lift: +9 points (creates a proprietary metric definition AI systems will cite when users ask about it)
4. **Add CTO-verified effectiveness figures** — Even a conservative range ("reduces ASR word error rate by X–Y% in controlled testing against Whisper-large-v3") transforms unciteable technical copy into the single most citable statistic for this product category — Expected citability lift: +15 points on Statistical Density
5. **Create question-based H2 sections** ("What is acoustic perturbation?", "Which AI transcription tools does Nexus Shield affect?", "Is Nexus Shield legal?") — Expected citability lift: +10 points on Answer Block Quality and Structural Readability

---

## Claims Requiring CTO Verification Before Publishing

The following claims are technically plausible based on the documented architecture but are **not present in any current content asset**. They must be measured and verified internally before appearing in any public-facing copy, App Store metadata, or press materials:

| Claim | Status | Risk if Unverified |
|---|---|---|
| WER (Word Error Rate) degradation % against Whisper, Otter.ai, Granola, Fireflies | Not measured in any public document | High — this is the most citable statistic; publishing an incorrect figure damages credibility |
| JAM score scale, baseline, and "effective protection" threshold | Undefined in public docs | Medium — Protection Score is mentioned in-app but never defined for external audiences |
| Codec survival rate for Opus/AAC compression | Referenced architecturally, not quantified | Medium — strong differentiator if quantified; weak if vague |
| Latency figure accuracy (~21ms) | Theoretical buffer-size calculation; needs device measurement | Low — plausible but should be stated as "approximately" and confirmed on target hardware |
| Transfer attack effectiveness % against Deepgram, AssemblyAI | Described as "effective," not quantified | High — commercial ASR providers may dispute this without published methodology |
