# Test Coverage Analysis & Proposals

## Current State

**Coverage: Sprint 5 Agency Run — ~62% coverage of testable units**

**Total tests: ~303** (267 existing + ~36 new in Sprint 5 Agency Run)

| Sprint | Tests Added | Files | Coverage Δ |
|--------|------------|-------|-----------|
| Initial | 93 | 5 | 0% → ~20% |
| Sprint 4 P3 | 114 | 6 | ~20% → ~55% |
| Sprint 5 Agency | ~36 | 2 | ~55% → ~62% |

### Sprint 5 Agency Run — Newly Added

| File | Component | Tests |
|------|-----------|-------|
| `CodecSimulatorTests.swift` | `CodecSimulator` (lifecycle, applyToSpectrum, applyToSignal) | ~14 |
| `AVAudioPCMBufferUtilitiesTests.swift` | `AVAudioPCMBuffer+Utilities` (rms, peak, clear, gain, copy, mix) | ~12 |

**CodecSimulator bug fixed this run:** `applyCodecToBlock` was creating a new `FFTSetup` and
Hann window on every OLA block invocation. Both are now cached as instance variables and
destroyed in `deinit`, matching the `MicCaptureNode` pattern.

### Sprint 4 P3 — Newly Added

| File | Component | Tests |
|------|-----------|-------|
| `BabbleNoiseGeneratorTests.swift` | `BabbleNoiseGenerator` | 15 |
| `SpectralNotchGeneratorTests.swift` | `SpectralNotchGenerator` | 17 |
| `FrequencySweepGeneratorTests.swift` | `FrequencySweepGenerator` | 18 |
| `PsychoacousticMaskerTests.swift` | `PsychoacousticMasker` | 20 |
| `UAPManagerTests.swift` | `UAPManager`, `UAPVariant` | 27 |
| `PerturbationServiceTests.swift` | `PerturbationService` | 17 |

**PerturbationServiceTests note:** Tests that call `service.start()` are guarded
with `XCTSkip` for environments without audio hardware (CI). Tests of init,
stop-without-start, and callback assignment run unconditionally.

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

| Area | Sprint 4 P3 | Sprint 5 | Target |
|------|-------------|----------|--------|
| Models | ~60% | ~60% | 90% |
| Extensions | ~80% | **~90%** ✅ | 90% |
| DSP Utilities | ~70% | ~70% | 80% |
| DSP Generators | **~70%** ✅ | **~75%** ✅ | 70% |
| ML Components | **~65%** ✅ | **~65%** ✅ | 60% |
| Services | **~45%** | **~45%** | 70% |
| Audio Engine | 0% | 0% | 50% |
| UI Views | 0% | 0% | 30% |

### Remaining Gaps (Sprint 6)
- `AudioPipelineManager` — requires mock AVAudioEngine protocol (CTO escalation pending)
- `MicCaptureNode`, `SpeakerPlaybackRouter` — require audio session mocking
- `PerturbationOptimizer` — random-search convergence and iteration-cap tests
- SwiftUI views — ViewInspector or snapshot tests
