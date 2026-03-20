import SwiftUI
import AVFoundation

// MARK: - Onboarding container

@available(iOS 17, *)
struct OnboardingView: View {
    @AppStorage("nexus.onboarding.completed") private var isCompleted = false
    @State private var page = 0
    private let totalPages = 4

    var body: some View {
        ZStack {
            // Pure black background
            PixelColor.background.ignoresSafeArea()

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
        .scanlines()
        .animation(.easeOut(duration: 0.2), value: page)
    }

    private var bottomControls: some View {
        VStack(spacing: 26) {
            // Progress indicator — pixel dots, no capsule
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Rectangle()
                        .fill(i == page ? PixelColor.phosphor : PixelColor.textSecondary)
                        .frame(width: i == page ? 20 : 5, height: 3)
                        .animation(PixelAnimation.primary, value: page)
                }
            }

            // CTA buttons — rectangular, pixel-bordered
            if page == 0 {
                Button(action: advance) {
                    Text("[ GET STARTED ]")
                }
                .buttonStyle(PixelButtonStyle())
                .padding(.horizontal, 28)
            } else {
                Button(action: advance) {
                    Text("[ CONTINUE ]")
                }
                .buttonStyle(PixelButtonStyle())
                .padding(.horizontal, 28)
            }
        }
        .padding(.bottom, 54)
        .padding(.horizontal, 28)
    }

    private func advance() {
        withAnimation(PixelAnimation.primary) {
            page = min(page + 1, totalPages - 1)
        }
    }
}

// MARK: - Page 1 — Welcome

@available(iOS 17, *)
private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            PixelColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 24) {
                    // ASCII pixel logo
                    VStack(alignment: .leading, spacing: 0) {
                        Text("  _   _ _______  ___  ___")
                        Text(" | \\ | | ____\\ \\/ / |/ /")
                        Text(" |  \\| |  _|  \\  /| ' / ")
                        Text(" | |\\  | |___ /  \\| . \\ ")
                        Text(" |_| \\_|_____/_/\\_\\_|\\_\\")
                    }
                    .font(PixelFont.monoSmall(size: 10))
                    .foregroundStyle(PixelColor.phosphor)
                    .phosphorGlow()
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(PixelAnimation.appear.delay(0.05), value: appeared)

                    // Version badge
                    HStack(spacing: 0) {
                        Text("> ")
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                        Text("NEXUS SHIELD v1.0")
                            .foregroundStyle(PixelColor.textSecondary)
                    }
                    .font(PixelFont.terminal(12))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 6)
                    .animation(PixelAnimation.appear.delay(0.12), value: appeared)

                    // Hero headline — ALL CAPS, monospaced, tight
                    Text("YOUR VOICE.\nYOUR RULES.")
                        .font(PixelFont.hero(42))
                        .foregroundStyle(PixelColor.text)
                        .lineSpacing(2)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(PixelAnimation.appear.delay(0.2), value: appeared)

                    // Subhead — dim monospaced
                    Text("REAL-TIME ACOUSTIC PROTECTION.\nREDUCES UNWANTED TRANSCRIPTION.\nINVISIBLY. LOCALLY. INSTANTLY.")
                        .font(PixelFont.terminal(13))
                        .foregroundStyle(PixelColor.textSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(PixelAnimation.appear.delay(0.3), value: appeared)
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

// MARK: - Page 2 — How it works

@available(iOS 17, *)
private struct HowItWorksPage: View {
    @State private var appeared = false

    private struct Step {
        let number: String
        let title: String
        let body: String
    }

    private let steps: [Step] = [
        Step(number: "01",
             title: "ACOUSTIC MASKING",
             body: "Psychoacoustic masking below hearing\nthreshold helps protect spoken privacy."),
        Step(number: "02",
             title: "ADVERSARIAL AI",
             body: "Adaptive perturbations can reduce\ntranscription accuracy in many models."),
        Step(number: "03",
             title: "ON-DEVICE ONLY",
             body: "Under 10ms. Zero data leaves phone.\nNo cloud. No accounts."),
    ]

    var body: some View {
        ZStack {
            PixelColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 0) {
                        Text("> ")
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                        Text("HOW IT WORKS")
                            .foregroundStyle(PixelColor.text)
                    }
                    .font(PixelFont.hero(28))

                    Text("TWO LAYERS. ONE TAP. ZERO DATA.")
                        .font(PixelFont.terminal(13))
                        .foregroundStyle(PixelColor.textSecondary)
                        .lineSpacing(4)
                }
                .padding(.top, 76)
                .padding(.horizontal, 34)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(PixelAnimation.appear.delay(0.05), value: appeared)

                Spacer().frame(height: 48)

                // Steps — terminal output format
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        terminalStepRow(step, delay: Double(idx) * 0.09)
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

    private func terminalStepRow(_ step: Step, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Step header: `01/ ACOUSTIC MASKING`
            HStack(spacing: 0) {
                Text(step.number)
                    .font(PixelFont.terminal(13, weight: .bold))
                    .foregroundStyle(PixelColor.phosphor)
                    .phosphorGlow()
                Text("/ ")
                    .font(PixelFont.terminal(13))
                    .foregroundStyle(PixelColor.phosphor)
                    .phosphorGlow()
                Text(step.title)
                    .font(PixelFont.terminal(13, weight: .bold))
                    .foregroundStyle(PixelColor.text)
            }
            // Body indented like terminal output
            Text(step.body)
                .font(PixelFont.terminal(12))
                .foregroundStyle(PixelColor.textSecondary)
                .lineSpacing(4)
                .padding(.leading, 4)
        }
        .padding(.bottom, 28)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -8)
        .animation(PixelAnimation.appear.delay(0.2 + delay), value: appeared)
    }
}

// MARK: - Page 3 — Microphone permission

@available(iOS 17, *)
private struct PermissionPage: View {
    let onGranted: () -> Void

    @State private var appeared = false
    @State private var permissionState: PermissionState = .unknown

    enum PermissionState { case unknown, requesting, granted, denied }

    var body: some View {
        ZStack {
            PixelColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Pixel mic icon — text representation in a box
                VStack(spacing: 2) {
                    Text("┌─────┐")
                    Text("│ MIC │")
                    Text("│ ))) │")
                    Text("└──┬──┘")
                    Text("   │   ")
                    Text("───┴───")
                }
                .font(PixelFont.terminal(14, weight: .bold))
                .foregroundStyle(micIconColor)
                .if(permissionState == .granted) { $0.phosphorGlow() }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 36)

                // Copy — terminal command style
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 0) {
                        Text("> ")
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                        Text(permissionState == .denied
                             ? "MICROPHONE BLOCKED"
                             : "REQUESTING MICROPHONE ACCESS")
                            .foregroundStyle(PixelColor.text)
                    }
                    .font(PixelFont.hero(20))
                    .fixedSize(horizontal: false, vertical: true)

                    Text(permissionState == .denied
                         ? "OPEN SETTINGS TO ENABLE MIC ACCESS,\nTHEN RETURN TO NEXUS."
                         : "AUDIO PROCESSED ON-DEVICE ONLY.\nNOTHING RECORDED OR TRANSMITTED.")
                        .font(PixelFont.terminal(13))
                        .foregroundStyle(PixelColor.textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .padding(.horizontal, 34)

                Spacer()

                if permissionState == .denied {
                    Button("[ OPEN SETTINGS ]") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(PixelButtonStyle())
                    .padding(.horizontal, 28)
                    .padding(.bottom, 130)
                } else if permissionState != .requesting {
                    Button("[ ALLOW ACCESS ]", action: requestPermission)
                        .buttonStyle(PixelButtonStyle())
                        .padding(.horizontal, 28)
                        .padding(.bottom, 130)
                }
            }
        }
        .onAppear {
            checkCurrentPermission()
            withAnimation(PixelAnimation.appear.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var micIconColor: Color {
        switch permissionState {
        case .granted: return PixelColor.phosphor
        case .denied:  return PixelColor.warning
        default:       return PixelColor.text
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
                withAnimation(PixelAnimation.primary) {
                    permissionState = granted ? .granted : .denied
                }
                if granted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onGranted() }
                }
            }
        }
    }
}

// MARK: - Page 4 — Ready

@available(iOS 17, *)
private struct ReadyPage: View {
    let onDone: () -> Void
    @State private var appeared = false
    @State private var cursorVisible: Bool = true
    private let cursorTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            PixelColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 28) {
                    // Pixel checkmark box
                    VStack(alignment: .leading, spacing: 0) {
                        Text("┌───┐")
                        Text("│ ✓ │")
                        Text("└───┘")
                    }
                    .font(PixelFont.hero(20))
                    .foregroundStyle(PixelColor.phosphor)
                    .phosphorGlow()
                    .scaleEffect(appeared ? 1 : 0.75)
                    .opacity(appeared ? 1 : 0)
                    .animation(PixelAnimation.appear.delay(0.1), value: appeared)

                    VStack(alignment: .leading, spacing: 16) {
                        // `> SYSTEM READY` in phosphor green with glow + blinking cursor
                        HStack(spacing: 0) {
                            Text("> SYSTEM READY")
                                .font(PixelFont.hero(32))
                                .foregroundStyle(PixelColor.phosphor)
                                .phosphorGlow()
                            Text(cursorVisible ? " ▌" : "  ")
                                .font(PixelFont.hero(32))
                                .foregroundStyle(PixelColor.phosphor)
                                .phosphorGlow()
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(PixelAnimation.appear.delay(0.18), value: appeared)

                        Text("> ALL SYSTEMS NOMINAL")
                            .font(PixelFont.terminal(14))
                            .foregroundStyle(PixelColor.phosphor)
                            .phosphorGlow()
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(PixelAnimation.appear.delay(0.26), value: appeared)

                        Text("TAP THE SHIELD ON THE HOME SCREEN\nTO BEGIN VOICE PROTECTION.")
                            .font(PixelFont.terminal(13))
                            .foregroundStyle(PixelColor.textSecondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)
                            .animation(PixelAnimation.appear.delay(0.34), value: appeared)
                    }
                }
                .padding(.horizontal, 34)

                Spacer()

                Button("[ START NEXUS SHIELD ]", action: onDone)
                    .buttonStyle(PixelButtonStyle(active: true))
                    .padding(.horizontal, 28)
                    .padding(.bottom, 54)
                    .opacity(appeared ? 1 : 0)
                    .animation(PixelAnimation.appear.delay(0.42), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
        .onReceive(cursorTimer) { _ in
            cursorVisible.toggle()
        }
    }
}
