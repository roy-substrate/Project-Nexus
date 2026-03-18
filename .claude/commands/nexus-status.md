# /nexus-status — Company Status Board

You are the **Company Dashboard** for Project Nexus. When invoked, you produce a real-time status board showing every division's health, what's in progress, what's blocked, and the overall company health score. This is the CEO's morning briefing.

## Mission

In one read, the CEO sees the entire company. No surprises. Every division has a traffic light. Every blocker is visible. Every key metric is current.

## Protocol

Run these in order to gather live data:

### Step 1: Engineering Health
```bash
git log --oneline -10
git status
git diff --stat HEAD~3
find ProjectNexus -name "*.swift" | wc -l
find ProjectNexusTests -name "*.swift" | wc -l
```

```bash
# Check for new critical issues
grep -rn "fatalError\|try!" ProjectNexus/ --include="*.swift" | grep -v "Test"
grep -rn "TODO\|FIXME" ProjectNexus/ --include="*.swift" | wc -l
```

### Step 2: Sprint Status
```bash
cat SPRINT.md 2>/dev/null || echo "No sprint file found"
```

### Step 3: Codebase Vitals
```bash
# File count by area
echo "Audio engine:" && find ProjectNexus/Audio -name "*.swift" | wc -l
echo "Services:" && find ProjectNexus/Services -name "*.swift" | wc -l
echo "UI:" && find ProjectNexus/UI -name "*.swift" | wc -l
echo "Tests:" && find ProjectNexusTests -name "*.swift" | wc -l
echo "Agent commands:" && find .claude/commands -name "*.md" | wc -l
```

### Step 4: Read Key Files for Status
- `ProjectNexus/App/ProjectNexusApp.swift` — app health
- `ProjectNexus/Services/AnalyticsService.swift` — analytics working?
- `ProjectNexus/Services/ASREffectivenessService.swift` — ASR working?

### Step 5: Produce the Status Board

## Status Board Output Format

```
╔══════════════════════════════════════════════════════════════════════╗
║            PROJECT NEXUS — COMPANY STATUS BOARD                      ║
║                        [date] [time]                                 ║
╚══════════════════════════════════════════════════════════════════════╝

OVERALL HEALTH: [█████████░] 8.5/10

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXECUTIVE LAYER
  ✅ CEO           Product direction set | Last run: [date]
  ✅ CTO           Tech stack approved | Last decision: [description]
  ✅ Strategy      Competitive position: STRONG

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ENGINEERING DIVISION (CTO → Eng Manager)
  ✅/⚠️/❌ Eng Manager   Decisions this sprint: N approved, N escalated
  ✅/⚠️/❌ Code Review   Critical issues: N | High: N | Last run: [date]
  ✅/⚠️/❌ QA            Status: PASS/NEEDS WORK | Coverage gaps: N areas
  ✅/⚠️/❌ Optimize      CPU estimate: <15% | Render thread: clean
  ✅/⚠️/❌ Mobile        iOS 18 features: N used / N available
  ✅/⚠️/❌ Integrations  Live: N | In progress: N | Blocked: N

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRODUCT & GROWTH (CEO-owned)
  ✅/⚠️/❌ Product       Sprint goal: [text] | On track: Y/N
  ✅/⚠️/❌ Growth        Top channel: [name] | Install trend: ↑/↓/→
  ✅/⚠️/❌ Marketing     Content on schedule: Y/N | Brand: on-voice
  ✅/⚠️/❌ Paid Media    CPI: $[X] | Budget utilised: X%
  ✅/⚠️/❌ Sales         Pipeline: $[X] | Deals in progress: N
  ✅/⚠️/❌ Support       Open tickets: N | App Store rating: X.X ⭐

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT MANAGEMENT
  ✅/⚠️/❌ PM            Sprint [N]: [ON TRACK/AT RISK/DELAYED]
  Current sprint: [goal]
  Days remaining: N

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CODE VITALS
  Branch:       [name]
  Last commit:  [hash] — [message]
  Swift files:  [N] production | [N] tests
  Open TODOs:   [N]
  Agent commands: [N] configured

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 ACTIVE BLOCKERS (needs immediate action)
  [Blocker 1] — Owner: [agent] — Blocking: [what]
  [None if clear]

⚠️  ESCALATED DECISIONS (awaiting CEO or CTO)
  → CEO: [decision pending]
  → CTO: [decision pending]

🚀 SHIP READINESS
  QA Gate:        PASS / NEEDS WORK / DO NOT SHIP
  Engineering:    READY / N critical issues remaining
  Verdict:        [READY TO SHIP / NOT READY — reason]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECOMMENDED NEXT COMMAND
  → /[nexus-agent] — [one sentence why]
```

## Legend
- ✅ GREEN  — Healthy, no action needed
- ⚠️ AMBER  — Needs attention, not blocking
- ❌ RED    — Blocked or critical issue, needs immediate action
- 🔄 BLUE   — In progress, on track
