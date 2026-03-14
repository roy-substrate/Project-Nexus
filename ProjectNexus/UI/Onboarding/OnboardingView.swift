import SwiftUI
import AVFoundation

// MARK: - Onboarding container

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
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: page)
    }

    private var bottomControls: some View {
        VStack(spacing: 24) {
            // Pill dots
            HStack(spacing: 5) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.primary : Color.primary.opacity(0.18))
                        .frame(width: i == page ? 22 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: page)
                }
            }

            // CTA
            if page == 2 {
                Button("Skip for now") { advance() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            } else {
                Button(action: advance) {
                    Text(page == 0 ? "Get Started" : "Continue")
                }
                .buttonStyle(.nexusPrimary)
                .padding(.horizontal, 28)
            }
        }
        .padding(.bottom, 52)
        .padding(.horizontal, 28)
    }

    private func advance() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            page = min(page + 1, totalPages - 1)
        }
    }
}

// MARK: - Page 1 — Welcome (dark, editorial)

private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Deep background
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            // Soft radial glow behind the wordmark
            RadialGradient(
                colors: [Color.blue.opacity(0.22), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 260
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Wordmark block
                VStack(alignment: .leading, spacing: 16) {
                    // App badge
                    HStack(spacing: 10) {
                        Image(systemName: "shield.checkered.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Nexus Shield")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)

                    // Hero headline
                    Text("Your voice.\nYour rules.")
                        .font(.system(size: 52, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.18), value: appeared)

                    // Subhead
                    Text("Real-time acoustic protection that defeats AI transcription — invisibly, locally, instantly.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.28), value: appeared)
                }
                .padding(.horizontal, 32)

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
             color: Color(hue: 0.58, saturation: 0.80, brightness: 0.92)),
        Step(number: "02",
             title: "Adversarial AI",
             body: "ML-crafted universal adversarial perturbations cause Whisper, DeepSpeech, and other models to misrecognize your speech.",
             color: Color(hue: 0.73, saturation: 0.70, brightness: 0.88)),
        Step(number: "03",
             title: "Under 10 ms latency",
             body: "Everything runs on-device. No cloud, no accounts, no data ever leaves your phone.",
             color: .orange),
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Text("How it works")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Three layers, one tap.")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 72)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05), value: appeared)

                Spacer().frame(height: 44)

                // Steps
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        stepRow(step, delay: Double(idx) * 0.09)
                        if idx < steps.count - 1 {
                            Rectangle()
                                .fill(Color(.separator).opacity(0.4))
                                .frame(height: 0.5)
                                .padding(.leading, 32 + 36 + 20)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    private func stepRow(_ step: Step, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Large number
            Text(step.number)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(step.color)
                .frame(width: 36, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(step.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(step.body)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 22)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -10)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.18 + delay), value: appeared)
    }
}

// MARK: - Page 3 — Microphone permission

private struct PermissionPage: View {
    let onGranted: () -> Void

    @State private var appeared = false
    @State private var permissionState: PermissionState = .unknown

    enum PermissionState { case unknown, requesting, granted, denied }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(micIconColor.opacity(0.09))
                        .frame(width: 96, height: 96)
                    Image(systemName: micIconName)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(micIconColor)
                        .symbolEffect(.bounce, value: permissionState)
                }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 32)

                // Copy
                VStack(spacing: 12) {
                    Text(permissionState == .denied ? "Microphone blocked" : "Allow microphone access")
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(permissionState == .denied
                         ? "Open Settings to enable microphone access, then return to Nexus."
                         : "Audio is processed entirely on-device. Nothing is recorded or sent anywhere.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer()

                if permissionState == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.nexusPrimary)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 130)
                } else if permissionState != .requesting {
                    Button(action: requestPermission) {
                        Text("Allow Microphone")
                    }
                    .buttonStyle(.nexusPrimary)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 130)
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            checkCurrentPermission()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.1)) {
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
        case .granted: return .green
        case .denied:  return .red
        default:       return .blue
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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

private struct ReadyPage: View {
    let onDone: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()

            RadialGradient(
                colors: [Color.green.opacity(0.18), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 240
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    // Checkmark badge
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                    .scaleEffect(appeared ? 1 : 0.75)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.1), value: appeared)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("All set.")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.18), value: appeared)

                        Text("Tap the shield on the home screen to start protecting your voice.")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.26), value: appeared)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                Button("Start Using Nexus", action: onDone)
                    .buttonStyle(DarkPrimaryButtonStyle())
                    .padding(.horizontal, 28)
                    .padding(.bottom, 52)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.38), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Dark-surface primary button (for dark onboarding pages)

private struct DarkPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Color(red: 0.05, green: 0.05, blue: 0.08))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .opacity(configuration.isPressed ? 0.82 : 1)
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
