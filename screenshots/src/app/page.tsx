"use client";

import { useEffect, useRef, useState } from "react";
import { toPng } from "html-to-image";

// ─── Canvas dimensions (design at largest, scale down for export) ───────────
const IPHONE_W = 1320;
const IPHONE_H = 2868;

const IPHONE_SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1125, h: 2436 },
] as const;

// ─── Mockup measurements (pre-measured for included mockup.png) ──────────────
const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

// ─── Brand tokens ────────────────────────────────────────────────────────────
const BRAND = {
  darkBg: "#0D0D14",         // onboarding dark (0.05/0.05/0.08)
  tier1: "#3BC4D6",          // hsl(208°, 72%, 85%) — acoustic blue-teal
  tier2: "#9B79D9",          // hsl(263°, 56%, 80%) — adversarial indigo
  blue: "#007AFF",           // iOS system blue
  white: "#FFFFFF",
  offWhite: "#F2F2F7",       // iOS systemGroupedBackground
  cardBg: "#1C1C1E",         // dark card surface
  mutedDark: "rgba(255,255,255,0.45)",
  mutedLight: "rgba(13,13,20,0.5)",
};

// ─── Slide copy ──────────────────────────────────────────────────────────────
// Follows Iron Rules: one idea, 3-5 words/line, readable at thumbnail
const SLIDES_META = [
  { id: "hero",         label: "01 · Hero" },
  { id: "proof",        label: "02 · AI Jammed" },
  { id: "two-tier",     label: "03 · Two Tiers" },
  { id: "local",        label: "04 · On-Device" },
  { id: "live",         label: "05 · Live Metrics" },
  { id: "more",         label: "06 · More Features" },
] as const;

// ─── Phone component ─────────────────────────────────────────────────────────
function Phone({
  src,
  alt,
  style,
  className = "",
}: {
  src: string;
  alt: string;
  style?: React.CSSProperties;
  className?: string;
}) {
  return (
    <div
      className={`relative ${className}`}
      style={{ aspectRatio: `${MK_W}/${MK_H}`, ...style }}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src="/mockup.png"
        alt=""
        className="block w-full h-full"
        draggable={false}
      />
      <div
        className="absolute z-10 overflow-hidden"
        style={{
          left: `${SC_L}%`,
          top: `${SC_T}%`,
          width: `${SC_W}%`,
          height: `${SC_H}%`,
          borderRadius: `${SC_RX}% / ${SC_RY}%`,
          background: "#111",
        }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={src}
          alt={alt}
          className="block w-full h-full object-cover object-top"
          draggable={false}
          onError={(e) => {
            // Graceful placeholder when screenshot not yet provided
            (e.target as HTMLImageElement).style.display = "none";
          }}
        />
      </div>
    </div>
  );
}

// ─── Glow blob ───────────────────────────────────────────────────────────────
function Glow({
  color,
  size,
  top,
  left,
  opacity = 0.35,
}: {
  color: string;
  size: number;
  top: string;
  left: string;
  opacity?: number;
}) {
  return (
    <div
      style={{
        position: "absolute",
        top,
        left,
        width: size,
        height: size,
        borderRadius: "50%",
        background: color,
        filter: `blur(${size * 0.45}px)`,
        opacity,
        transform: "translate(-50%, -50%)",
        pointerEvents: "none",
      }}
    />
  );
}

// ─── Caption ─────────────────────────────────────────────────────────────────
function Caption({
  label,
  headline,
  sub,
  labelColor = BRAND.tier1,
  textColor = BRAND.white,
  canvasW = IPHONE_W,
  align = "left",
}: {
  label: string;
  headline: React.ReactNode;
  sub?: string;
  labelColor?: string;
  textColor?: string;
  canvasW?: number;
  align?: "left" | "center";
}) {
  return (
    <div style={{ textAlign: align }}>
      <div
        style={{
          fontSize: canvasW * 0.028,
          fontWeight: 600,
          letterSpacing: "0.08em",
          textTransform: "uppercase" as const,
          color: labelColor,
          marginBottom: canvasW * 0.018,
          fontFamily: "Inter, system-ui, sans-serif",
        }}
      >
        {label}
      </div>
      <div
        style={{
          fontSize: canvasW * 0.092,
          fontWeight: 800,
          lineHeight: 0.95,
          color: textColor,
          fontFamily: "Inter, system-ui, sans-serif",
        }}
      >
        {headline}
      </div>
      {sub && (
        <div
          style={{
            fontSize: canvasW * 0.038,
            fontWeight: 400,
            lineHeight: 1.4,
            color: "rgba(255,255,255,0.55)",
            marginTop: canvasW * 0.025,
            fontFamily: "Inter, system-ui, sans-serif",
          }}
        >
          {sub}
        </div>
      )}
    </div>
  );
}

// ─── Pill badge ──────────────────────────────────────────────────────────────
function Pill({
  label,
  color,
  canvasW,
}: {
  label: string;
  color: string;
  canvasW: number;
}) {
  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: canvasW * 0.012,
        padding: `${canvasW * 0.016}px ${canvasW * 0.036}px`,
        borderRadius: 999,
        background: `${color}22`,
        border: `1.5px solid ${color}55`,
        fontSize: canvasW * 0.032,
        fontWeight: 600,
        color,
        fontFamily: "Inter, system-ui, sans-serif",
        whiteSpace: "nowrap" as const,
      }}
    >
      {label}
    </div>
  );
}

// ─── SLIDE 1: Hero ───────────────────────────────────────────────────────────
function Slide1Hero({ W, H, screenshotSrc }: { W: number; H: number; screenshotSrc: string }) {
  return (
    <div
      style={{
        width: W,
        height: H,
        background: BRAND.darkBg,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, sans-serif",
      }}
    >
      {/* Background glows */}
      <Glow color={BRAND.blue} size={W * 1.1} top="20%" left="50%" opacity={0.18} />
      <Glow color={BRAND.tier2} size={W * 0.7} top="75%" left="75%" opacity={0.22} />

      {/* App badge */}
      <div
        style={{
          position: "absolute",
          top: H * 0.065,
          left: W * 0.08,
          display: "flex",
          alignItems: "center",
          gap: W * 0.022,
        }}
      >
        <div
          style={{
            width: W * 0.07,
            height: W * 0.07,
            borderRadius: W * 0.016,
            background: BRAND.blue,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <svg
            width={W * 0.04}
            height={W * 0.04}
            viewBox="0 0 24 24"
            fill="white"
          >
            <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z" />
          </svg>
        </div>
        <span
          style={{
            fontSize: W * 0.038,
            fontWeight: 600,
            color: BRAND.white,
            letterSpacing: "-0.01em",
          }}
        >
          Nexus Shield
        </span>
      </div>

      {/* Headline */}
      <div
        style={{
          position: "absolute",
          bottom: H * 0.38,
          left: W * 0.08,
          right: W * 0.08,
        }}
      >
        <Caption
          label="Voice Privacy"
          headline={
            <>
              Your voice.
              <br />
              Your rules.
            </>
          }
          sub="Defeats AI transcription — invisibly."
          canvasW={W}
        />
      </div>

      {/* Phone — centered, bleeding off bottom */}
      <Phone
        src={screenshotSrc}
        alt="Nexus Shield main screen"
        style={{
          position: "absolute",
          bottom: 0,
          left: "50%",
          width: W * 0.84,
          transform: "translateX(-50%) translateY(12%)",
        }}
      />
    </div>
  );
}

// ─── SLIDE 2: Proof — ASR jam score ─────────────────────────────────────────
function Slide2Proof({ W, H, screenshotSrc }: { W: number; H: number; screenshotSrc: string }) {
  return (
    <div
      style={{
        width: W,
        height: H,
        background: BRAND.darkBg,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, sans-serif",
      }}
    >
      <Glow color={BRAND.tier1} size={W * 0.9} top="65%" left="30%" opacity={0.2} />
      <Glow color={BRAND.tier2} size={W * 0.6} top="30%" left="80%" opacity={0.18} />

      {/* Score card overlay — the viral hero element */}
      <div
        style={{
          position: "absolute",
          top: H * 0.065,
          left: W * 0.08,
          right: W * 0.08,
          background: "rgba(255,255,255,0.04)",
          border: `1px solid rgba(255,255,255,0.1)`,
          borderRadius: W * 0.045,
          padding: `${W * 0.06}px ${W * 0.08}px`,
        }}
      >
        <div
          style={{
            fontSize: W * 0.028,
            fontWeight: 600,
            letterSpacing: "0.08em",
            textTransform: "uppercase" as const,
            color: BRAND.tier1,
            marginBottom: W * 0.02,
          }}
        >
          AI Jamming Score
        </div>
        <div style={{ display: "flex", alignItems: "baseline", gap: W * 0.02 }}>
          <span
            style={{
              fontSize: W * 0.22,
              fontWeight: 800,
              lineHeight: 1,
              color: BRAND.tier1,
              letterSpacing: "-0.04em",
            }}
          >
            87
          </span>
          <span
            style={{
              fontSize: W * 0.08,
              fontWeight: 700,
              color: "rgba(59,196,214,0.6)",
            }}
          >
            %
          </span>
        </div>
        {/* Progress bar */}
        <div
          style={{
            height: W * 0.014,
            background: "rgba(255,255,255,0.08)",
            borderRadius: 999,
            overflow: "hidden",
            marginTop: W * 0.025,
          }}
        >
          <div
            style={{
              width: "87%",
              height: "100%",
              background: `linear-gradient(90deg, ${BRAND.tier1}, ${BRAND.blue})`,
              borderRadius: 999,
            }}
          />
        </div>
        <div
          style={{
            fontSize: W * 0.032,
            color: "rgba(255,255,255,0.45)",
            marginTop: W * 0.022,
          }}
        >
          Whisper recognition degraded
        </div>
      </div>

      {/* Caption */}
      <div
        style={{
          position: "absolute",
          bottom: H * 0.37,
          left: W * 0.08,
          right: W * 0.08,
        }}
      >
        <Caption
          label="Live Proof"
          headline={
            <>
              AI can&apos;t
              <br />
              hear you.
            </>
          }
          canvasW={W}
        />
      </div>

      {/* Phone — right-offset */}
      <Phone
        src={screenshotSrc}
        alt="Nexus Shield diagnostics"
        style={{
          position: "absolute",
          bottom: 0,
          right: `-${W * 0.04}px`,
          width: W * 0.82,
          transform: "translateY(10%)",
        }}
      />
    </div>
  );
}

// ─── SLIDE 3: Two-Tier (light/contrast slide) ─────────────────────────────────
function Slide3TwoTier({ W, H, screenshotSrc }: { W: number; H: number; screenshotSrc: string }) {
  return (
    <div
      style={{
        width: W,
        height: H,
        background: BRAND.offWhite,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, sans-serif",
      }}
    >
      {/* Soft gradient top */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `linear-gradient(180deg, rgba(0,122,255,0.06) 0%, ${BRAND.offWhite} 40%)`,
        }}
      />

      {/* Tier pills */}
      <div
        style={{
          position: "absolute",
          top: H * 0.065,
          left: W * 0.08,
          display: "flex",
          flexDirection: "column",
          gap: W * 0.025,
        }}
      >
        {/* Tier 1 */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: W * 0.035,
            background: "white",
            borderRadius: W * 0.035,
            padding: `${W * 0.035}px ${W * 0.045}px`,
            boxShadow: `0 4px 24px rgba(59,196,214,0.15), 0 1px 4px rgba(0,0,0,0.06)`,
          }}
        >
          <div
            style={{
              width: W * 0.085,
              height: W * 0.085,
              borderRadius: W * 0.02,
              background: `${BRAND.tier1}18`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            <svg width={W * 0.045} height={W * 0.045} viewBox="0 0 24 24" fill="none">
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" stroke={BRAND.tier1} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div>
            <div style={{ fontSize: W * 0.038, fontWeight: 700, color: "#111", lineHeight: 1.2 }}>
              Acoustic Layer
            </div>
            <div style={{ fontSize: W * 0.03, color: "#666", marginTop: 4 }}>
              Psychoacoustic masking · 300–4kHz
            </div>
          </div>
          <div
            style={{
              marginLeft: "auto",
              width: W * 0.022,
              height: W * 0.022,
              borderRadius: "50%",
              background: BRAND.tier1,
            }}
          />
        </div>

        {/* Tier 2 */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: W * 0.035,
            background: "white",
            borderRadius: W * 0.035,
            padding: `${W * 0.035}px ${W * 0.045}px`,
            boxShadow: `0 4px 24px rgba(155,121,217,0.15), 0 1px 4px rgba(0,0,0,0.06)`,
          }}
        >
          <div
            style={{
              width: W * 0.085,
              height: W * 0.085,
              borderRadius: W * 0.02,
              background: `${BRAND.tier2}18`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            <svg width={W * 0.045} height={W * 0.045} viewBox="0 0 24 24" fill="none">
              <path d="M12 2a7 7 0 017 7c0 5.25-7 13-7 13S5 14.25 5 9a7 7 0 017-7z" stroke={BRAND.tier2} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              <circle cx="12" cy="9" r="2.5" stroke={BRAND.tier2} strokeWidth="2" />
            </svg>
          </div>
          <div>
            <div style={{ fontSize: W * 0.038, fontWeight: 700, color: "#111", lineHeight: 1.2 }}>
              Adversarial AI
            </div>
            <div style={{ fontSize: W * 0.03, color: "#666", marginTop: 4 }}>
              Universal perturbations · Whisper & more
            </div>
          </div>
          <div
            style={{
              marginLeft: "auto",
              width: W * 0.022,
              height: W * 0.022,
              borderRadius: "50%",
              background: BRAND.tier2,
            }}
          />
        </div>
      </div>

      {/* Caption */}
      <div
        style={{
          position: "absolute",
          bottom: H * 0.38,
          left: W * 0.08,
          right: W * 0.08,
        }}
      >
        <Caption
          label="Two-Layer Shield"
          headline={
            <>
              Two layers.
              <br />
              One tap.
            </>
          }
          sub="Acoustic + adversarial AI working together."
          textColor="#111"
          labelColor={BRAND.blue}
          canvasW={W}
        />
      </div>

      {/* Phone */}
      <Phone
        src={screenshotSrc}
        alt="Nexus Shield settings"
        style={{
          position: "absolute",
          bottom: 0,
          left: "50%",
          width: W * 0.82,
          transform: "translateX(-50%) translateY(12%)",
        }}
      />
    </div>
  );
}

// ─── SLIDE 4: On-device / No cloud ──────────────────────────────────────────
function Slide4Local({ W, H, screenshotSrc }: { W: number; H: number; screenshotSrc: string }) {
  return (
    <div
      style={{
        width: W,
        height: H,
        background: BRAND.darkBg,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, sans-serif",
      }}
    >
      <Glow color={BRAND.tier2} size={W * 0.8} top="30%" left="15%" opacity={0.22} />
      <Glow color="#00C48C" size={W * 0.6} top="70%" left="70%" opacity={0.18} />

      {/* Stat cards — floating */}
      <div
        style={{
          position: "absolute",
          top: H * 0.065,
          left: W * 0.08,
          right: W * 0.08,
          display: "flex",
          gap: W * 0.035,
        }}
      >
        {[
          { value: "0", unit: "bytes", label: "sent to cloud" },
          { value: "<10", unit: "ms", label: "latency" },
        ].map((stat) => (
          <div
            key={stat.label}
            style={{
              flex: 1,
              background: "rgba(255,255,255,0.05)",
              border: "1px solid rgba(255,255,255,0.1)",
              borderRadius: W * 0.04,
              padding: `${W * 0.045}px ${W * 0.05}px`,
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "baseline",
                gap: W * 0.012,
              }}
            >
              <span
                style={{
                  fontSize: W * 0.1,
                  fontWeight: 800,
                  lineHeight: 1,
                  color: BRAND.white,
                  letterSpacing: "-0.03em",
                }}
              >
                {stat.value}
              </span>
              <span
                style={{
                  fontSize: W * 0.036,
                  fontWeight: 600,
                  color: BRAND.tier1,
                }}
              >
                {stat.unit}
              </span>
            </div>
            <div
              style={{
                fontSize: W * 0.03,
                color: "rgba(255,255,255,0.45)",
                marginTop: W * 0.012,
              }}
            >
              {stat.label}
            </div>
          </div>
        ))}
      </div>

      {/* Caption */}
      <div
        style={{
          position: "absolute",
          bottom: H * 0.37,
          left: W * 0.08,
          right: W * 0.08,
        }}
      >
        <Caption
          label="100% On-Device"
          headline={
            <>
              Your voice
              <br />
              stays yours.
            </>
          }
          sub="No cloud. No accounts. No data leaves."
          canvasW={W}
        />
      </div>

      {/* Phone */}
      <Phone
        src={screenshotSrc}
        alt="Nexus Shield — on device"
        style={{
          position: "absolute",
          bottom: 0,
          left: `-${W * 0.02}px`,
          width: W * 0.8,
          transform: "translateY(10%)",
        }}
      />
    </div>
  );
}

// ─── SLIDE 5: Live spectrum / metrics ────────────────────────────────────────
function Slide5Live({ W, H, screenshotSrc }: { W: number; H: number; screenshotSrc: string }) {
  const bars = Array.from({ length: 40 }, (_, i) => {
    const x = i / 40;
    const h = Math.max(0.08, Math.sin(x * Math.PI * 3) * 0.5 + Math.random() * 0.4 + 0.15);
    return { h, color: x < 0.45 ? BRAND.tier1 : BRAND.tier2 };
  });

  return (
    <div
      style={{
        width: W,
        height: H,
        background: BRAND.offWhite,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, sans-serif",
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `linear-gradient(180deg, rgba(155,121,217,0.07) 0%, ${BRAND.offWhite} 45%)`,
        }}
      />

      {/* Spectrum visualizer card */}
      <div
        style={{
          position: "absolute",
          top: H * 0.065,
          left: W * 0.06,
          right: W * 0.06,
          background: "white",
          borderRadius: W * 0.045,
          padding: `${W * 0.05}px ${W * 0.055}px`,
          boxShadow: "0 4px 32px rgba(0,0,0,0.08)",
        }}
      >
        <div
          style={{
            fontSize: W * 0.032,
            fontWeight: 600,
            color: "#111",
            marginBottom: W * 0.04,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <span>Live Spectrum</span>
          <span
            style={{
              fontSize: W * 0.026,
              color: "#00C48C",
              fontWeight: 600,
              display: "flex",
              alignItems: "center",
              gap: W * 0.012,
            }}
          >
            <span
              style={{
                width: W * 0.018,
                height: W * 0.018,
                borderRadius: "50%",
                background: "#00C48C",
                display: "inline-block",
              }}
            />
            LIVE
          </span>
        </div>
        {/* Bars */}
        <div
          style={{
            display: "flex",
            alignItems: "flex-end",
            gap: W * 0.008,
            height: W * 0.18,
          }}
        >
          {bars.map((bar, i) => (
            <div
              key={i}
              style={{
                flex: 1,
                height: `${bar.h * 100}%`,
                background: `linear-gradient(180deg, ${bar.color}, ${bar.color}66)`,
                borderRadius: W * 0.005,
              }}
            />
          ))}
        </div>
        {/* Freq labels */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginTop: W * 0.02,
            fontSize: W * 0.024,
            color: "#999",
            fontVariantNumeric: "tabular-nums",
          }}
        >
          <span>100 Hz</span>
          <span>1 kHz</span>
          <span>4 kHz</span>
          <span>20 kHz</span>
        </div>
      </div>

      {/* Caption */}
      <div
        style={{
          position: "absolute",
          bottom: H * 0.37,
          left: W * 0.08,
          right: W * 0.08,
        }}
      >
        <Caption
          label="Real-Time Proof"
          headline={
            <>
              Know it&apos;s
              <br />
              working.
            </>
          }
          sub="Live spectrum + latency + AI jam score."
          textColor="#111"
          labelColor={BRAND.tier2}
          canvasW={W}
        />
      </div>

      {/* Phone */}
      <Phone
        src={screenshotSrc}
        alt="Nexus Shield diagnostics view"
        style={{
          position: "absolute",
          bottom: 0,
          right: `-${W * 0.04}px`,
          width: W * 0.8,
          transform: "translateY(10%)",
        }}
      />
    </div>
  );
}

// ─── SLIDE 6: More features ───────────────────────────────────────────────────
function Slide6More({ W, H }: { W: number; H: number }) {
  const features = [
    { label: "Bluetooth HQ Recording", color: BRAND.tier1 },
    { label: "AirPods Pro Support", color: BRAND.tier1 },
    { label: "VoIP Mode", color: BRAND.tier2 },
    { label: "Session History", color: BRAND.tier2 },
    { label: "Background Shield", color: "#00C48C" },
    { label: "Siri Shortcuts", color: BRAND.blue },
  ];
  const coming = ["Live Activity", "Widget", "Android"];

  return (
    <div
      style={{
        width: W,
        height: H,
        background: BRAND.darkBg,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, sans-serif",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: `0 ${W * 0.08}px`,
      }}
    >
      <Glow color={BRAND.blue} size={W * 1.0} top="50%" left="50%" opacity={0.14} />

      {/* App icon placeholder */}
      <div
        style={{
          width: W * 0.22,
          height: W * 0.22,
          borderRadius: W * 0.05,
          background: `linear-gradient(135deg, ${BRAND.blue}, ${BRAND.tier2})`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          marginBottom: W * 0.05,
          boxShadow: `0 0 ${W * 0.08}px ${BRAND.blue}44`,
        }}
      >
        <svg width={W * 0.12} height={W * 0.12} viewBox="0 0 24 24" fill="white">
          <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z" />
        </svg>
      </div>

      <div
        style={{
          fontSize: W * 0.08,
          fontWeight: 800,
          color: BRAND.white,
          lineHeight: 1,
          textAlign: "center",
          marginBottom: W * 0.02,
        }}
      >
        And so much more.
      </div>
      <div
        style={{
          fontSize: W * 0.034,
          color: "rgba(255,255,255,0.45)",
          textAlign: "center",
          marginBottom: W * 0.065,
        }}
      >
        Everything you need to protect your voice.
      </div>

      {/* Feature pills */}
      <div
        style={{
          display: "flex",
          flexWrap: "wrap" as const,
          gap: W * 0.022,
          justifyContent: "center",
          marginBottom: W * 0.05,
        }}
      >
        {features.map((f) => (
          <Pill key={f.label} label={f.label} color={f.color} canvasW={W} />
        ))}
      </div>

      {/* Coming soon */}
      <div
        style={{
          fontSize: W * 0.026,
          fontWeight: 600,
          letterSpacing: "0.08em",
          textTransform: "uppercase" as const,
          color: "rgba(255,255,255,0.3)",
          marginBottom: W * 0.022,
        }}
      >
        Coming Soon
      </div>
      <div
        style={{
          display: "flex",
          gap: W * 0.022,
          justifyContent: "center",
          flexWrap: "wrap" as const,
        }}
      >
        {coming.map((c) => (
          <div
            key={c}
            style={{
              padding: `${W * 0.016}px ${W * 0.036}px`,
              borderRadius: 999,
              border: "1.5px solid rgba(255,255,255,0.12)",
              fontSize: W * 0.03,
              fontWeight: 600,
              color: "rgba(255,255,255,0.25)",
              fontFamily: "Inter, system-ui, sans-serif",
            }}
          >
            {c}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Slide registry ──────────────────────────────────────────────────────────
const SCREENSHOT_PATHS = {
  main: "/screenshots/main.png",
  diagnostics: "/screenshots/diagnostics.png",
  settings: "/screenshots/settings.png",
  account: "/screenshots/account.png",
};

function getSlide(id: string, W: number, H: number) {
  switch (id) {
    case "hero":
      return <Slide1Hero W={W} H={H} screenshotSrc={SCREENSHOT_PATHS.main} />;
    case "proof":
      return <Slide2Proof W={W} H={H} screenshotSrc={SCREENSHOT_PATHS.diagnostics} />;
    case "two-tier":
      return <Slide3TwoTier W={W} H={H} screenshotSrc={SCREENSHOT_PATHS.settings} />;
    case "local":
      return <Slide4Local W={W} H={H} screenshotSrc={SCREENSHOT_PATHS.main} />;
    case "live":
      return <Slide5Live W={W} H={H} screenshotSrc={SCREENSHOT_PATHS.diagnostics} />;
    case "more":
      return <Slide6More W={W} H={H} />;
    default:
      return null;
  }
}

// ─── Preview card with ResizeObserver scaling ────────────────────────────────
function PreviewCard({
  slideId,
  size,
  onExport,
}: {
  slideId: string;
  size: (typeof IPHONE_SIZES)[number];
  onExport: (el: HTMLDivElement, label: string, index: number) => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const offscreenRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  const meta = SLIDES_META.find((s) => s.id === slideId)!;
  const index = SLIDES_META.findIndex((s) => s.id === slideId);

  useEffect(() => {
    if (!containerRef.current) return;
    const ro = new ResizeObserver((entries) => {
      const entry = entries[0];
      if (!entry) return;
      const containerW = entry.contentRect.width;
      setScale(containerW / IPHONE_W);
    });
    ro.observe(containerRef.current);
    return () => ro.disconnect();
  }, []);

  return (
    <div className="flex flex-col gap-2">
      <div
        ref={containerRef}
        className="relative overflow-hidden rounded-2xl bg-zinc-900 cursor-pointer group"
        style={{ aspectRatio: `${IPHONE_W}/${IPHONE_H}` }}
        onClick={() => {
          if (offscreenRef.current)
            onExport(offscreenRef.current, meta.label, index);
        }}
        title="Click to export this slide"
      >
        <div
          style={{
            width: IPHONE_W,
            height: IPHONE_H,
            transform: `scale(${scale})`,
            transformOrigin: "top left",
          }}
        >
          {getSlide(slideId, IPHONE_W, IPHONE_H)}
        </div>
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/30 rounded-2xl">
          <span className="text-white text-sm font-semibold bg-black/60 px-3 py-1.5 rounded-full">
            Export PNG
          </span>
        </div>
      </div>
      <span className="text-xs text-zinc-500 font-medium text-center">{meta.label}</span>

      {/* Offscreen export target at full resolution */}
      <div
        ref={offscreenRef}
        style={{
          position: "absolute",
          left: -9999,
          top: 0,
          width: size.w,
          height: size.h,
          overflow: "hidden",
        }}
      >
        {getSlide(slideId, size.w, size.h)}
      </div>
    </div>
  );
}

// ─── Main page ────────────────────────────────────────────────────────────────
export default function ScreenshotsPage() {
  const [selectedSize, setSelectedSize] = useState<(typeof IPHONE_SIZES)[number]>(IPHONE_SIZES[0]);
  const [exporting, setExporting] = useState<string | null>(null);

  async function exportSlide(el: HTMLDivElement, label: string, index: number) {
    if (exporting) return;
    setExporting(label);
    try {
      // Move on-screen for capture
      el.style.left = "0px";
      el.style.opacity = "1";
      el.style.zIndex = "-1";

      const opts = {
        width: selectedSize.w,
        height: selectedSize.h,
        pixelRatio: 1,
        cacheBust: true,
      };

      // Double-call trick: first warms fonts/images, second produces clean output
      await toPng(el, opts);
      const dataUrl = await toPng(el, opts);

      // Move off-screen
      el.style.left = "-9999px";
      el.style.opacity = "";
      el.style.zIndex = "";

      const fileName = `${String(index + 1).padStart(2, "0")}-${label.split("·")[1]?.trim().toLowerCase().replace(/\s+/g, "-") ?? label}-${selectedSize.w}x${selectedSize.h}.png`;
      const link = document.createElement("a");
      link.download = fileName;
      link.href = dataUrl;
      link.click();
    } catch (err) {
      console.error("Export failed:", err);
      el.style.left = "-9999px";
    } finally {
      setExporting(null);
    }
  }

  async function exportAll() {
    if (exporting) return;
    for (let i = 0; i < SLIDES_META.length; i++) {
      const slide = SLIDES_META[i];
      // Find the offscreen div for this slide — each PreviewCard renders its own
      // We use a document query since refs are in child components
      const offscreenEls = document.querySelectorAll<HTMLDivElement>(
        "[data-export-slide]"
      );
      const el = offscreenEls[i];
      if (el) {
        await exportSlide(el, slide.label, i);
        await new Promise((r) => setTimeout(r, 300));
      }
    }
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-white">
      {/* Toolbar */}
      <div className="sticky top-0 z-50 bg-zinc-900/80 backdrop-blur border-b border-white/[0.06] px-6 py-3 flex items-center gap-4 flex-wrap">
        <div className="flex items-center gap-2 mr-2">
          <div className="w-6 h-6 rounded bg-blue-600 flex items-center justify-center">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white">
              <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z" />
            </svg>
          </div>
          <span className="font-bold text-sm tracking-tight">Nexus Shield</span>
        </div>

        <span className="text-zinc-500 text-xs">App Store Screenshots</span>

        <div className="ml-auto flex items-center gap-3">
          {/* Size picker */}
          <div className="flex gap-1">
            {IPHONE_SIZES.map((s) => (
              <button
                key={s.label}
                onClick={() => setSelectedSize(s)}
                className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${
                  selectedSize.label === s.label
                    ? "bg-blue-600 text-white"
                    : "bg-white/10 text-zinc-400 hover:bg-white/15"
                }`}
              >
                {s.label}
              </button>
            ))}
          </div>

          <button
            onClick={exportAll}
            disabled={!!exporting}
            className="bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white text-xs font-semibold px-4 py-2 rounded-full transition-colors"
          >
            {exporting ? `Exporting…` : "Export All"}
          </button>
        </div>
      </div>

      {/* Grid */}
      <div className="p-6">
        <div className="mb-5">
          <h1 className="text-lg font-bold text-white">6 Slides · iPhone</h1>
          <p className="text-sm text-zinc-500 mt-1">
            Drop your simulator screenshots into{" "}
            <code className="bg-white/10 px-1.5 py-0.5 rounded text-xs font-mono text-zinc-300">
              public/screenshots/
            </code>{" "}
            (main.png, diagnostics.png, settings.png, account.png). Click any
            slide to export, or use Export All.
          </p>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
          {SLIDES_META.map((slide, i) => (
            <PreviewCard
              key={slide.id}
              slideId={slide.id}
              size={selectedSize}
              onExport={(el, label) => exportSlide(el, label, i)}
            />
          ))}
        </div>

        {/* Legend */}
        <div className="mt-8 grid grid-cols-2 sm:grid-cols-3 gap-3 text-xs text-zinc-500">
          <div className="bg-white/5 rounded-xl p-4">
            <div className="font-semibold text-zinc-300 mb-1">Narrative Arc</div>
            <ol className="list-decimal list-inside space-y-0.5">
              <li>Your voice. Your rules. (Hero)</li>
              <li>87% AI jammed (Proof)</li>
              <li>Two layers, one tap (How)</li>
              <li>0 bytes to cloud (Trust)</li>
              <li>Know it&apos;s working (Metrics)</li>
              <li>And so much more (Features)</li>
            </ol>
          </div>
          <div className="bg-white/5 rounded-xl p-4">
            <div className="font-semibold text-zinc-300 mb-1">Export Sizes</div>
            <div className="space-y-0.5">
              {IPHONE_SIZES.map((s) => (
                <div key={s.label}>
                  {s.label} — {s.w}×{s.h}
                </div>
              ))}
            </div>
          </div>
          <div className="bg-white/5 rounded-xl p-4">
            <div className="font-semibold text-zinc-300 mb-1">Screenshot Files</div>
            <div className="space-y-0.5 font-mono text-zinc-600">
              <div>public/screenshots/main.png</div>
              <div>public/screenshots/diagnostics.png</div>
              <div>public/screenshots/settings.png</div>
              <div>public/screenshots/account.png</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
