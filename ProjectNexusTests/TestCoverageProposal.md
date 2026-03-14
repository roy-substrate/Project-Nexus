# Test Coverage Analysis & Proposals

## Current State

**Coverage: 0% → Initial tests added for ~20% coverage of testable units**

The project had zero tests. This document outlines what has been added and what
remains to be addressed.

---

## Tests Added (This PR)

| File | Component | Tests |
|------|-----------|-------|
| `DSPUtilitiesTests.swift` | `DSPUtilities` | 19 |
| `FloatArrayDSPTests.swift` | `[Float]` DSP extensions | 23 |
| `PerturbationConfigTests.swift` | `PerturbationConfig`, `CodecTarget` | 19 |
| `PerturbationTypeTests.swift` | `PerturbationTier`, `PerturbationTechnique` | 18 |
| `AudioMetricsTests.swift` | `AudioMetrics` | 14 |

**Total: 93 new tests**

---

## Highest Priority Gaps

### 1. DSP Generators (Audio/DSP/) — Critical
These contain core mathematical logic that has no tests at all.

**`BabbleNoiseGenerator`**
- Test that `fillBuffer` produces non-zero output when enabled
- Test that `setIntensity(0)` produces near-silence
- Test `isEnabled = false` produces zero output
- Test frequency band coverage (output should have energy in 300–4000 Hz range)

**`FrequencySweepGenerator`**
- Test that sweep frequency advances each buffer fill
- Test chirp stays within `frequencyRangeLow`–`frequencyRangeHigh`
- Test `setIntensity` scales output linearly

**`SpectralNotchGenerator`**
- Test that notch frequencies are attenuated in output spectrum
- Test crossfade behaviour when switching notch frequencies
- Test output is bounded to `[-1, 1]`

**`PsychoacousticMasker`**  ← *Most critical*
- Test Bark scale masking thresholds are computed for known input levels
- Test that masked regions produce lower output amplitude
- Test ISO 11172-3 masking spread matches expected values at spot-check frequencies

**`CodecSimulator`**
- Test that `opus32k` target produces measurably different output to `opus128k`
- Test output length matches input length
- Test perturbation energy is preserved above codec noise floor

**`DSPUtilities.bandpassFilter`**
- Test that frequencies below `lowFreq` are attenuated
- Test that frequencies above `highFreq` are attenuated
- Test passband energy is largely preserved

### 2. Audio Engine (Audio/Engine/) — High Priority
These components manage the real-time pipeline and need integration tests:

**`AudioPipelineManager`**
- Test `addGenerator` / `removeAllGenerators` state tracking
- Test `setOutputGain` clamps to `[0, 1]`
- Test soft-clipping limits output to `[-1, 1]`
- Mock-based test: verify `onMetricsUpdate` callback fires after buffer fill

**`MicCaptureNode`**
- Test tap installation and removal
- Use mock `AVAudioEngine` to verify capture callback receives correct buffer size

### 3. ML Components (Audio/ML/) — High Priority

**`UAPManager`**
- Test `selectVariant` changes active UAP data
- Test `loadUAPs` handles missing bundle resource gracefully (falls back to placeholder)
- Test `fillBuffer` with placeholder UAPs produces bounded output
- Test all `UAPVariant` cases are handled

**`PerturbationOptimizer`**
- Test CMA-ES step produces output with expected distribution
- Test step count increments each call
- Test convergence guard: optimizer does not diverge after N steps

### 4. Services (Services/) — High Priority

**`PerturbationService`** (requires mocked dependencies)
- Test `start(with:)` where `tier1Enabled = false` does not add Tier 1 generators
- Test `start(with:)` where `tier2Enabled = false` does not add UAP generator
- Test `updateConfig` propagates intensity to all active generators
- Test `stop()` sets `isRunning = false` and clears generator references
- Test UAP variant selection logic: ensemble → whisper → deepSpeech fallback order

### 5. Extensions (Extensions/) — Medium Priority

**`AVAudioPCMBuffer+Utilities`**
- Test buffer creation with expected frame count
- Test float channel data pointer is non-nil for mono buffers

### 6. Models (Models/) — Low Priority (partially covered)

**`AudioMode`**
- Test all cases have valid raw values
- Test `Identifiable` conformance (id uniqueness)

---

## Recommended Testing Strategy

### Unit Tests (XCTest, no hardware needed)
All DSP math functions, model logic, configuration toggles, and codec enum
properties can be tested in a standard XCTest target on the simulator.

### Integration Tests (require device or simulator with AVAudioSession)
`AudioPipelineManager`, `MicCaptureNode`, `SpeakerPlaybackRouter`, and
`VoIPAudioRouter` all interact with `AVAudioSession` and `AVAudioEngine`.
These should be tested via protocol abstractions with mock objects to avoid
requiring physical audio hardware.

### Snapshot / UI Tests
SwiftUI views (`MainControlView`, `PerturbationSettingsView`, etc.) should be
covered with ViewInspector or SwiftUI snapshot tests to catch regressions in
layout and state-driven rendering.

---

## Suggested Code Coverage Target

| Area | Current | Target |
|------|---------|--------|
| Models | 0% | 90% |
| Extensions | 0% | 90% |
| DSP Utilities | 0% | 80% |
| DSP Generators | 0% | 70% |
| ML Components | 0% | 60% |
| Services | 0% | 70% |
| Audio Engine | 0% | 50% |
| UI Views | 0% | 30% |
