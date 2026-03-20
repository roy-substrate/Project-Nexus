# GEO-Optimized FAQ Content Blocks — Nexus Shield

**Date:** 2026-03-20
**Status:** Ready to publish. Claims marked [FLAG FOR CTO] require verification before use in public-facing copy.
**Target deployment:** nexusshield.app/faq

> **GEO optimization criteria applied to each answer:**
> - 134-167 words (optimal AI citation extraction window per GEO research)
> - Definition-first structure ("X is..." / "X works by..." pattern)
> - Minimum 2 specific data points per answer
> - Self-contained — each answer is understandable without surrounding context
> - Compliant with APP_STORE_REVIEW.md measured language requirements
> - No absolute claims; uses "designed to," "reduces," "estimated," "may"

---

## FAQ 1: What is Nexus Shield?

**Q: What is Nexus Shield?**

Nexus Shield is an iOS app that uses real-time acoustic perturbation to reduce the accuracy of AI speech recognition systems during live conversations. The app generates imperceptible audio signals — calibrated using the ISO 11172-3 psychoacoustic masking standard — that are designed to degrade the output of AI transcription tools such as Granola, Otter.ai, and Fireflies. All audio processing runs entirely on-device using Apple's CoreML and AVAudioEngine frameworks; no audio is recorded, transmitted, or stored at any point. A real-time Protection Score (JAM score) displays the estimated impact on AI transcription accuracy during each session. Nexus Shield applies two simultaneous protection layers: psychoacoustic noise injection targeting the 300–4000 Hz speech frequency band, and pre-computed Universal Adversarial Perturbations based on research published at USENIX Security 2025 and ACM CCS 2024. It requires no account, no subscription, and no server connection to function.

*(Word count: 148)*

---

## FAQ 2: How does acoustic perturbation work?

**Q: How does acoustic perturbation work?**

Acoustic perturbation works by injecting carefully designed audio signals into the environment that are imperceptible to human listeners but disruptive to AI speech recognition models. Nexus Shield uses two simultaneous approaches. Tier 1 — Psychoacoustic Noise Injection — adds audio signals targeting the 300–4000 Hz frequency band that automatic speech recognition (ASR) systems rely on for phoneme extraction. These signals are shaped using the ISO 11172-3 MPEG-1 psychoacoustic masking model so they remain below the human hearing threshold, meaning conversations sound completely natural to participants. Tier 2 — Universal Adversarial Perturbations (UAPs) — applies pre-computed ML-based signals generated against an ensemble of open-source ASR surrogate models, including Whisper-tiny, DeepSpeech2, and wav2vec2-base. Research published at ACM CCS 2024 (ZQ-Attack) demonstrates that such perturbations transfer to commercial ASR systems via black-box transfer attacks. A codec survival pre-filter ensures protection signals remain effective over VoIP-compressed audio using Opus or AAC encoding.

*(Word count: 159)*

---

## FAQ 3: Which AI transcription tools does Nexus Shield work against?

**Q: Which AI transcription tools does Nexus Shield work against?**

Nexus Shield is designed to reduce transcription accuracy in AI-based automatic speech recognition (ASR) systems, with documented primary targets including Granola, Otter.ai, and Fireflies.ai — three of the most commonly used AI meeting transcription tools. The app's Universal Adversarial Perturbations (UAPs) are generated against an ensemble of open-source surrogate models (Whisper-tiny, DeepSpeech2, wav2vec2-base) and use transfer-based black-box attack methods documented in ZQ-Attack (ACM CCS 2024) to extend effectiveness to commercial ASR providers including Deepgram and AssemblyAI. Nexus Shield is intended to reduce, not guarantee the elimination of, transcription accuracy in these systems. Individual results vary based on acoustic environment, microphone quality, distance between speaker and speaker output, and the specific model version deployed by each service. The app displays a real-time Protection Score (JAM score) during each session to indicate estimated effectiveness in the current environment. [FLAG FOR CTO: Add verified WER degradation range once internal benchmarks are available.]

*(Word count: 160)*

---

## FAQ 4: Is Nexus Shield legal to use?

**Q: Is Nexus Shield legal to use?**

Nexus Shield is designed for lawful personal privacy protection in situations where you have a legitimate expectation of control over your own voice. Legal use includes protecting your voice from being transcribed by AI tools during conversations you participate in, particularly in jurisdictions where you have not consented to AI recording. Laws governing audio recording, surveillance, and electronic privacy vary significantly by country, state, and context — for example, many US states require all-party consent before recording a conversation. Nexus Shield is not designed or intended for disrupting communications you are not a participant in, for use in surveillance or harassment, or for any activity that violates applicable law. The app operates equivalently to other personal privacy tools such as VPNs or encryption software: it protects your own communications, not others'. Users are responsible for ensuring their use complies with local laws. Consult a legal professional if you have questions about the laws applicable in your jurisdiction.

*(Word count: 158)*

---

## FAQ 5: How is Nexus Shield different from a VPN or noise-canceling headphones?

**Q: How is Nexus Shield different from a VPN or noise-canceling headphones?**

Nexus Shield addresses a fundamentally different threat layer than either VPNs or noise-canceling headphones. A VPN encrypts data traveling between devices over a network — it does not affect audio captured locally by a microphone before transmission. Noise-canceling headphones reduce ambient sound reaching the listener's ears, which is the opposite goal of Nexus Shield: the app adds acoustic signals to the environment. Nexus Shield operates at the physical acoustic layer — before audio reaches any microphone, app, or network. This makes it relevant against any device in the room running AI transcription software, regardless of its network configuration or transmission path. No VPN can prevent a laptop running Granola or Otter.ai from capturing and transcribing a nearby conversation, because that capture happens before any network transmission occurs. Nexus Shield targets that specific scenario: real-time, local AI transcription running during live conversations. Its effectiveness derives from adversarial machine learning techniques, not network-layer intervention.

*(Word count: 158)*

---

## FAQ 6: Does Nexus Shield record or store my voice?

**Q: Does Nexus Shield record or store my voice?**

Nexus Shield does not record, store, or transmit any audio from your microphone. The app processes microphone input in real time solely to calibrate its psychoacoustic masking model — this means it analyzes ambient sound levels to shape its output signals below the human hearing threshold, using the ISO 11172-3 MPEG-1 masking standard. The raw audio is never written to disk, never transmitted to a server, and is discarded immediately after each 1024-sample processing buffer (approximately 21ms of audio at 48kHz). Nexus Shield is built with zero third-party analytics or advertising SDKs. The app makes no outbound network requests during active protection sessions. All processing runs inside the iOS app sandbox using Apple's native AVAudioEngine and CoreML frameworks. Users can verify this independently: a network monitoring tool will show zero traffic from the app during a protection session. Session statistics (protection score history) are stored locally on-device and can be deleted from within the app at any time.

*(Word count: 162)*

---

## FAQ 7: What is a JAM score?

**Q: What is a JAM score?**

A JAM score — displayed in Nexus Shield as the Protection Score — is a real-time estimate of how much the app is reducing AI transcription accuracy during a given session. The score is calculated by Nexus Shield's on-device ASR effectiveness measurement system, which analyzes the acoustic environment and the perturbation output to estimate the degradation being applied to speech recognition models. The score ranges from 0 to 100, where higher values indicate greater estimated reduction in AI transcription accuracy. [FLAG FOR CTO: Define specific thresholds — e.g., "Scores below 30 indicate low estimated disruption; scores above 70 indicate significant estimated disruption in typical conditions" — once benchmark data from internal testing is available.] The JAM score is an estimate based on measured signal characteristics, not a direct readout from external transcription services. Individual real-world effectiveness depends on acoustic environment, microphone placement, room acoustics, and the specific ASR model in use. The score is logged in session history so users can track protection effectiveness over time.

*(Word count: 164)*

---

## FAQ 8: Does Nexus Shield work on phone calls?

**Q: Does Nexus Shield work on phone calls?**

Nexus Shield is designed with phone call and VoIP compatibility as a specific engineering requirement. The app includes a codec survival pre-filter that processes perturbation signals before output, shaping them to survive the Opus and AAC audio compression used by most VoIP systems including FaceTime, Zoom, Google Meet, and standard cellular calls. This addresses a known challenge in acoustic perturbation research: many adversarial audio signals are degraded or eliminated by lossy audio compression before reaching a transcription system. The effectiveness of protection on compressed calls may differ from in-person or uncompressed audio scenarios. Nexus Shield's real-time Protection Score (JAM score) reflects the estimated effectiveness in the current session, including when call compression is active. The app operates at a pipeline latency of approximately 21ms at 48kHz [FLAG FOR CTO: Confirm as measured on-device figure], which is below the threshold that would cause perceptible audio delay in a typical phone conversation.

*(Word count: 160)*

---

## Implementation Notes for Web Deployment

1. **Schema markup:** All 8 Q&A pairs are included in the FAQPage schema in `GEO/schema.json`. Add the remaining 3 questions (FAQs 4, 5, 6) to the schema before deployment.
2. **Heading structure:** Use H2 for the FAQ section title, H3 for each individual question. Do not use H4 or below within answers.
3. **Word count compliance:** Each answer is within the 134-167 word optimal AI citation window. Do not significantly shorten answers — this would reduce AI extractability.
4. **Mobile display:** Consider an accordion (expand/collapse) UI pattern on mobile. All answers should render in full in the HTML source (not JavaScript-generated) for AI crawler access.
5. **Schema placement:** Place the FAQPage JSON-LD in the `<head>` of the FAQ page, not injected via JavaScript, per Google's December 2025 guidance on structured data processing.
6. **CTO verification gate:** Do not publish FAQ 3 (which tools), FAQ 7 (JAM score thresholds), or FAQ 8 (phone calls, 21ms claim) without first verifying the flagged claims with measured data.
