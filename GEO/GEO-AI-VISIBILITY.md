# GEO AI Visibility Report — Nexus Shield

**Analysis Date:** 2026-03-20
**Stage:** Pre-launch (no live website; GitHub repo is primary web presence)

---

## AI Visibility Score: 32/100 — Poor

> Pre-launch context: A score of 32 at this stage is realistic, not alarming. The technical citability foundation is stronger than most pre-launch products (research citations, specific architecture data). The score is held down entirely by the expected absence of brand mentions, the missing llms.txt, and the absence of a website. All three gaps have clear remediation paths within 30-90 days of launch.

**Score interpretation:**
- 0-20: Critical — Virtually invisible to AI search engines
- 21-40: **Poor — Minimal AI discoverability** ← Current position
- 41-60: Fair — Some AI visibility but significant gaps
- 61-80: Good — Solid AI presence with room for improvement
- 81-100: Excellent — Strong AI search visibility

---

## Score Breakdown

| Component | Score | Weight | Weighted Score | Notes |
|---|---|---|---|---|
| Citability | 41/100 | 35% | 14.4 | Pre-launch content; no FAQ, no website pages |
| Brand Mentions | 8/100 | 30% | 2.4 | GitHub only; no press, no Wikipedia, no social |
| Crawler Access | 100/100 | 25% | 25.0 | GitHub allows all AI crawlers |
| llms.txt | 0/100 | 10% | 0.0 | Absent; file created in this audit for future deployment |
| **AI Visibility Score** | | | **41.8 → 32** | Adjusted down 10 for no-website penalty |

> **Note on composite calculation:** The raw weighted score is 41.8/100. A -10 adjustment has been applied to reflect the absence of any live website — AI crawlers cannot index non-existent pages, making the Crawler Access score partially theoretical. At launch, remove this adjustment and recalculate.

---

## Citability Assessment

**Page Citability Score: 41/100**
*(See GEO-CITABILITY-SCORE.md for full per-block analysis)*

**Top citation-ready passages:**

1. **Research Foundation block** — Score: 64/100
   Five named peer-reviewed papers (USENIX Security 2025, ACM CCS 2024, EMNLP 2024, IEEE TDSC 2023) with ISO/IEC 11172-3 reference. Highest statistical density of any content block. Citable for queries about acoustic adversarial research.

2. **Audio Pipeline specs** — Score: 53/100
   Specific figures: 48kHz, Float32 mono, 1024-sample buffer, ~21ms latency, ISO 11172-3 psychoacoustic masking. Citable for technical queries about implementation specifics.

3. **Two-Tier Attack System** — Score: 46/100
   Named surrogate models (Whisper-tiny, DeepSpeech2, wav2vec2-base), transfer-based black-box attacks, Deepgram/AssemblyAI targets. Citable for queries about how acoustic perturbation works.

**Citation-unlikely areas needing improvement:**

- **App Store description (current direction)** — Score: 37/100. Conversion copy with no quantified claims. Cannot be extracted as a factual answer.
- **Tech Stack list** — Score: 31/100. Framework names without user-value framing. No AI extractable answer to any user query.

**Priority citability fix:** Add a 140-word product definition paragraph to README as the very first content block. This single change would raise citability to an estimated 52/100.

---

## AI Crawler Access

**Crawler Access Score: 100/100**

GitHub.com does not block AI crawlers at the repository level. All major AI indexing bots have unrestricted access to public GitHub repositories.

| Crawler | Service | Status | Notes |
|---|---|---|---|
| GPTBot | OpenAI (training + search) | Allowed | GitHub allows GPTBot on public repos |
| OAI-SearchBot | OpenAI search-only | Allowed | Not blocked by GitHub robots.txt |
| ChatGPT-User | ChatGPT browsing | Allowed | Public repo content is accessible |
| ClaudeBot | Anthropic / Claude | Allowed | GitHub allows ClaudeBot |
| PerplexityBot | Perplexity AI | Allowed | GitHub allows PerplexityBot |
| Amazonbot | Amazon / Alexa AI | Allowed | Not blocked |
| Google-Extended | Gemini training | Allowed | Not blocked by GitHub |
| Bytespider | ByteDance / TikTok AI | Allowed | Not blocked |
| CCBot | Common Crawl | Allowed | GitHub public repos are crawled |
| Applebot-Extended | Apple Intelligence | Allowed | Not blocked |
| FacebookBot | Meta AI | Allowed | Not blocked |
| Cohere-ai | Cohere models | Allowed | Not blocked |

**Issues found:** None for current GitHub presence. **Future action required:** When nexusshield.app launches, ensure robots.txt explicitly allows all AI crawlers listed above. Do not use a blanket `Disallow: /` for any bot. Add a `Sitemap:` directive pointing to sitemap.xml.

---

## llms.txt Status

**Status:** Absent from GitHub repo and planned domain
**Score: 0/100**

The llms.txt standard (https://llmstxt.org) provides AI models with a structured, machine-readable overview of a website's content and purpose. At pre-launch, this file does not exist.

**Action required:** The `GEO/llms.txt` file created in this audit should be deployed at `https://nexusshield.app/llms.txt` when the site launches. This file is ready to deploy.

**Expected score after deployment:** 70/100 (valid format, covers primary content areas; upgrade to 90+ once llms-full.txt is also deployed with complete documentation content).

**Impact on AI Visibility Score:** Deploying llms.txt at launch adds approximately 7 points to the composite AI Visibility Score.

---

## Brand Mention Presence

**Brand Mention Score: 8/100**

| Platform | Status | Details | Score Contribution |
|---|---|---|---|
| Wikipedia | Absent | No Wikipedia article for "Nexus Shield" or "Project Nexus (app)" | 0/30 |
| Reddit | Absent | No r/privacy, r/apple, r/privacy_tech, or r/ios discussion threads found | 0/20 |
| YouTube | Absent | No official channel; no reviews or demo videos | 0/15 |
| LinkedIn | Absent | No company page for Nexus Shield | 0/10 |
| GitHub | Present | Public repository at github.com/roy-substrate/Project-Nexus; commit history, test files, architecture docs | 5/25 |
| App Store | Absent | Pre-launch; no listing | 0/25 |
| Product Hunt | Absent | No listing | 0/25 |
| Press/Tech Media | Absent | No coverage in any tech publication | 0/25 |

> **Note on GitHub score:** GitHub presence contributes 5 points under "Industry/niche sources" because GitHub is recognized as authoritative for technical software projects. The repository is public, indexed, and contains meaningful technical content. This is a genuine, if modest, authority signal for the developer/tech audience.

**Realistic post-launch Brand Mention Score trajectory:**

| Timeline | Expected Score | Key Drivers |
|---|---|---|
| Launch day | 12-15 | App Store listing added |
| 30 days post-launch | 25-35 | Product Hunt, initial reviews, first Reddit mentions |
| 90 days post-launch | 40-55 | Press coverage (1-2 articles), Twitter presence, community discussion |
| 6 months post-launch | 60-70 | Wikipedia eligibility (if notable coverage), YouTube demo, continued press |

---

## Priority Actions (Ranked by AI Visibility Impact)

### Priority 1 — HIGH IMPACT | Deploy llms.txt at launch
**Effort:** 30 minutes | **Impact:** +7 AI Visibility points

Deploy `GEO/llms.txt` (created in this audit) at `https://nexusshield.app/llms.txt` on day one of website launch. This is the easiest high-impact action available.

**Additional:** Create `llms-full.txt` after FAQ and How-It-Works pages exist, and link it from llms.txt. This upgrades the llms.txt score from 70 to 90+.

---

### Priority 2 — HIGH IMPACT | Add product definition paragraph to README
**Effort:** 15 minutes | **Impact:** +11 Citability points → +3.8 AI Visibility points

Add a single definition-first paragraph as the very first content in README.md:

> "Nexus Shield is an iOS app that uses real-time acoustic perturbation to reduce the accuracy of AI speech recognition systems during live conversations. It generates imperceptible audio signals — calibrated using the ISO 11172-3 psychoacoustic masking model — designed to degrade transcripts produced by tools such as Granola, Otter.ai, and Fireflies. All processing is on-device; no audio is recorded or transmitted."

This paragraph is 56 words, self-contained, definition-first, and immediately citable by AI systems.

---

### Priority 3 — HIGH IMPACT | Launch website with 5 core pages
**Effort:** 2-4 weeks | **Impact:** +15-20 AI Visibility points (removes -10 no-website penalty; enables proper Crawler Access score)

Minimum viable website for GEO purposes:
1. **Homepage** — hero section with product definition + key claims
2. **How It Works** — question-format H2s, mechanism explanation, research citations
3. **FAQ** — 8+ questions (content provided in FAQ-CONTENT-BLOCKS.md)
4. **Privacy** — on-device architecture explained for non-technical users
5. **About** — team bio with credentials (even minimal)

---

### Priority 4 — HIGH IMPACT | Product Hunt launch
**Effort:** 1-2 days of preparation | **Impact:** +8-12 Brand Mention points → +2.4-3.6 AI Visibility points

A successful Product Hunt launch (top 5 Product of the Day) generates:
- Authoritative inbound links from producthunt.com (high-authority domain AI models index)
- Reddit discussion threads (community votes often cross-post to r/privacy, r/apple)
- Twitter/X mentions from hunters
- AlternativeTo listing (often auto-populated from PH)

This is the single highest-leverage brand-mention action for a B2C iOS app at launch.

---

### Priority 5 — MEDIUM IMPACT | Create social accounts before launch
**Effort:** 2 hours | **Impact:** +5-8 Brand Mention points → +1.5-2.4 AI Visibility points

Create and partially populate:
- Twitter/X: @NexusShieldApp (or @NexusShield)
- LinkedIn: Nexus Shield company page (even 1-2 posts)
- YouTube: Upload one demo video (JAM score rising on a live call — already planned as highest-virality asset per agency report)

These accounts don't need to be active to contribute brand mention signal — their existence creates entity nodes that AI models connect to the brand.

---

### Priority 6 — MEDIUM IMPACT | Convert Research Foundation to "findings + implementation" table
**Effort:** 30 minutes | **Impact:** +8 Citability points → +2.8 AI Visibility points

Convert the current Research Foundation bullet list to a table with columns: Paper / Venue / Year / Finding / How Nexus Shield Implements It. This transforms borrowed authority (citation list) into demonstrated expertise (implementation mapping).

---

### Priority 7 — HIGH IMPACT (long-term) | Press outreach to privacy publications
**Effort:** 4-6 weeks | **Impact:** +15-25 Brand Mention points → +4.5-7.5 AI Visibility points

Target: The Markup, Rest of World, Wired, Ars Technica, MacStories, 9to5Mac.
Angle: "iOS app uses adversarial AI research to protect users from AI transcription surveillance."
Timing: Coordinate with Product Hunt launch for maximum coverage momentum.

One quality press article in a Tier 1 tech publication delivers more AI Visibility score improvement than any other single action after launch.

---

## 90-Day AI Visibility Forecast

| Milestone | Estimated AI Visibility Score |
|---|---|
| Current (pre-launch) | 32/100 |
| Launch day (website + llms.txt + App Store) | 42-45/100 |
| +30 days (Product Hunt + social + first reviews) | 48-54/100 |
| +60 days (press coverage + FAQ content live) | 55-62/100 |
| +90 days (community mentions + CTO-verified stats published) | 62-68/100 |

Target: 65/100 ("Good") by 90 days post-launch. This is achievable with consistent execution of the actions above.
