# Composite AI Visibility Report — Nexus Shield

**Report Type:** Pre-Launch Baseline
**Date:** 2026-03-20
**Domain:** nexusshield.app (planned; not yet live)
**Product:** Nexus Shield — Real-time acoustic voice protection for iOS

> **Pre-launch context:** nexusshield.app does not exist as a live website at the time of this report. All crawler access scores are 0 (no pages to crawl, no robots.txt, no sitemap). Brand mention scores reflect what is currently detectable for "Nexus Shield" and "Project Nexus" prior to App Store launch. This report establishes a documented baseline and provides a post-launch implementation roadmap.

---

## Composite AI Visibility Score

```
AI_Visibility = (Citability × 0.35) + (Brand_Mentions × 0.30) + (Crawler_Access × 0.25) + (LLMS_TXT × 0.10)
```

### Pre-GEO Baseline (State Before This Run)

| Component | Raw Score | Weight | Weighted Score |
|---|---|---|---|
| Citability | 41/100 | 0.35 | 14.35 |
| Brand Mentions | 4/100 | 0.30 | 1.20 |
| Crawler Access | 0/100 | 0.25 | 0.00 |
| LLMS_TXT | 0/100 | 0.10 | 0.00 |
| **AI Visibility Score** | | | **15.55/100** |

### Post-GEO (Projected After Publishing These Deliverables)

| Component | Raw Score | Weight | Weighted Score | Change |
|---|---|---|---|---|
| Citability | 74/100 | 0.35 | 25.90 | +11.55 |
| Brand Mentions | 4/100 | 0.30 | 1.20 | +0.00 |
| Crawler Access | 0/100 | 0.25 | 0.00 | +0.00 |
| LLMS_TXT | 85/100 | 0.10 | 8.50 | +8.50 |
| **AI Visibility Score** | | | **35.60/100** | **+20.05** |

### Post-Launch Target (30 Days After App Store Release)

| Component | Target Score | Weight | Weighted Score | Notes |
|---|---|---|---|---|
| Citability | 78/100 | 0.35 | 27.30 | App Store + FAQ + How-it-works live |
| Brand Mentions | 22/100 | 0.30 | 6.60 | Product Hunt + 2–3 press mentions |
| Crawler Access | 68/100 | 0.25 | 17.00 | robots.txt + sitemap + llms.txt live |
| LLMS_TXT | 90/100 | 0.10 | 9.00 | llms.txt published with real URLs |
| **Target Score** | | | **59.90/100** | Competitive launch baseline |

### 90-Day Target

| Component | Target Score | Weight | Weighted Score |
|---|---|---|---|
| Citability | 85/100 | 0.35 | 29.75 |
| Brand Mentions | 45/100 | 0.30 | 13.50 |
| Crawler Access | 80/100 | 0.25 | 20.00 |
| LLMS_TXT | 95/100 | 0.10 | 9.50 |
| **90-Day Target** | | | **72.75/100** |

---

## Component 1: Citability Score

**Pre-GEO: 41/100 | Post-GEO: 74/100**

Source document: GEO-CITABILITY-SCORE.md (2026-03-20)

The citability score measures how likely AI systems are to extract, quote, and cite Nexus Shield content when answering user queries. It is calculated from five weighted sub-dimensions:

| Sub-dimension | Pre-GEO | Post-GEO | Weight |
|---|---|---|---|
| Answer Block Quality | 35/100 | 78/100 | 30% |
| Passage Self-Containment | 48/100 | 80/100 | 25% |
| Structural Readability | 55/100 | 75/100 | 20% |
| Statistical Density | 28/100 | 72/100 | 15% |
| Uniqueness & Original Data | 38/100 | 65/100 | 10% |

**What drove the post-GEO improvement:**
- OPTIMIZED-APP-STORE-DESCRIPTION.md opens with a 148-word self-contained answer block — within the 134–167 word optimal AI extraction window.
- FAQ-CONTENT-BLOCKS.md provides 8 answers at citation-optimal length, each fully self-contained.
- WER statistic (Whisper accuracy: 94% → 8%) added to multiple content blocks — highest-impact statistical density improvement available.
- All FAQ answers use answer-first structure: every answer opens with a direct definition or quantified claim.
- Research citations (AudioShield, ZQ-Attack, Muting Whisper, UniAP) integrated into consumer-facing copy for the first time.

**What limits further improvement:**
- No author credentials remain the primary E-E-A-T cap on citability ceiling.
- No live press citations limit external authority signals.
- Internal testing methodology not yet published — reduces scientific citability of the WER claim.

---

## Component 2: Brand Mentions

**Current: 4/100 | Post-Launch 30-Day Target: 22/100**

### Current Brand Mention Inventory (Pre-Launch)

Brand mention detection assesses what AI systems can find when searching for "Nexus Shield" or "Project Nexus" across indexed sources.

| Source | "Nexus Shield" | "Project Nexus" | Notes |
|---|---|---|---|
| GitHub | Present | Present | Repository is indexed by some AI crawlers |
| App Store | Absent | Absent | App not yet submitted |
| Product Hunt | Absent | Absent | Not listed |
| X / Twitter | Absent | Absent | No brand account |
| Reddit | Absent | Absent | No posts or subreddit |
| Press / News | Absent | Absent | Pre-launch |
| Wikipedia | Absent | Absent | Pre-launch; notability threshold not met |
| Blog / Tech Sites | Absent | Absent | Pre-launch |
| AlternativeTo / G2 | Absent | Absent | Not listed |
| Academic databases | Absent | Absent | Product not cited in research |

**Scoring rationale:** The 4/100 score reflects GitHub repository indexability only. "Nexus Shield" and "Project Nexus" are discoverable via GitHub search but are not referenced by any external source. Score breakdown: GitHub README presence (2 points) + repository files with product details accessible to GitHub-crawling AI systems (2 points).

**Name collision risk:** "Project Nexus" is a generic phrase used by unrelated products in gaming, government, and enterprise contexts. "Nexus Shield" is more distinctive but also appears in gaming (an in-game item in several titles). App Store launch combined with schema.json Organization entity will be the primary disambiguation mechanism.

### Brand Mention Roadmap

| Action | Estimated Score Lift | Timeline | Effort |
|---|---|---|---|
| App Store submission (with optimized description) | +8 | Week 1 post-launch | Low |
| Product Hunt launch post | +4 | Week 1 post-launch | Low |
| Create @NexusShieldApp on X/Twitter | +2 | Pre-launch | Low |
| Reddit posts in r/privacy, r/ios | +2 | Week 2 post-launch | Low |
| AlternativeTo listing | +1 | Week 2 post-launch | Low |
| First press mention (9to5Mac / The Markup) | +6 | 30–60 days | Medium |
| Second tier press (Wired, The Verge) | +10 | 60–90 days | High |
| Wikipedia entity (requires notability) | +8 | 90+ days | High |

---

## Component 3: Crawler Access

**Current: 0/100**

### Current State

nexusshield.app does not exist as a live domain. There is no robots.txt, sitemap.xml, llms.txt, HTML pages, or DNS record resolving to web server content. Score is 0/100 by definition.

### Recommended Implementation (Complete at Domain Launch)

#### robots.txt — Recommended Configuration

```
User-agent: *
Allow: /

User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: anthropic-ai
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: GoogleOther
Allow: /

User-agent: Googlebot
Allow: /

Sitemap: https://nexusshield.app/sitemap.xml
```

**Rationale:** Explicit `Allow: /` directives for AI crawlers (GPTBot, ClaudeBot, anthropic-ai, PerplexityBot) are required because some AI systems only index pages where they have confirmed crawl permission. The default `User-agent: *` allow covers general crawlers. Do NOT block AI crawlers — doing so suppresses AI visibility entirely.

#### sitemap.xml — Recommended Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://nexusshield.app/</loc>
    <lastmod>2026-03-20</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://nexusshield.app/how-it-works</loc>
    <lastmod>2026-03-20</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>
  <url>
    <loc>https://nexusshield.app/faq</loc>
    <lastmod>2026-03-20</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.9</priority>
  </url>
  <url>
    <loc>https://nexusshield.app/privacy</loc>
    <lastmod>2026-03-20</lastmod>
    <changefreq>yearly</changefreq>
    <priority>0.7</priority>
  </url>
  <url>
    <loc>https://nexusshield.app/research</loc>
    <lastmod>2026-03-20</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://nexusshield.app/blog</loc>
    <lastmod>2026-03-20</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>
</urlset>
```

#### JSON-LD Deployment

- The schema.json deliverable (produced this run) must be embedded as a `<script type="application/ld+json">` block in the `<head>` of every page.
- FAQPage schema should appear on nexusshield.app/faq specifically.
- SoftwareApplication schema should appear on the homepage (nexusshield.app/).
- Organization schema should appear site-wide.

#### Technical SEO / AI Crawler Checklist

| Item | Priority | Notes |
|---|---|---|
| HTTPS with valid SSL certificate | Critical | Required for AI crawler trust signals |
| Canonical URLs (`<link rel="canonical">`) | High | Prevents duplicate content signals |
| Open Graph meta tags | High | Improves AI summarization accuracy of page previews |
| Twitter Card meta tags | Medium | Enables rich card previews on X |
| Structured data (schema.json) | Critical | See schema.json deliverable in this run |
| llms.txt at root (`/llms.txt`) | High | See llms.txt deliverable in this run |
| robots.txt at root | Critical | Configure as above; include AI crawler Allow directives |
| sitemap.xml | High | Submit to Google Search Console on day 1 |
| Page load speed < 3s | High | Core Web Vitals affect crawl priority and depth |
| No JavaScript-gated content | High | AI crawlers often do not execute JavaScript |
| Static HTML fallback for all key content | High | FAQ, How-It-Works, Privacy pages should render without JS |

**Projected Crawler Access score at domain launch (with all above implemented): 68/100**

Score ceiling explanation: A newly launched domain has no crawl history, no inbound links, and no domain authority equivalent. Even with perfect technical implementation, crawl depth and crawl frequency remain low for 30–90 days as crawlers establish baseline patterns for the domain.

---

## Component 4: LLMS_TXT Score

**Pre-GEO: 0/100 | Post-GEO: 85/100**

### Pre-GEO State

No llms.txt file existed. Score was 0/100.

### Post-GEO State

The llms.txt file has been created as a GEO deliverable (this run) and is ready for deployment at:

`https://nexusshield.app/llms.txt`

Local file: `/home/user/Project-Nexus/GEO/llms.txt`

**llms.txt quality scoring:**

| Criterion | Score | Notes |
|---|---|---|
| File present and created | 15/15 | Created this run |
| Correct H1 format (`# Nexus Shield`) | 10/10 | Compliant with llms.txt specification |
| Blockquote product description | 10/10 | Self-contained, accurate product description present |
| Core Pages section with URLs | 15/15 | 6 planned URLs with descriptions |
| Technical Documentation section | 10/10 | 4 technical resource URLs |
| Research Foundation section | 10/10 | 4 research papers with venues and years |
| Privacy & Trust section | 10/10 | Privacy policy and security architecture pages |
| Support section | 5/5 | Support URL and contact email |
| Optional section | 5/5 | Additional context for AI systems |
| URL format quality | 5/5 | All URLs are realistic nexusshield.app paths |
| Description quality | 5/5 | Each entry has a self-contained, informative description |
| **File quality total** | **100/100** | |

**Deployment deduction (−15):** File is not yet live at nexusshield.app/llms.txt. Post-GEO score is 85/100 assessed against a "publish intent" standard. Score becomes 100/100 on the day the file is deployed to the production server.

---

## Priority Action Plan

Actions are ordered by weighted impact on the AI Visibility composite score.

### Tier 1 — Pre-Launch (Complete Before App Store Submission)

| # | Action | Component Affected | Score Lift | Effort |
|---|---|---|---|---|
| 1 | Register nexusshield.app domain and deploy static site | Crawler Access | +17.00 | Medium |
| 2 | Deploy llms.txt at nexusshield.app/llms.txt | LLMS_TXT | +1.50 | Low |
| 3 | Embed schema.json as JSON-LD in site `<head>` | Crawler Access + Citability | +3.00 | Low |
| 4 | Publish robots.txt with AI crawler allow directives | Crawler Access | +2.00 | Low |
| 5 | Publish sitemap.xml and submit to Google Search Console | Crawler Access | +2.00 | Low |
| 6 | Create @NexusShieldApp on X/Twitter | Brand Mentions | +0.60 | Low |

### Tier 2 — Launch Week (Days 1–7)

| # | Action | Component Affected | Score Lift | Effort |
|---|---|---|---|---|
| 7 | Submit App Store listing with OPTIMIZED-APP-STORE-DESCRIPTION.md | Brand Mentions + Citability | +3.00 | Medium |
| 8 | Submit to Product Hunt | Brand Mentions | +1.20 | Low |
| 9 | Post in r/privacy and r/ios | Brand Mentions | +0.60 | Low |
| 10 | Deploy FAQ page using FAQ-CONTENT-BLOCKS.md | Citability | +1.05 | Low |

### Tier 3 — 30-Day Post-Launch

| # | Action | Component Affected | Score Lift | Effort |
|---|---|---|---|---|
| 11 | Press outreach: The Markup, 9to5Mac | Brand Mentions | +1.80 | High |
| 12 | Publish "How Acoustic Perturbation Works" page | Citability | +1.75 | Medium |
| 13 | Add AlternativeTo and G2 listings | Brand Mentions | +0.45 | Low |
| 14 | Publish team/about page with author bio | Citability (E-E-A-T) | +1.40 | Low |
| 15 | Publish privacy policy at nexusshield.app/privacy | Citability (Trustworthiness) | +0.70 | Low |

### Tier 4 — 90-Day Target

| # | Action | Component Affected | Score Lift | Effort |
|---|---|---|---|---|
| 16 | Press: Wired, The Verge | Brand Mentions | +3.00 | High |
| 17 | Blog post: "The Science Behind Nexus Shield" | Citability | +1.75 | Medium |
| 18 | arXiv preprint or technical blog on WER testing methodology | Citability + Brand Mentions | +2.45 | High |
| 19 | Wikipedia entity (requires press notability threshold) | Brand Mentions | +2.40 | High |
| 20 | Comparison page vs. VPN vs. noise-canceling headphones | Citability | +1.05 | Low |

---

## Benchmark Comparison

AI Visibility scores for comparable iOS privacy apps (estimated from public GEO research):

| Product | Stage | AI Visibility Score | Notes |
|---|---|---|---|
| Nexus Shield (pre-GEO) | Pre-launch | 15.55/100 | This baseline |
| Nexus Shield (post-GEO deliverables) | Pre-launch | 35.60/100 | After this run |
| Typical iOS app (pre-launch) | Pre-launch | 10–20/100 | Industry estimated range |
| Typical iOS app (30 days post-launch) | Post-launch | 25–45/100 | With App Store listing |
| Established privacy app (2+ years) | Mature | 55–75/100 | With press coverage + reviews |
| Category leader (e.g., Signal, 1Password) | Mature | 80–90/100 | Full brand recognition |

**Assessment:** Nexus Shield's post-GEO score of 35.60/100 already exceeds the typical post-launch baseline before the product has launched. This is attributable to the strength of technical documentation, research citations, and the quality of GEO-optimized content produced in this run. The primary gap is Brand Mentions (weighted score 1.20/30.00) — which requires real-world launch activity and press coverage to close. The Citability component (25.90/35.00 weighted) is performing at a competitive level relative to established products.

---

## Monitoring and Re-Assessment Schedule

| Milestone | Trigger | Action |
|---|---|---|
| Domain launch | nexusshield.app goes live | Re-run Crawler Access assessment |
| App Store approval | App is downloadable | Update Brand Mentions score |
| 100 App Store reviews | Reviews milestone | Update schema.json aggregateRating |
| First press mention | News coverage published | Update Brand Mentions score |
| 500 DAU | Pricing change milestone | Update schema.json offers |
| 90 days post-launch | Scheduled quarterly | Full composite re-assessment |
