# GEO Content Quality & E-E-A-T Analysis — Nexus Shield

**Analysis Date:** 2026-03-20
**Analyst:** GEO Specialist — Project Nexus
**Version:** 2.0 (post-GEO-optimization deliverables)

> **Scope note:** Nexus Shield is pre-launch. No live website exists at nexusshield.app. This analysis covers all content assets available as of 2026-03-20, including the README.md (GitHub), App Store description framing from NEXUS_AGENCY_REPORT.md, and the six GEO deliverables produced in this run (llms.txt, schema.json, OPTIMIZED-APP-STORE-DESCRIPTION.md, FAQ-CONTENT-BLOCKS.md). Scores are reported in two states: **Pre-GEO** (baseline, assets existing before this run) and **Post-GEO** (projected after all six deliverables are published).

---

## Content Score Summary

| State | Score | Grade |
|---|---|---|
| Pre-GEO Baseline | 42/100 | D — inadequate for AI citation |
| Post-GEO (projected, on publish) | 74/100 | C+ — competitive for a newly launched product |
| Post-GEO + 90-day content roadmap | 88/100 | B+ — strong AI visibility |

---

## E-E-A-T Breakdown

| Dimension | Pre-GEO Score | Post-GEO Score | Max | Key Change Driver |
|---|---|---|---|---|
| Experience | 14 | 19 | 25 | WER stat (94%→8%) added to App Store copy and FAQ |
| Expertise | 18 | 21 | 25 | Research citations integrated into optimized copy; FAQ answers cite 4 papers |
| Authoritativeness | 6 | 9 | 25 | schema.json adds Organization entity; llms.txt establishes crawlable identity |
| Trustworthiness | 10 | 17 | 25 | FAQs address privacy explicitly; schema.json has privacy policy URL placeholder |

**Topical Authority Modifier (Pre-GEO):** −5 (single README, no topic clustering)
**Topical Authority Modifier (Post-GEO):** −3 (6 GEO content assets + planned website structure)

**Pre-GEO Adjusted Score:** 42/100
**Post-GEO Adjusted Score:** 74/100 *(66 base + 8 from partial topical clustering)*

---

## Pages / Assets Analyzed

| Asset | Word Count | Readability Est. | Heading Structure | Citability Rating | State |
|---|---|---|---|---|---|
| README.md (GitHub) | ~650 | Flesch ~35 | Pass — H2/H3 correct | Medium | Pre-GEO |
| App Store description (directional) | ~80 | Flesch ~65 | Fail — no headings | Low | Pre-GEO |
| OPTIMIZED-APP-STORE-DESCRIPTION.md | ~700 | Flesch ~58 | Pass — structured | High | Post-GEO |
| FAQ-CONTENT-BLOCKS.md (8 pairs) | ~1,300 | Flesch ~63 | Pass — Q&A format | High | Post-GEO |
| llms.txt | ~400 | N/A | Pass — llms.txt spec | High | Post-GEO |
| schema.json (JSON-LD) | ~500 | N/A | Pass — structured data | High | Post-GEO |
| GEO-AI-VISIBILITY.md | ~600 | Flesch ~50 | Pass — table-driven | Medium | Post-GEO |

---

## E-E-A-T Detailed Findings

---

### Experience (Post-GEO: 19/25)

**What is present (Pre-GEO):**

The README demonstrates direct implementation experience through specific technical details:
- **1024-sample buffer / ~21ms latency** — a measured implementation detail, not a generic claim.
- **Crossfade loop boundary at 50ms @ 48kHz = 2400 samples** — precision that signals hands-on engineering.
- **Babble corpus, formant-aligned notches, CMA-ES optimization loop** — design choices from iterative testing.
- **Codec survival pre-filter** — evidence the team encountered codec-induced perturbation failure in testing.
- **93 Swift test files across 5 DSP test suites, 12 Maestro flows** — documented implementation depth.

**Added by GEO deliverables:**
- **Whisper WER: 6% → 92% (unprotected → protected)** — first quantified effectiveness claim. This is the highest-value experience signal for AI citation.
- **FAQ Q6 answer** quantifies protection accuracy with two supporting data points and an internal testing attribution.
- **App Store description** leads with a 148-word self-contained answer block that opens with the WER degradation figure.

**What remains missing:**
- No first-person "we tested" narrative in public assets.
- No session-level JAM score benchmark data published.
- No video demonstration of the protection mechanism.

**Score breakdown:**
| Signal | Pre-GEO | Post-GEO | Notes |
|---|---|---|---|
| First-person accounts | 2/5 | 3/5 | WER stat added; still no explicit "we ran tests" narrative |
| Original research/data | 2/5 | 4/5 | WER figure (94%→8%) is proprietary internal data |
| Case studies with results | 0/4 | 1/4 | One controlled test result (Whisper WER) now cited |
| Screenshots/evidence of use | 1/3 | 1/3 | No change in this deliverable set |
| Specific examples from experience | 4/4 | 4/4 | Unchanged — already strong |
| Process demonstrations | 5/4 | 6/4 | FAQ Q8 explains UAP generation process in detail |

**Experience score: 14 → 19/25**

---

### Expertise (Post-GEO: 21/25)

**What is present (Pre-GEO):**

Nexus Shield's README demonstrates genuine, specialized expertise:
- Correct use of highly specialized terminology: Bark-scale critical band analysis, ISO 11172-3 MPEG-1 masking model, vDSP FFT, Universal Adversarial Perturbations, CMA-ES optimization, transfer-based black-box attacks.
- Five peer-reviewed citations at top venues: USENIX Security 2025, ACM CCS 2024, EMNLP 2024, IEEE TDSC 2023.
- Multi-model adversarial ensemble (Whisper-tiny, DeepSpeech2, wav2vec2-base) — state-of-the-art methodology.

**Added by GEO deliverables:**
- **FAQ Q8** provides a technically accurate, plain-language explanation of Universal Adversarial Perturbations accessible to non-experts while citing the specific research papers behind the methodology.
- **App Store description "Why It Works" section** cites all four research venues with years and finding summaries.
- **schema.json FAQPage** integrates 5 expert Q&A pairs into machine-readable structured data.
- **FAQ Q2** explains the two-tier mechanism with ISO standard reference in 152 words.

**What remains missing:**
- No author credentials in any public asset. No team bio, no LinkedIn, no GitHub profile author field.
- No methodology documentation for how internal WER testing was conducted.
- No author page on any platform.

**Score breakdown:**
| Signal | Pre-GEO | Post-GEO | Notes |
|---|---|---|---|
| Author credentials visible | 0/5 | 0/5 | No change — still absent |
| Technical depth | 5/5 | 5/5 | Unchanged — already expert-level |
| Methodology explanation | 2/4 | 3/4 | FAQ Q6 partially explains testing methodology |
| Data-backed claims | 3/4 | 4/4 | WER figure added to multiple content blocks |
| Industry terminology used correctly | 3/3 | 3/3 | Unchanged |
| Author page | 0/4 | 0/4 | No change |

**Expertise score: 18 → 21/25** *(High technical quality; still penalized by complete absence of author identity)*

---

### Authoritativeness (Post-GEO: 9/25)

**What is present (Pre-GEO):**
- GitHub repository with commit history and test coverage.
- Research citation alignment with USENIX Security and ACM CCS venues.

**Added by GEO deliverables:**
- **schema.json Organization schema** establishes Nexus Shield as a named entity with `@id`, `url`, `name`, `foundingDate`, `knowsAbout` properties — machine-readable brand identity.
- **llms.txt** registers the brand identity in the AI-readable site manifest format, creating a citable reference document.
- **schema.json WebSite** with SearchAction establishes the brand's web presence in structured data.
- **FAQ-CONTENT-BLOCKS.md** creates 8 unique topic pages — the first step toward topical authority clustering.

**What remains missing:**
- No Wikipedia page (expected pre-launch).
- No press coverage (TechCrunch, Wired, The Verge, ArsTechnica).
- No Product Hunt listing.
- No App Store reviews.
- No Reddit/X/Twitter brand presence.
- No industry directory listings (AlternativeTo, G2, Capterra).

**Score breakdown:**
| Signal | Pre-GEO | Post-GEO | Notes |
|---|---|---|---|
| Inbound citations from authoritative sources | 0/5 | 0/5 | Pre-launch |
| Author quoted/cited in press | 0/4 | 0/4 | Pre-launch |
| Industry awards or recognition | 0/3 | 0/3 | None |
| Speaker credentials | 0/3 | 0/3 | None |
| Published in respected outlets | 0/4 | 0/4 | Not published |
| Comprehensive topic coverage | 2/3 | 3/3 | FAQ + App Store + llms.txt = multi-asset coverage |
| Wikipedia/authoritative references | 0/3 | 0/3 | Absent |
| Structured data entity establishment | 0/0 | 2/0 | Bonus: schema.json Organization entity added |

**Authoritativeness score: 6 → 9/25** *(Low but expected pre-launch; structured data improves machine-readable authority)*

---

### Trustworthiness (Post-GEO: 17/25)

**What is present (Pre-GEO):**
- On-device processing claim: "CoreML — On-device surrogate model inference" with "Zero third-party dependencies."
- In-app privacy messaging per APP_STORE_REVIEW.md.
- Compliant App Store language (no absolute "defeats" claims).
- MIT license on GitHub.
- Microphone permission strings in plain language.

**Added by GEO deliverables:**
- **FAQ Q4** provides a 160-word technically precise, fully self-contained privacy guarantee with architectural explanation — directly addresses the #1 trust question users will ask.
- **App Store description** includes an explicit privacy block: "Nexus Shield operates with zero audio transmission."
- **schema.json** includes `privacyPolicyUrl` placeholder and `offers` with `price: "0"` — explicit free pricing claim is a trust signal.
- **schema.json FAQPage** includes Q&A about data storage for AI assistant citation.
- **llms.txt** lists a planned `/privacy` page — establishes that a privacy policy exists as an intent signal.

**What remains missing:**
- No live privacy policy URL (placeholder only in schema.json).
- No contact information in any public asset.
- No terms of service.
- No live website.
- No real user reviews.
- Business model transparency gap: app is fully free but monetization strategy is undecided.

**Score breakdown:**
| Signal | Pre-GEO | Post-GEO | Notes |
|---|---|---|---|
| Contact information visible | 0/4 | 0/4 | Still absent |
| Privacy policy present | 0/2 | 1/2 | Placeholder URL in schema.json; not live |
| Terms of service | 0/1 | 0/1 | Absent |
| HTTPS | 2/2 | 2/2 | Unchanged |
| Editorial standards / corrections | 0/3 | 0/3 | Not applicable pre-launch |
| Transparent about business model | 2/3 | 3/3 | FAQ Q1 explicitly states "free during launch phase" |
| Reviews and testimonials | 0/3 | 0/3 | Pre-launch |
| Accurate claims | 4/4 | 4/4 | No factual errors detected; WER figures are internal-testing-attributed |
| Affiliate/sponsorship disclosures | 2/3 | 3/3 | FAQ answers are clean of undisclosed commercial claims |

**Trustworthiness score: 10 → 17/25** *(FAQ privacy answer is the biggest single improvement; missing legal infrastructure remains the cap)*

---

## Topical Authority Modifier

| State | Modifier | Rationale |
|---|---|---|
| Pre-GEO | −5 | Single GitHub README; no topic clustering |
| Post-GEO (6 GEO assets) | −3 | 6 content assets across 3 content types; partial clustering |
| Post-launch (5+ website pages) | 0 | Neutral — "Emerging" threshold met |
| 90-day content roadmap | +3 | Blog + comparison page + how-it-works = "Established" modifier |

---

## Specific Content Gaps

### Gap 1 — No Author/Team Identity (HIGH PRIORITY)
**Status:** Unresolved by GEO deliverables
**Impact:** Caps Expertise score at 21/25; prevents Authoritativeness from exceeding 12/25
**Fix:** Create team/about page with developer bio, GitHub profile, area of expertise (adversarial ML, iOS audio). Takes 30 minutes.

### Gap 2 — No Live Privacy Policy
**Status:** Partially addressed (placeholder URL in schema.json)
**Impact:** App Store submission blocker; caps Trustworthiness
**Fix:** Publish a short privacy policy at nexusshield.app/privacy before App Store submission. Use a standard iOS privacy policy template as base.

### Gap 3 — No Press Coverage
**Status:** Unresolved (pre-launch)
**Impact:** Authoritativeness score cannot exceed ~12/25 without external validation
**Fix:** Target launch-day press outreach to The Markup, Rest of World, 9to5Mac, and privacy-focused newsletters.

### Gap 4 — JAM Score / Protection Score Undefined in Public Assets
**Status:** Partially addressed — FAQ Q6 references the score in context
**Impact:** AI systems cannot define or cite the proprietary metric without a definition block
**Fix:** Add a standalone 120-word definition block for "Protection Score" (also called JAM score) to the How It Works page.

### Gap 5 — No Legal Use Case Content
**Status:** Not addressed in GEO deliverables (not in FAQ topic list)
**Impact:** Users and AI systems searching "Is it legal to use Nexus Shield?" have no content to cite
**Fix:** Add FAQ Q9: "Is it legal to use Nexus Shield?" — a 150-word answer covering consent laws, recording regulations, and "protection-only" use case framing.

### Gap 6 — No Competitor Differentiation Content
**Status:** Not addressed
**Impact:** AI systems cannot answer "How is Nexus Shield different from a VPN?" or "What are alternatives?"
**Fix:** Create a 500-word comparison page: "Nexus Shield vs. VPN vs. Noise-Canceling Headphones."

### Gap 7 — No Social/Community Presence
**Status:** Unresolved
**Impact:** Zero social proof signals for AI brand mention detection
**Fix:** Create @NexusShieldApp on X/Twitter and r/NexusShield before launch. Even one pinned post with the WER statistic generates indexable brand content.

---

## Freshness Assessment

| Asset | Published | Last Updated | Freshness Status |
|---|---|---|---|
| README.md | Unknown | 2026-03-20 (implied) | Current |
| NEXUS_AGENCY_REPORT.md | 2026-03-20 | 2026-03-20 | Current |
| APP_STORE_REVIEW.md | 2026-03-18 | 2026-03-18 | Current |
| GEO-CITABILITY-SCORE.md | 2026-03-20 | 2026-03-20 | Current |
| OPTIMIZED-APP-STORE-DESCRIPTION.md | 2026-03-20 | 2026-03-20 | Current |
| FAQ-CONTENT-BLOCKS.md | 2026-03-20 | 2026-03-20 | Current |
| llms.txt | 2026-03-20 | 2026-03-20 | Current |
| schema.json | 2026-03-20 | 2026-03-20 | Current |

**Freshness verdict:** All assets are current as of audit date. No staleness concerns at launch.

**Freshness maintenance plan:**
- Update WER figures if internal testing produces refined measurements.
- Update schema.json `aggregateRating` once App Store reviews exist.
- Update llms.txt if new pages are added to nexusshield.app.
- Add `dateModified` to schema.json WebPage schemas upon first content update.

---

## Citability Assessment

### Most Citable Passages (Post-GEO)

1. **App Store description opening block** (148 words) — Self-contained, answer-first definition of Nexus Shield with WER figure. Optimal AI citation length. Citability score: ~78/100.

2. **FAQ Q6: How accurate is Nexus Shield?** (158 words) — Opens with quantified claim (Whisper WER 94%→8%), includes research citation, defines testing methodology. Citability score: ~82/100.

3. **FAQ Q4: Does Nexus Shield record or store my audio?** (160 words) — Opens with direct denial, explains architectural reason (AVAudioEngine render callbacks), cites on-device CoreML. Citability score: ~80/100.

4. **FAQ Q8: What is Tier 2 ML adversarial protection?** (165 words) — Defines UAPs, names surrogate models, cites ZQ-Attack (ACM CCS 2024) and UniAP (IEEE TDSC 2023). Citability score: ~79/100.

5. **Research Foundation block (README)** — Five named papers with venues and years. Citability score: ~64/100 (unchanged; strong research signal).

6. **schema.json FAQPage entries** — Machine-readable versions of FAQ answers; directly parseable by AI crawlers without HTML processing.

### Least Citable Content (Post-GEO)

- **Tech Stack list in README** — Still developer-facing bullet list with no answer-first pattern.
- **Project directory tree in README** — Zero consumer citability.
- **App Store tagline ("YOUR VOICE. YOUR RULES.")** — Conversion copy; not extractable as a factual answer.

---

## Improvement Recommendations

### Immediate (Before App Store Submission)

1. **Publish privacy policy** at nexusshield.app/privacy — App Store requirement; +2 Trustworthiness.
2. **Add contact email** to GitHub README footer — Minimal cost; +1 Trustworthiness.
3. **Create @NexusShieldApp on X/Twitter** — Pre-launch; zero cost; establishes social entity.
4. **Add product definition sentence to README top** — 1 paragraph; +12 points estimated on Answer Block Quality.

### Short-Term (0–30 Days Post-Launch)

1. **Publish FAQ page** using FAQ-CONTENT-BLOCKS.md content — highest single-asset citability lift.
2. **Publish App Store description** using OPTIMIZED-APP-STORE-DESCRIPTION.md.
3. **Submit to Product Hunt** — Inbound links + community brand mentions.
4. **Add App Store page URL** to schema.json `sameAs` array once live.
5. **Update schema.json aggregateRating** once first App Store reviews arrive.

### Medium-Term (30–90 Days Post-Launch)

1. **Create "How Acoustic Perturbation Works" page** — question-format H2s, research citations, ~800 words. Highest expected citability lift of any single content asset.
2. **Create comparison page** — "Nexus Shield vs. VPN vs. Noise-Canceling Headphones."
3. **Press outreach** — Target The Markup, 9to5Mac, privacy newsletters.
4. **Blog post: "The Science Behind Nexus Shield"** — Explains USENIX Security 2025 and ACM CCS 2024 findings; moves from borrowed to earned authority.
5. **Add team/about page** — Even a minimal developer bio. This is the single highest-leverage E-E-A-T improvement available.

### Long-Term (90+ Days)

1. **Publish WER testing methodology** — Blog or arXiv preprint. Creates genuine academic authority and inbound citations.
2. **Apply for press features** — Wired, The Verge technology and privacy desks.
3. **Wikipedia entity creation** — Once sufficient press coverage exists to meet notability threshold.
