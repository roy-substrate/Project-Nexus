import SwiftUI
import AVFoundation

// MARK: - Onboarding container

@available(iOS 26, *)
struct OnboardingView: View {
    @AppStorage("nexus.onboarding.completed") private var isCompleted = false
    @State private var page = 0
    private let totalPages = 4

    var body: some View {
        ZStack {
            TabView(selection: $page) {
                WelcomePage()
                    .tag(0)
                HowItWorksPage()
                    .tag(1)
                PermissionPage(onGranted: { advance() })
                    .tag(2)
                ReadyPage(onDone: { isCompleted = true })
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            if page < 3 {
                VStack {
                    Spacer()
                    bottomControls
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.9), value: page)
    }

    private var bottomControls: some View {
        VStack(spacing: 26) {
            // Progress indicator — thin capsule dots
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page
                              ? NexusColor.accent
                              : NexusColor.textTertiary)
                        .frame(width: i == page ? 24 : 6, height: 5)
                        .animation(NexusAnimation.primary, value: page)
                }
            }

            // CTA
            if page == 2 {
                Button("Skip for now") { advance() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NexusColor.textSecondary)
                    .padding(.bottom, 4)
            } else if page == 0 {
                // Welcome — dark page: glassProminent (opaque primary action)
                Button(action: advance) {
                    Text("Get Started")
                }
                .buttonStyle(.glassProminent)
                .padding(.horizontal, 28)
            } else {
                // HowItWorks (page 1) — dark page: glass (translucent secondary)
                Button(action: advance) {
                    Text("Continue")
                }
                .buttonStyle(.glass)
                .padding(.horizontal, 28)
            }
        }
        .padding(.bottom, 54)
        .padding(.horizontal, 28)
    }

    private func advance() {
        withAnimation(NexusAnimation.primary) {
            page = min(page + 1, totalPages - 1)
        }
    }
}

// MARK: - Page 1 — Welcome (dark, editorial)

@available(iOS 26, *)
private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Deep near-black background
            NexusColor.background
                .ignoresSafeArea()

            // Tight radial glow — accent indigo, not generic blue
            RadialGradient(
                colors: [NexusColor.accent.opacity(0.16), Color.clear],
                center: .init(x: 0.38, y: 0.52),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    // App badge — minimal, precise
                    HStack(spacing: 10) {
                        Image(systemName: "shield.checkered.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(NexusColor.accent)
                        Text("Nexus Shield")
                            .font(.system(size: 15, weight: .semibold))
                            .kerning(0.2)
                            .foregroundStyle(NexusColor.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(NexusAnimation.appear.delay(0.1), value: appeared)

                    // Hero headline — tighter tracking, heavier impact
                    Text("Your voice.\nYour rules.")
                        .font(.system(size: 54, weight: .bold, design: .default))
                        .kerning(-1.2)
                        .foregroundStyle(NexusColor.textPrimary)
                        .lineSpacing(0)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(NexusAnimation.appear.delay(0.18), value: appeared)

                    // Subhead — cooler white, more weight contrast
                    Text("Real-time acoustic protection that defeats AI transcription — invisibly, locally, instantly.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(NexusColor.textSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(NexusAnimation.appear.delay(0.28), value: appeared)
                }
                .padding(.horizontal, 34)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Page 2 — How it works (editorial dark)

@available(iOS 26, *)
private struct HowItWorksPage: View {
    @State private var appeared = false

    private struct Step {
        let number: String
        let title: String
        let body: String
        let color: Color
    }

    private let steps: [Step] = [
        Step(number: "01",
             title: "Acoustic masking",
             body: "Psychoacoustic noise below your hearing threshold disrupts the feature-extraction layer of speech recognition systems.",
             color: NexusColor.tier1),
        Step(number: "02",
             title: "Adversarial AI",
             body: "ML-crafted universal adversarial perturbations cause Whisper, DeepSpeech, and other models to misrecognize your speech.",
             color: NexusColor.tier2),
        Step(number: "03",
             title: "Under 10 ms latency",
             body: "Everything runs on-device. No cloud, no accounts, no data ever leaves your phone.",
             color: NexusColor.warning),
    ]

    var body: some View {
        ZStack {
            NexusColor.background.ignoresSafeArea()

            // Subtle accent wash
            RadialGradient(
                colors: [NexusColor.tier2.opacity(0.08), Color.clear],
                center: .init(x: 0.8, y: 0.15),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Text("How it works")
                        .font(.system(size: 38, weight: .bold))
                        .kerning(-1.0)
                        .foregroundStyle(NexusColor.textPrimary)

                    Text("Two layers of protection.\nOne tap. Zero data shared.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(NexusColor.textSecondary)
                        .lineSpacing(5)
                }
                .padding(.top, 76)
                .padding(.horizontal, 34)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(NexusAnimation.appear.delay(0.05), value: appeared)

                Spacer().frame(height: 48)

                // Steps — editorial layout, no separator lines
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        stepRow(step, isLast: idx == steps.count - 1, delay: Double(idx) * 0.09)
                    }
                }
                .padding(.horizontal, 34)

                Spacer()
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    private func stepRow(_ step: Step, isLast: Bool, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Step number column — generous gutter
            VStack(alignment: .leading, spacing: 0) {
                Text(step.number)
                    .font(NexusFont.mono(size: 11))
                    .kerning(0.5)
                    .foregroundStyle(step.color)
                    .padding(.top, 3)

                if !isLast {
                    // Connecting line — editorial column rule
                    Rectangle()
                        .fill(NexusColor.textTertiary.opacity(0.3))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
            }
            .frame(width: 38, alignment: .leading)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.system(size: 16, weight: .semibold))
                    .kerning(-0.2)
                    .foregroundStyle(NexusColor.textPrimary)

                Text(step.body)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(NexusColor.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 8)
            .padding(.bottom, isLast ? 0 : 36)
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -8)
        .animation(NexusAnimation.appear.delay(0.2 + delay), value: appeared)
    }
}

// MARK: - Page 3 — Microphone permission

@available(iOS 26, *)
private struct PermissionPage: View {
    let onGranted: () -> Void

    @State private var appeared = false
    @State private var permissionState: PermissionState = .unknown

    enum PermissionState { case unknown, requesting, granted, denied }

    var body: some View {
        ZStack {
            NexusColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(micIconColor.opacity(0.10))
                        .frame(width: 100, height: 100)
                        .overlay {
                            Circle()
                                .strokeBorder(micIconColor.opacity(0.2), lineWidth: 1)
                        }
                    Image(systemName: micIconName)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(micIconColor)
                        .symbolEffect(.bounce, value: permissionState)
                }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 36)

                // Copy
                VStack(spacing: 14) {
                    Text(permissionState == .denied ? "Microphone blocked" : "Allow microphone access")
                        .font(.system(size: 28, weight: .bold))
                        .kerning(-0.6)
                        .foregroundStyle(NexusColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(permissionState == .denied
                         ? "Open Settings to enable microphone access, then return to Nexus."
                         : "Audio is processed entirely on-device. Nothing is recorded or sent anywhere.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(NexusColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer()

                if permissionState == .denied {
                    // Permission page — use .glass (translucent, less aggressive)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.glass)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 130)
                } else if permissionState != .requesting {
                    Button(action: requestPermission) {
                        Text("Allow Microphone")
                    }
                    .buttonStyle(.glass)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 130)
                }
            }
            .padding(.horizontal, 34)
        }
        .onAppear {
            checkCurrentPermission()
            withAnimation(NexusAnimation.appear.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var micIconName: String {
        switch permissionState {
        case .granted: return "mic.fill"
        case .denied:  return "mic.slash.fill"
        default:       return "mic.fill"
        }
    }

    private var micIconColor: Color {
        switch permissionState {
        case .granted: return NexusColor.accentEmerald
        case .denied:  return NexusColor.danger
        default:       return NexusColor.accent
        }
    }

    private func checkCurrentPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            permissionState = .granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onGranted() }
        case .denied:
            permissionState = .denied
        default:
            permissionState = .unknown
        }
    }

    private func requestPermission() {
        permissionState = .requesting
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            await MainActor.run {
                withAnimation(NexusAnimation.primary) {
                    permissionState = granted ? .granted : .denied
                }
                if granted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onGranted() }
                }
            }
        }
    }
}

// MARK: - Page 4 — Ready (dark close, matches welcome)

@available(iOS 26, *)
private struct ReadyPage: View {
    let onDone: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            NexusColor.background.ignoresSafeArea()

            // Emerald glow — signals "protected and ready"
            RadialGradient(
                colors: [NexusColor.accentEmerald.opacity(0.12), Color.clear],
                center: .init(x: 0.42, y: 0.5),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 22) {
                    // Status badge
                    ZStack {
                        Circle()
                            .fill(NexusColor.accentEmerald.opacity(0.12))
                            .frame(width: 68, height: 68)
                            .overlay {
                                Circle()
                                    .strokeBorder(NexusColor.accentEmerald.opacity(0.3), lineWidth: 1)
                            }
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(NexusColor.accentEmerald)
                    }
                    .scaleEffect(appeared ? 1 : 0.75)
                    .opacity(appeared ? 1 : 0)
                    .animation(NexusAnimation.appear.delay(0.1), value: appeared)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("All set.")
                            .font(.system(size: 54, weight: .bold))
                            .kerning(-1.2)
                            .foregroundStyle(NexusColor.textPrimary)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(NexusAnimation.appear.delay(0.18), value: appeared)

                        Text("Tap the shield on the home screen to start protecting your voice.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(NexusColor.textSecondary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(NexusAnimation.appear.delay(0.26), value: appeared)
                    }
                }
                .padding(.horizontal, 34)

                Spacer()

                // Ready — dark page: glassProminent (opaque primary, strongest CTA)
                Button("Start Using Nexus", action: onDone)
                    .buttonStyle(.glassProminent)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 54)
                    .opacity(appeared ? 1 : 0)
                    .animation(NexusAnimation.appear.delay(0.38), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}
