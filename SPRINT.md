# Sprint 4 — Trust & Retention
**Period:** 2026-03-15 → 2026-03-28 (2 weeks)
**Sprint Goal:** Make users *feel* protected — surface proof, fix silent failures, increase trial conversion.

---

## CEO Direction (Autonomous — 2026-03-15)
1. Trial extended to 7 days (App Store Connect metadata update)
2. Diagnostics tab stays Pro; jam score surfaces on free main screen
3. Protection history count added to shield screen
4. Post-session score flash — celebrate >50% jam sessions
5. Weekly streak notification — keep users coming back (Sprint 5)
6. Quick presets Stealth/Balanced/Max (Sprint 5)

## Sprint Backlog

### P0 — Critical Fixes ✅ DONE
- [x] BUG-01: ASREffectivenessService restartTask reuses ended request → fixed
- [x] BUG-02: bufferUnderruns counter never incremented → fixed (atomic)

### P1 — Product × Design → Engineering ✅ SHIPPED THIS RUN
- [x] All features made free — paywall removed, isPro always true
- [x] "Faintly audible" copy → confidence framing in Settings Advanced section
- [x] Protection history stat on shield screen ("Protected N sessions")
- [x] Post-session score flash — capsule banner on shield deactivation if score >50%

### P1 — Remaining ✅ DONE
- [x] Remove "Skip for now" on mic permission page; add friction-reducing trust copy
      Done: commit e928520 — `if page < 2`, trust copy "THE MIC IS HOW THE SHIELD HEARS.\nNO ACCESS = NO PROTECTION."

### P2 — Growth (parallel)
- [x] App Store description rewrite — lead with "100% on-device, zero data shared"
      Done: GEO/OPTIMIZED-APP-STORE-DESCRIPTION.md — target 78/100 citability (commit f372d80)
- [ ] Demo video: jam score rising on a live call — highest-shareability asset
      Owner: /nexus-marketing — brief approved this run

### P3 — Test Coverage ✅ DONE
- [x] DSP generators: BabbleNoiseGenerator, SpectralNotchGenerator, FrequencySweepGenerator
- [x] PsychoacousticMasker unit tests
- [x] PerturbationService start/stop/updateConfig mock tests
- [x] UAPManager: loadUAPs, fillBuffer, variant selection
      18 test files, 288 test methods total (commit history)

### P4 — iOS Platform (Sprint 5)
- [ ] WidgetKit Lock Screen widget — one-tap shield activation
      Owner: /nexus-mobile
- [ ] Siri / Action button shortcut integration
      Owner: /nexus-mobile
- [ ] Weekly streak local notification
      Owner: /nexus-product (spec) → /nexus-mobile (build)
- [ ] Quick presets: Stealth / Balanced / Max
      Owner: /nexus-product (spec) → /nexus-mobile (build)

---

## Definition of Done
- All P0 bugs resolved ✅
- QA gate: PASS (0 try!, 0 fatalError, 0 TODO) ✅
- Eng Manager approved all fixes ✅
- CEO approved all copy changes ✅
- Coverage ≥ 40% on DSP layer ✅ (18 files, 288 test methods)

## Engineering Fix — This Run
- AudioPipelineManager.swift:162 — replaced `DispatchQueue.main.async` with `Task { @MainActor [weak self] in ... }` for Swift 6 consistency. Approved by Eng Manager.

---

## CEO Decisions — Autonomous (2026-03-20)

### Monetization Model (DECIDED)
- **Consumer:** Free forever — no paywall, no subscription. All features unlocked. Acquisition via App Store virality + jam score sharing.
- **B2B / M&A Legal:** $99–149/seat/month SaaS for AmLaw 200 law firms and M&A teams. Entry via M&A partner direct outreach (see office-hours design doc). First contract target: Q2 2026.
- Rationale: Consumer free builds install base + social proof; B2B $99–149/seat captures high-willingness-to-pay segment with existing pain (deal confidentiality on calls).

### App Store Copy (APPROVED — pending masking actualization)
- GEO/OPTIMIZED-APP-STORE-DESCRIPTION.md is approved for submission.
- **Gate:** Must ship masking actualization fix (CTO Option B — this run) before submitting to App Store Connect. Masking claim ("psychoacoustic masking") must be functionally true at submission.

### Demo Video (GREEN-LIT)
- Brief approved: jam score rising live on a Zoom/Teams call, real device, no voiceover.
- Owner: /nexus-marketing
- Deliverable: 30s vertical video (Reels/TikTok format) + 60s horizontal (YouTube).
- Target: complete before Sprint 5 ends (2026-04-11).

### Sprint 5 Scope (APPROVED)
- **P0:** One-tap shield activation — reduce friction from 3 taps to 1 (Lock Screen widget + home screen shortcut). Must ship Sprint 5 Day 1.
- **P1:** Weekly streak local notification — re-engagement loop. Max 2 notifications/week.
- **P1:** Quick presets (Stealth / Balanced / Max) — configures intensity + frequency range in one tap.
- **P2:** B2B landing page (nexusshield.app/enterprise) — gated behind M&A legal vertical messaging.
- **Out of scope Sprint 5:** Siri integration (defer to Sprint 6), iCloud sync (defer until B2B signed).

### Office-Hours Design Doc Reference
- Path: `~/.gstack/projects/project-nexus/root-claude-nexus-agency-setup-0QjbK-design-20260320-112318.md`
- Status: APPROVED. Consumer Frictionless (Approach A) + M&A Legal Wedge (Approach B) strategy.
- Assignment (CEO carries): Email one M&A partner at an AmLaw 200 firm before writing B2B landing page code.

---

## Metrics This Sprint
- Permission grant rate on onboarding page 3
- Day-7 retention
- Post-session flash tap-through rate (new)
