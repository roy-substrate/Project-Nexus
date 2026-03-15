# Sprint 4 — Trust & Retention
**Period:** 2026-03-15 → 2026-03-28 (2 weeks)
**Sprint Goal:** Make users *feel* protected — surface proof, fix silent failures, increase trial conversion.

---

## CEO Direction (Autonomous — 2026-03-15)
1. Trial extended to 7 days (App Store Connect metadata update)
2. Diagnostics tab stays Pro; jam score surfaces on free main screen
3. Protection history count added to shield screen

## Sprint Backlog

### P0 — Critical Fixes (Engineering, this sprint)
- [x] BUG-01: ASREffectivenessService restartTask reuses ended request → fixed
- [x] BUG-02: bufferUnderruns counter never incremented → fixed (atomic)

### P1 — Product × Design (ready for engineering next sprint)
- [ ] Jam score hero redesign — large number, plain English, screenshot-worthy
      Owner: /nexus-product + /nexus-mobile
- [ ] Remove "faintly audible" copy from intensity slider; replace with confidence framing
      Owner: /nexus-script
- [ ] Remove "Skip for now" on mic permission page; add friction-reducing trust copy
      Owner: /nexus-script + /nexus-product
- [ ] Protection history stat on shield screen ("Protected 12 sessions this month")
      Owner: /nexus-product (spec) → /nexus-mobile (build)

### P2 — Growth (parallel)
- [ ] App Store description rewrite emphasising "0% data shared, 100% on-device"
      Owner: /nexus-growth + /nexus-script → CEO approval before publish
- [ ] Share your score — screenshot card with jam %
      Owner: /nexus-product (spec) → /nexus-mobile (build)

### P3 — Test Coverage (this sprint, branch: analyze-test-coverage)
- [ ] DSP generators: BabbleNoiseGenerator, SpectralNotchGenerator, FrequencySweepGenerator
- [ ] PsychoacousticMasker unit tests
- [ ] PerturbationService start/stop/updateConfig mock tests
- [ ] UAPManager: loadUAPs, fillBuffer, variant selection
      Owner: /nexus-qa → /nexus-review

### P4 — iOS Platform (next sprint)
- [ ] WidgetKit Lock Screen widget — one-tap shield activation
      Owner: /nexus-mobile
- [ ] Siri / Action button shortcut integration
      Owner: /nexus-mobile

---

## Definition of Done
- All P0 bugs resolved ✅
- QA gate: PASS (0 try!, 0 fatalError, 0 TODO)
- Eng Manager approved all fixes
- Coverage ≥ 40% on DSP layer
- CEO approved any copy/App Store changes before publish

---

## Metrics This Sprint
- Trial-to-paid conversion rate (baseline this week)
- Permission grant rate on onboarding page 3
- Day-7 retention
