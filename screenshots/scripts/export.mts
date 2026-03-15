/**
 * Nexus Shield — Autonomous App Store Screenshot Generator
 * Uses satori (JSX→SVG) + @resvg/resvg-js (SVG→PNG) — no browser needed.
 * Run: bun run export
 * Output: screenshots-output/01-hero-1320x2868.png ... 06-more-1320x2868.png
 */

import satori from "satori";
import { Resvg } from "@resvg/resvg-js";
import { readFile, writeFile, mkdir } from "fs/promises";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import React from "react";

const __filename = fileURLToPath(import.meta.url);
const __dir = dirname(__filename);
const ROOT = resolve(__dir, "..");
const OUT = resolve(ROOT, "screenshots-output");

// ─── Canvas ───────────────────────────────────────────────────────────────────
const W = 1320;
const H = 2868;

// ─── Brand tokens ─────────────────────────────────────────────────────────────
const B = {
  darkBg: "#0D0D14",
  tier1: "#3BC4D6",
  tier2: "#9B79D9",
  blue: "#007AFF",
  white: "#FFFFFF",
  offWhite: "#F2F2F7",
  card: "#1C1C1E",
  green: "#30D158",
  muted: "rgba(255,255,255,0.45)",
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
const px = (n: number) => `${n}px`;
const f = (size: number, weight: 400 | 600 | 700 | 800 = 400) => ({
  fontSize: size,
  fontWeight: weight,
  fontFamily: "Sans",
});

// Satori flex container shortcut
function row(
  children: React.ReactNode,
  style?: React.CSSProperties
): React.ReactElement {
  return React.createElement(
    "div",
    {
      style: {
        display: "flex",
        flexDirection: "row",
        alignItems: "center",
        ...style,
      },
    },
    children
  );
}

function col(
  children: React.ReactNode,
  style?: React.CSSProperties
): React.ReactElement {
  return React.createElement(
    "div",
    {
      style: {
        display: "flex",
        flexDirection: "column",
        ...style,
      },
    },
    children
  );
}

function txt(
  content: string,
  style?: React.CSSProperties
): React.ReactElement {
  return React.createElement("span", { style: { display: "flex", ...style } }, content);
}

// ─── Mock phone screen: Nexus Shield main view (active) ─────────────────────
function MockMainScreen({ width: pw, height: ph }: { width: number; height: number }) {
  const bars = [0.4, 0.7, 0.55, 0.85, 0.65, 0.9, 0.5, 0.75, 0.6, 0.8, 0.45, 0.7];
  return col(
    [
      // Status bar
      row(
        [
          txt("9:41", { ...f(pw * 0.042, 600), color: "#fff", letterSpacing: 0 }),
          row(
            [
              // Signal bars
              ...[0.4, 0.65, 0.9].map((h, i) =>
                React.createElement("div", {
                  key: i,
                  style: {
                    display: "flex",
                    width: pw * 0.018,
                    height: pw * 0.028 * h,
                    marginRight: pw * 0.006,
                    background: "#fff",
                    borderRadius: 1,
                    alignSelf: "flex-end",
                  },
                })
              ),
              // WiFi icon approximation
              React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.048,
                  height: pw * 0.036,
                  marginLeft: pw * 0.016,
                  background: "rgba(255,255,255,0.8)",
                  borderRadius: pw * 0.008,
                  justifyContent: "center",
                  alignItems: "center",
                },
              }),
              // Battery
              React.createElement("div", {
                style: {
                  display: "flex",
                  marginLeft: pw * 0.016,
                  width: pw * 0.07,
                  height: pw * 0.03,
                  borderRadius: 3,
                  border: "1.5px solid rgba(255,255,255,0.5)",
                  padding: 2,
                  alignItems: "center",
                },
              }, React.createElement("div", {
                style: {
                  display: "flex",
                  width: "82%",
                  height: "100%",
                  background: B.green,
                  borderRadius: 1,
                },
              })),
            ],
            { gap: 0, alignItems: "center" }
          ),
        ],
        {
          justifyContent: "space-between",
          padding: `${pw * 0.04}px ${pw * 0.06}px ${pw * 0.02}px`,
          width: "100%",
        }
      ),

      // Shield hero area
      col(
        [
          // Outer glow rings
          React.createElement("div", {
            style: {
              display: "flex",
              width: pw * 0.45,
              height: pw * 0.45,
              borderRadius: "50%",
              border: `${pw * 0.04}px solid rgba(0,122,255,0.08)`,
              position: "absolute",
              justifyContent: "center",
              alignItems: "center",
              left: pw * 0.5 - pw * 0.225,
            },
          }),
          React.createElement("div", {
            style: {
              display: "flex",
              width: pw * 0.39,
              height: pw * 0.39,
              borderRadius: "50%",
              border: `${pw * 0.015}px solid rgba(0,122,255,0.13)`,
              position: "absolute",
              left: pw * 0.5 - pw * 0.195,
              justifyContent: "center",
              alignItems: "center",
            },
          }),
          // Core circle
          React.createElement("div", {
            style: {
              display: "flex",
              width: pw * 0.32,
              height: pw * 0.32,
              borderRadius: "50%",
              background: B.blue,
              justifyContent: "center",
              alignItems: "center",
              boxShadow: `0 ${pw * 0.025}px ${pw * 0.07}px rgba(0,122,255,0.35)`,
              flexDirection: "column",
              gap: pw * 0.015,
            },
          }, [
            // Shield icon
            React.createElement("svg", {
              key: "shield",
              width: pw * 0.11,
              height: pw * 0.11,
              viewBox: "0 0 24 24",
              fill: "white",
            }, React.createElement("path", {
              d: "M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z",
            })),
            // Mini waveform
            row(
              bars.map((h, i) =>
                React.createElement("div", {
                  key: i,
                  style: {
                    display: "flex",
                    width: pw * 0.012,
                    height: pw * 0.045 * h,
                    marginRight: pw * 0.005,
                    background: "rgba(255,255,255,0.7)",
                    borderRadius: 2,
                  },
                })
              ),
              { alignItems: "center", gap: 0 }
            ),
          ]),
        ],
        {
          alignItems: "center",
          justifyContent: "center",
          height: pw * 0.58,
          position: "relative",
        }
      ),

      // Status label
      col(
        [
          txt("Protecting your voice", { ...f(pw * 0.046, 600), color: B.blue }),
          row(
            [
              React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.02,
                  height: pw * 0.02,
                  borderRadius: "50%",
                  background: B.green,
                  marginRight: pw * 0.015,
                },
              }),
              txt("2 techniques active", { ...f(pw * 0.036), color: "rgba(255,255,255,0.6)" }),
            ],
            { marginTop: pw * 0.02, alignItems: "center" }
          ),
          // Jam badge
          row(
            [
              txt("87% AI jammed", {
                ...f(pw * 0.036, 600),
                color: B.tier1,
                fontVariantNumeric: "tabular-nums",
              }),
            ],
            {
              marginTop: pw * 0.022,
              padding: `${pw * 0.016}px ${pw * 0.036}px`,
              background: "rgba(59,196,214,0.1)",
              borderRadius: 999,
              border: `1px solid rgba(59,196,214,0.25)`,
            }
          ),
        ],
        { alignItems: "center", padding: `0 ${pw * 0.06}px`, gap: 0 }
      ),

      // Tier row
      row(
        [
          // Tier 1
          row(
            [
              React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.07,
                  height: pw * 0.07,
                  borderRadius: "50%",
                  background: `rgba(59,196,214,0.12)`,
                  justifyContent: "center",
                  alignItems: "center",
                },
              }, React.createElement("div", {
                style: { display: "flex", width: pw * 0.035, height: pw * 0.035, background: B.tier1, borderRadius: 2 },
              })),
              col(
                [
                  txt("Acoustic", { ...f(pw * 0.036, 600), color: "#fff" }),
                  txt("Tier 1", { ...f(pw * 0.028), color: "rgba(255,255,255,0.4)" }),
                ],
                { marginLeft: pw * 0.025, gap: 0 }
              ),
              React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.02,
                  height: pw * 0.02,
                  borderRadius: "50%",
                  background: B.tier1,
                  marginLeft: "auto",
                },
              }),
            ],
            {
              flex: 1,
              background: "rgba(255,255,255,0.05)",
              borderRadius: pw * 0.035,
              padding: `${pw * 0.03}px ${pw * 0.035}px`,
              border: `1px solid rgba(59,196,214,0.2)`,
              alignItems: "center",
            }
          ),
          React.createElement("div", { style: { display: "flex", width: pw * 0.025 } }),
          // Tier 2
          row(
            [
              React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.07,
                  height: pw * 0.07,
                  borderRadius: "50%",
                  background: `rgba(155,121,217,0.12)`,
                  justifyContent: "center",
                  alignItems: "center",
                },
              }, React.createElement("div", {
                style: { display: "flex", width: pw * 0.035, height: pw * 0.035, background: B.tier2, borderRadius: 2 },
              })),
              col(
                [
                  txt("Adversarial", { ...f(pw * 0.036, 600), color: "#fff" }),
                  txt("Tier 2", { ...f(pw * 0.028), color: "rgba(255,255,255,0.4)" }),
                ],
                { marginLeft: pw * 0.025, gap: 0 }
              ),
              React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.02,
                  height: pw * 0.02,
                  borderRadius: "50%",
                  background: B.tier2,
                  marginLeft: "auto",
                },
              }),
            ],
            {
              flex: 1,
              background: "rgba(255,255,255,0.05)",
              borderRadius: pw * 0.035,
              padding: `${pw * 0.03}px ${pw * 0.035}px`,
              border: `1px solid rgba(155,121,217,0.2)`,
              alignItems: "center",
            }
          ),
        ],
        {
          padding: `${pw * 0.04}px ${pw * 0.06}px`,
          marginTop: pw * 0.05,
          width: "100%",
        }
      ),

      // Spectrum mini
      col(
        [
          row(
            [
              txt("Spectrum", { ...f(pw * 0.038, 600), color: "#fff" }),
              row(
                [
                  React.createElement("div", {
                    style: {
                      display: "flex",
                      width: pw * 0.016,
                      height: pw * 0.016,
                      borderRadius: "50%",
                      background: B.green,
                      marginRight: pw * 0.012,
                    },
                  }),
                  txt("Live", { ...f(pw * 0.03, 600), color: B.green }),
                ],
                { alignItems: "center" }
              ),
            ],
            { justifyContent: "space-between", width: "100%", marginBottom: pw * 0.03 }
          ),
          // Spectrum bars
          row(
            bars.concat([0.55, 0.7, 0.4, 0.65]).map((h, i) =>
              React.createElement("div", {
                key: i,
                style: {
                  display: "flex",
                  flex: 1,
                  height: pw * 0.12 * h,
                  background: i < 8 ? B.tier1 : B.tier2,
                  opacity: 0.7 + h * 0.3,
                  borderRadius: 2,
                  marginRight: pw * 0.006,
                  alignSelf: "flex-end",
                },
              })
            ),
            { alignItems: "flex-end", height: pw * 0.12, width: "100%" }
          ),
        ],
        {
          background: "rgba(255,255,255,0.04)",
          borderRadius: pw * 0.04,
          padding: `${pw * 0.04}px ${pw * 0.045}px`,
          margin: `${pw * 0.02}px ${pw * 0.06}px 0`,
          border: "1px solid rgba(255,255,255,0.07)",
        }
      ),

      // Tab bar
      React.createElement("div", { style: { display: "flex", flex: 1 } }),
      row(
        ["Shield", "Settings", "Routing", "Diag", "Account"].map((label, i) =>
          col(
            [
              React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.055,
                  height: pw * 0.055,
                  borderRadius: pw * 0.012,
                  background: i === 0 ? `rgba(0,122,255,0.15)` : "transparent",
                  justifyContent: "center",
                  alignItems: "center",
                  marginBottom: pw * 0.012,
                },
              }, React.createElement("div", {
                style: {
                  display: "flex",
                  width: pw * 0.035,
                  height: pw * 0.035,
                  background: i === 0 ? B.blue : "rgba(255,255,255,0.25)",
                  borderRadius: 4,
                },
              })),
              txt(label, {
                ...f(pw * 0.028),
                color: i === 0 ? B.blue : "rgba(255,255,255,0.3)",
              }),
            ],
            { alignItems: "center", flex: 1, gap: 0 }
          )
        ),
        {
          background: "rgba(20,20,28,0.95)",
          borderTop: "0.5px solid rgba(255,255,255,0.08)",
          padding: `${pw * 0.025}px 0 ${pw * 0.05}px`,
          width: "100%",
        }
      ),
    ],
    {
      width: pw,
      height: ph,
      background: B.darkBg,
      overflow: "hidden",
    }
  );
}

// ─── Phone frame wrapper ────────────────────────────────────────────────────
// Renders a stylized iPhone 16 Pro shell with the screen content inside
function PhoneFrame({
  children,
  width: fw,
  height: fh,
}: {
  children: React.ReactElement;
  width: number;
  height: number;
}) {
  const border = fw * 0.028;
  const radius = fw * 0.12;
  const screenW = fw - border * 2;
  const screenH = fh - border * 2;

  return React.createElement(
    "div",
    {
      style: {
        display: "flex",
        width: fw,
        height: fh,
        borderRadius: radius,
        background: "#1A1A1A",
        boxShadow: `0 0 0 ${fw * 0.006}px #2A2A2A, 0 ${fw * 0.04}px ${fw * 0.12}px rgba(0,0,0,0.7)`,
        padding: border,
        position: "relative",
        overflow: "hidden",
      },
    },
    [
      // Screen content
      React.createElement(
        "div",
        {
          key: "screen",
          style: {
            display: "flex",
            width: screenW,
            height: screenH,
            borderRadius: radius - border,
            overflow: "hidden",
            position: "relative",
          },
        },
        children
      ),
      // Dynamic island
      React.createElement("div", {
        key: "island",
        style: {
          display: "flex",
          position: "absolute",
          top: border + fw * 0.025,
          left: fw / 2 - fw * 0.12,
          width: fw * 0.24,
          height: fw * 0.045,
          borderRadius: 999,
          background: "#000",
        },
      }),
    ]
  );
}

// ─── Slide 1: Hero ──────────────────────────────────────────────────────────
function slide1(): React.ReactElement {
  const phoneW = W * 0.52;
  const phoneH = phoneW * 2.17;

  return col(
    [
      // Background gradient approximation (solid)
      // App badge top-left
      row(
        [
          React.createElement("div", {
            style: {
              display: "flex",
              width: W * 0.065,
              height: W * 0.065,
              borderRadius: W * 0.014,
              background: B.blue,
              justifyContent: "center",
              alignItems: "center",
            },
          }, React.createElement("svg", {
            width: W * 0.038,
            height: W * 0.038,
            viewBox: "0 0 24 24",
            fill: "white",
          }, React.createElement("path", { d: "M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z" }))),
          txt("Nexus Shield", { ...f(W * 0.036, 600), color: B.white, marginLeft: W * 0.022 }),
        ],
        { padding: `${H * 0.055}px ${W * 0.08}px ${H * 0.03}px` }
      ),

      // Headline
      col(
        [
          txt("VOICE PRIVACY", { ...f(W * 0.026, 600), color: B.tier1, letterSpacing: "0.08em" }),
          col(
            [
              txt("Your voice.", { ...f(W * 0.088, 800), color: B.white, lineHeight: 0.95 }),
              txt("Your rules.", { ...f(W * 0.088, 800), color: B.white, lineHeight: 0.95 }),
            ],
            { marginTop: W * 0.016, gap: W * 0.008 }
          ),
          txt("Defeats AI transcription — invisibly.", {
            ...f(W * 0.036),
            color: "rgba(255,255,255,0.5)",
            marginTop: W * 0.024,
          }),
        ],
        { padding: `0 ${W * 0.08}px`, marginTop: H * 0.04 }
      ),

      // Phone centered
      row(
        [
          React.createElement(
            PhoneFrame,
            { width: phoneW, height: phoneH },
            MockMainScreen({ width: phoneW - phoneW * 0.056, height: phoneH - phoneW * 0.056 })
          ),
        ],
        {
          justifyContent: "center",
          marginTop: H * 0.055,
          flex: 1,
          alignItems: "flex-start",
          overflow: "hidden",
        }
      ),
    ],
    {
      width: W,
      height: H,
      background: B.darkBg,
      overflow: "hidden",
    }
  );
}

// ─── Slide 2: Proof — ASR score ─────────────────────────────────────────────
function slide2(): React.ReactElement {
  const phoneW = W * 0.5;
  const phoneH = phoneW * 2.17;

  return col(
    [
      // Score card
      col(
        [
          txt("AI JAMMING SCORE", { ...f(W * 0.026, 600), color: B.tier1, letterSpacing: "0.08em" }),
          row(
            [
              txt("87", { ...f(W * 0.2, 800), color: B.tier1, lineHeight: 1, letterSpacing: "-0.04em" }),
              txt("%", { ...f(W * 0.075, 700), color: "rgba(59,196,214,0.6)", marginLeft: W * 0.015, alignSelf: "flex-end", marginBottom: W * 0.02 }),
            ],
            { alignItems: "flex-end", marginTop: W * 0.018 }
          ),
          // Progress bar
          React.createElement("div", {
            style: {
              display: "flex",
              width: "100%",
              height: W * 0.013,
              background: "rgba(255,255,255,0.08)",
              borderRadius: 999,
              overflow: "hidden",
              marginTop: W * 0.02,
            },
          }, React.createElement("div", {
            style: {
              display: "flex",
              width: "87%",
              height: "100%",
              background: `linear-gradient(90deg, ${B.tier1}, ${B.blue})`,
              borderRadius: 999,
            },
          })),
          txt("Whisper recognition degraded", {
            ...f(W * 0.03),
            color: "rgba(255,255,255,0.4)",
            marginTop: W * 0.02,
          }),
        ],
        {
          background: "rgba(255,255,255,0.04)",
          border: "1px solid rgba(255,255,255,0.1)",
          borderRadius: W * 0.042,
          padding: `${W * 0.055}px ${W * 0.07}px`,
          margin: `${H * 0.065}px ${W * 0.08}px 0`,
        }
      ),

      // Headline
      col(
        [
          txt("LIVE PROOF", { ...f(W * 0.026, 600), color: B.tier1, letterSpacing: "0.08em", marginBottom: W * 0.016 }),
          txt("AI can't", { ...f(W * 0.088, 800), color: B.white, lineHeight: 0.95 }),
          txt("hear you.", { ...f(W * 0.088, 800), color: B.white, lineHeight: 0.95, marginTop: W * 0.008 }),
        ],
        { padding: `${H * 0.04}px ${W * 0.08}px 0` }
      ),

      // Phone — right offset
      row(
        [
          React.createElement("div", { style: { display: "flex", flex: 1 } }),
          React.createElement(
            PhoneFrame,
            { width: phoneW, height: phoneH },
            MockMainScreen({ width: phoneW - phoneW * 0.056, height: phoneH - phoneW * 0.056 })
          ),
        ],
        {
          marginTop: H * 0.045,
          flex: 1,
          alignItems: "flex-start",
          overflow: "hidden",
          paddingRight: -W * 0.02,
        }
      ),
    ],
    { width: W, height: H, background: B.darkBg, overflow: "hidden" }
  );
}

// ─── Slide 3: Two-Tier (light) ───────────────────────────────────────────────
function slide3(): React.ReactElement {
  const phoneW = W * 0.5;
  const phoneH = phoneW * 2.17;

  const tierCard = (
    title: string,
    sub: string,
    color: string
  ) =>
    row(
      [
        React.createElement("div", {
          style: {
            display: "flex",
            width: W * 0.08,
            height: W * 0.08,
            borderRadius: W * 0.018,
            background: `${color}18`,
            justifyContent: "center",
            alignItems: "center",
            flexShrink: 0,
          },
        }, React.createElement("div", {
          style: {
            display: "flex",
            width: W * 0.042,
            height: W * 0.042,
            background: color,
            borderRadius: 4,
          },
        })),
        col(
          [
            txt(title, { ...f(W * 0.036, 700), color: "#111" }),
            txt(sub, { ...f(W * 0.028), color: "#666", marginTop: W * 0.008 }),
          ],
          { marginLeft: W * 0.03 }
        ),
        React.createElement("div", {
          style: {
            display: "flex",
            width: W * 0.02,
            height: W * 0.02,
            borderRadius: "50%",
            background: color,
            marginLeft: "auto",
          },
        }),
      ],
      {
        background: "#fff",
        borderRadius: W * 0.032,
        padding: `${W * 0.032}px ${W * 0.04}px`,
        boxShadow: `0 4px 24px ${color}26, 0 1px 4px rgba(0,0,0,0.06)`,
        alignItems: "center",
      }
    );

  return col(
    [
      // Tier cards
      col(
        [
          tierCard("Acoustic Layer", "Psychoacoustic masking · 300–4kHz", B.tier1),
          React.createElement("div", { style: { display: "flex", height: W * 0.022 } }),
          tierCard("Adversarial AI", "Universal perturbations · Whisper & more", B.tier2),
        ],
        { padding: `${H * 0.065}px ${W * 0.08}px 0` }
      ),

      // Headline
      col(
        [
          txt("TWO-LAYER SHIELD", { ...f(W * 0.026, 600), color: B.blue, letterSpacing: "0.08em", marginBottom: W * 0.016 }),
          txt("Two layers.", { ...f(W * 0.088, 800), color: "#111", lineHeight: 0.95 }),
          txt("One tap.", { ...f(W * 0.088, 800), color: "#111", lineHeight: 0.95, marginTop: W * 0.008 }),
          txt("Acoustic + adversarial AI working together.", {
            ...f(W * 0.034),
            color: "rgba(0,0,0,0.45)",
            marginTop: W * 0.022,
          }),
        ],
        { padding: `${H * 0.04}px ${W * 0.08}px 0` }
      ),

      // Phone
      row(
        [
          React.createElement(
            PhoneFrame,
            { width: phoneW, height: phoneH },
            MockMainScreen({ width: phoneW - phoneW * 0.056, height: phoneH - phoneW * 0.056 })
          ),
        ],
        {
          justifyContent: "center",
          marginTop: H * 0.045,
          flex: 1,
          alignItems: "flex-start",
          overflow: "hidden",
        }
      ),
    ],
    { width: W, height: H, background: B.offWhite, overflow: "hidden" }
  );
}

// ─── Slide 4: On-Device / No Cloud ──────────────────────────────────────────
function slide4(): React.ReactElement {
  const phoneW = W * 0.48;
  const phoneH = phoneW * 2.17;

  const statCard = (value: string, unit: string, label: string) =>
    col(
      [
        row(
          [
            txt(value, { ...f(W * 0.092, 800), color: B.white, letterSpacing: "-0.03em", lineHeight: 1 }),
            txt(unit, { ...f(W * 0.034, 600), color: B.tier1, marginLeft: W * 0.012, alignSelf: "flex-end", marginBottom: W * 0.01 }),
          ],
          { alignItems: "flex-end" }
        ),
        txt(label, { ...f(W * 0.028), color: "rgba(255,255,255,0.4)", marginTop: W * 0.01 }),
      ],
      {
        flex: 1,
        background: "rgba(255,255,255,0.05)",
        border: "1px solid rgba(255,255,255,0.1)",
        borderRadius: W * 0.038,
        padding: `${W * 0.042}px ${W * 0.046}px`,
      }
    );

  return col(
    [
      // Stat cards
      row(
        [
          statCard("0", "bytes", "sent to cloud"),
          React.createElement("div", { style: { display: "flex", width: W * 0.03 } }),
          statCard("<10", "ms", "latency"),
        ],
        { padding: `${H * 0.065}px ${W * 0.08}px 0` }
      ),

      // Headline
      col(
        [
          txt("100% ON-DEVICE", { ...f(W * 0.026, 600), color: B.tier1, letterSpacing: "0.08em", marginBottom: W * 0.016 }),
          txt("Your voice", { ...f(W * 0.088, 800), color: B.white, lineHeight: 0.95 }),
          txt("stays yours.", { ...f(W * 0.088, 800), color: B.white, lineHeight: 0.95, marginTop: W * 0.008 }),
          txt("No cloud. No accounts. No data leaves.", {
            ...f(W * 0.034),
            color: "rgba(255,255,255,0.45)",
            marginTop: W * 0.022,
          }),
        ],
        { padding: `${H * 0.04}px ${W * 0.08}px 0` }
      ),

      // Phone left-offset
      row(
        [
          React.createElement(
            PhoneFrame,
            { width: phoneW, height: phoneH },
            MockMainScreen({ width: phoneW - phoneW * 0.056, height: phoneH - phoneW * 0.056 })
          ),
          React.createElement("div", { style: { display: "flex", flex: 1 } }),
        ],
        {
          marginTop: H * 0.045,
          flex: 1,
          alignItems: "flex-start",
          overflow: "hidden",
          paddingLeft: W * 0.025,
        }
      ),
    ],
    { width: W, height: H, background: B.darkBg, overflow: "hidden" }
  );
}

// ─── Slide 5: Live Spectrum ──────────────────────────────────────────────────
function slide5(): React.ReactElement {
  const phoneW = W * 0.48;
  const phoneH = phoneW * 2.17;
  const specBars = Array.from({ length: 36 }, (_, i) => {
    const x = i / 36;
    const h = Math.max(0.08, Math.sin(x * Math.PI * 2.5) * 0.45 + 0.35 + ((i * 7919) % 13) * 0.022);
    return { h, color: x < 0.45 ? B.tier1 : B.tier2 };
  });

  return col(
    [
      // Spectrum card
      col(
        [
          row(
            [
              txt("Live Spectrum", { ...f(W * 0.03, 600), color: "#111" }),
              row(
                [
                  React.createElement("div", {
                    style: {
                      display: "flex",
                      width: W * 0.016,
                      height: W * 0.016,
                      borderRadius: "50%",
                      background: "#00C48C",
                      marginRight: W * 0.012,
                    },
                  }),
                  txt("LIVE", { ...f(W * 0.024, 600), color: "#00C48C" }),
                ],
                { alignItems: "center" }
              ),
            ],
            { justifyContent: "space-between", width: "100%", marginBottom: W * 0.035 }
          ),
          // Bars
          row(
            specBars.map((bar, i) =>
              React.createElement("div", {
                key: i,
                style: {
                  display: "flex",
                  flex: 1,
                  height: W * 0.17 * bar.h,
                  background: bar.color,
                  opacity: 0.6 + bar.h * 0.4,
                  borderRadius: 3,
                  alignSelf: "flex-end",
                  marginRight: W * 0.004,
                },
              })
            ),
            { height: W * 0.17, alignItems: "flex-end", width: "100%" }
          ),
          // Freq labels
          row(
            [
              txt("100 Hz", { ...f(W * 0.022), color: "#999" }),
              txt("1 kHz", { ...f(W * 0.022), color: "#999" }),
              txt("4 kHz", { ...f(W * 0.022), color: "#999" }),
              txt("20 kHz", { ...f(W * 0.022), color: "#999" }),
            ],
            { justifyContent: "space-between", marginTop: W * 0.018, width: "100%" }
          ),
        ],
        {
          background: "#fff",
          borderRadius: W * 0.04,
          padding: `${W * 0.045}px ${W * 0.05}px`,
          margin: `${H * 0.065}px ${W * 0.06}px 0`,
          boxShadow: "0 4px 32px rgba(0,0,0,0.08)",
        }
      ),

      // Headline
      col(
        [
          txt("REAL-TIME PROOF", { ...f(W * 0.026, 600), color: B.tier2, letterSpacing: "0.08em", marginBottom: W * 0.016 }),
          txt("Know it's", { ...f(W * 0.088, 800), color: "#111", lineHeight: 0.95 }),
          txt("working.", { ...f(W * 0.088, 800), color: "#111", lineHeight: 0.95, marginTop: W * 0.008 }),
          txt("Live spectrum + latency + AI jam score.", {
            ...f(W * 0.034),
            color: "rgba(0,0,0,0.45)",
            marginTop: W * 0.022,
          }),
        ],
        { padding: `${H * 0.038}px ${W * 0.08}px 0` }
      ),

      // Phone right
      row(
        [
          React.createElement("div", { style: { display: "flex", flex: 1 } }),
          React.createElement(
            PhoneFrame,
            { width: phoneW, height: phoneH },
            MockMainScreen({ width: phoneW - phoneW * 0.056, height: phoneH - phoneW * 0.056 })
          ),
        ],
        {
          marginTop: H * 0.038,
          flex: 1,
          alignItems: "flex-start",
          overflow: "hidden",
        }
      ),
    ],
    { width: W, height: H, background: B.offWhite, overflow: "hidden" }
  );
}

// ─── Slide 6: More features ──────────────────────────────────────────────────
function slide6(): React.ReactElement {
  const features = [
    { label: "Bluetooth HQ Recording", color: B.tier1 },
    { label: "AirPods Pro Support", color: B.tier1 },
    { label: "VoIP Mode", color: B.tier2 },
    { label: "Session History", color: B.tier2 },
    { label: "Background Shield", color: B.green },
    { label: "Siri Shortcuts", color: B.blue },
  ];
  const coming = ["Live Activity", "Widget", "Android"];

  const pill = (label: string, color: string, ghost = false) =>
    row(
      [txt(label, { ...f(W * 0.03, 600), color: ghost ? "rgba(255,255,255,0.25)" : color })],
      {
        padding: `${W * 0.015}px ${W * 0.034}px`,
        borderRadius: 999,
        background: ghost ? "transparent" : `${color}20`,
        border: `1.5px solid ${ghost ? "rgba(255,255,255,0.1)" : `${color}50`}`,
        margin: `0 ${W * 0.01}px ${W * 0.018}px 0`,
      }
    );

  return col(
    [
      // App icon
      React.createElement("div", {
        style: {
          display: "flex",
          width: W * 0.2,
          height: W * 0.2,
          borderRadius: W * 0.045,
          background: `linear-gradient(135deg, ${B.blue}, ${B.tier2})`,
          justifyContent: "center",
          alignItems: "center",
          marginBottom: W * 0.045,
          boxShadow: `0 0 ${W * 0.07}px ${B.blue}44`,
        },
      }, React.createElement("svg", {
        width: W * 0.11,
        height: W * 0.11,
        viewBox: "0 0 24 24",
        fill: "white",
      }, React.createElement("path", { d: "M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z" }))),

      txt("And so much more.", { ...f(W * 0.075, 800), color: B.white, lineHeight: 1, textAlign: "center" }),
      txt("Everything you need to protect your voice.", {
        ...f(W * 0.032),
        color: "rgba(255,255,255,0.4)",
        marginTop: W * 0.018,
        textAlign: "center",
      }),

      // Feature pills
      React.createElement("div", {
        style: {
          display: "flex",
          flexWrap: "wrap",
          justifyContent: "center",
          marginTop: W * 0.06,
          width: W * 0.84,
        },
      }, features.map((f_) => pill(f_.label, f_.color))),

      // Coming soon
      txt("COMING SOON", {
        ...f(W * 0.024, 600),
        color: "rgba(255,255,255,0.25)",
        letterSpacing: "0.08em",
        marginTop: W * 0.04,
        marginBottom: W * 0.02,
      }),

      React.createElement("div", {
        style: {
          display: "flex",
          flexWrap: "wrap",
          justifyContent: "center",
        },
      }, coming.map((c) => pill(c, B.white, true))),
    ],
    {
      width: W,
      height: H,
      background: B.darkBg,
      overflow: "hidden",
      alignItems: "center",
      justifyContent: "center",
      padding: `0 ${W * 0.08}px`,
    }
  );
}

// ─── Render + save ───────────────────────────────────────────────────────────
const SLIDES = [
  { id: "01-hero", fn: slide1 },
  { id: "02-ai-jammed", fn: slide2 },
  { id: "03-two-tiers", fn: slide3 },
  { id: "04-on-device", fn: slide4 },
  { id: "05-live-metrics", fn: slide5 },
  { id: "06-more", fn: slide6 },
];

async function renderSlide(
  slideEl: React.ReactElement,
  fonts: { name: string; data: ArrayBuffer; weight: number; style: "normal" }[]
): Promise<Buffer> {
  const svg = await satori(slideEl, {
    width: W,
    height: H,
    fonts,
    // embedFont: true,
  });

  const resvg = new Resvg(svg, {
    fitTo: { mode: "width", value: W },
    font: { loadSystemFonts: false },
  });
  const rendered = resvg.render();
  return Buffer.from(rendered.asPng());
}

async function main() {
  await mkdir(OUT, { recursive: true });

  // Load fonts
  const fontPaths = [
    {
      path: "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
      weight: 400,
    },
    {
      path: "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
      weight: 700,
    },
  ];

  const fonts = await Promise.all(
    fontPaths.map(async ({ path, weight }) => ({
      name: "Sans",
      data: (await readFile(path)).buffer as ArrayBuffer,
      weight: weight as 400 | 700,
      style: "normal" as const,
    }))
  );

  // Also add bold-italic for weight 800 (map to bold)
  fonts.push({
    name: "Sans",
    data: fonts[1].data,
    weight: 800,
    style: "normal",
  });
  fonts.push({
    name: "Sans",
    data: fonts[0].data,
    weight: 600,
    style: "normal",
  });

  console.log(`\n🎨 Nexus Shield — Generating ${SLIDES.length} App Store screenshots...\n`);

  for (const slide of SLIDES) {
    const el = slide.fn();
    const png = await renderSlide(el, fonts);
    const outPath = `${OUT}/${slide.id}-${W}x${H}.png`;
    await writeFile(outPath, png);
    const kb = Math.round(png.byteLength / 1024);
    console.log(`  ✓ ${slide.id}-${W}x${H}.png  (${kb} KB)`);
  }

  console.log(`\n✅ Done! Screenshots saved to: screenshots-output/\n`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
