import SwiftUI
import AVFoundation

// MARK: - Onboarding container

/// Full-screen onboarding flow shown once on first launch.
/// Uses @AppStorage so the completed flag persists across launches.
struct OnboardingView: View {
    @AppStorage("nexus.onboarding.completed") private var isCompleted = false
    @State private var page = 0

    private let totalPages = 4

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content fills entire screen
            TabView(selection: $page) {
                WelcomePage()      .tag(0)
                HowItWorksPage()   .tag(1)
                PermissionPage(onGranted: { advance() })
                    .tag(2)
                ReadyPage(onDone: { isCompleted = true })
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: page)

            // Shared bottom bar: page dots + CTA
            if page < 3 {
                bottomBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Shared bottom bar (pages 0–2)

    private var bottomBar: some View {
        VStack(spacing: 20) {
            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.primary : Color(.systemFill))
                        .frame(width: i == page ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                }
            }

            // CTA — different label for permission screen
            if page == 2 {
                // Permission page manages its own primary button;
                // show a "Skip for now" ghost option here
                Button("Skip for now") { advance() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            } else {
                Button(action: advance) {
                    Text(page == 0 ? "Get Started" : "Continue")
                }
                .buttonStyle(.nexusPrimary)
                .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 44)
        .padding(.horizontal, 32)
    }

    private func advance() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            page = min(page + 1, totalPages - 1)
        }
    }
}

// MARK: - Page 1 — Welcome

private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero illustration
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 180, height: 180)

                Image(systemName: "shield.checkered.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(Color.blue)
                    .symbolEffect(.pulse, options: .repeating, value: appeared)
            }
            .padding(.bottom, 40)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)

            // Wordmark
            VStack(spacing: 10) {
                Text("Nexus Shield")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Your voice. Your privacy.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer()
            Spacer() // extra spacer so content sits above the bottom bar

        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Page 2 — How it works

private struct HowItWorksPage: View {
    @State private var appeared = false

    private let features: [(icon: String, color: Color, title: String, body: String)] = [
        (
            icon: "waveform.path.ecg",
            color: Color(hue: 0.55, saturation: 0.78, brightness: 0.92),
            title: "Acoustic Shield",
            body: "Psychoacoustic noise that is inaudible to you, but disrupts automatic transcription at the feature-extraction layer."
        ),
        (
            icon: "brain",
            color: Color(hue: 0.73, saturation: 0.70, brightness: 0.88),
            title: "Adversarial AI",
            body: "ML-crafted universal adversarial perturbations that cause state-of-the-art speech recognition models to misrecognize your words."
        ),
        (
            icon: "bolt.fill",
            color: .orange,
            title: "Real-time",
            body: "Perturbations are synthesised and mixed in under 10 ms — imperceptible latency while you speak naturally."
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works")
                    .font(.system(.largeTitle, design: .default, weight: .bold))

                Text("Three layers of protection, active simultaneously.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)
            .padding(.horizontal, 32)
            .padding(.bottom, 36)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            // Feature rows
            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    featureRow(feature, delay: Double(index) * 0.08)

                    if index < features.count - 1 {
                        Divider().padding(.leading, 32 + 44 + 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }

    private func featureRow(
        _ feature: (icon: String, color: Color, title: String, body: String),
        delay: Double
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(feature.color)
                .frame(width: 44, height: 44)
                .background(Circle().fill(feature.color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))

                Text(feature.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -12)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.15 + delay), value: appeared)
    }
}

// MARK: - Page 3 — Microphone permission

private struct PermissionPage: View {
    let onGranted: () -> Void

    @State private var appeared = false
    @State private var permissionState: PermissionState = .unknown

    enum PermissionState { case unknown, requesting, granted, denied }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(micIconColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: micIconName)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(micIconColor)
                    .symbolEffect(.bounce, value: permissionState)
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 36)

            // Copy
            VStack(spacing: 12) {
                Text("Allow microphone access")
                    .font(.system(.title2, design: .default, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(permissionState == .denied
                     ? "Microphone access was denied. Open Settings to enable it, then come back."
                     : "Nexus listens to your microphone to calibrate the acoustic shield to your environment. Audio is processed entirely on-device and never leaves your phone.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer()

            // Primary action
            VStack(spacing: 12) {
                if permissionState == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.nexusPrimary)
                } else if permissionState != .requesting {
                    Button(action: requestPermission) {
                        if permissionState == .requesting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Allow Microphone Access")
                        }
                    }
                    .buttonStyle(.nexusPrimary)
                    .disabled(permissionState == .requesting)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 110) // space for the shared bottom bar
        }
        .padding(.horizontal, 32)
        .onAppear {
            checkCurrentPermission()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var micIconName: String {
        switch permissionState {
        case .granted:  return "mic.fill"
        case .denied:   return "mic.slash.fill"
        default:        return "mic.fill"
        }
    }

    private var micIconColor: Color {
        switch permissionState {
        case .granted:  return .green
        case .denied:   return .red
        default:        return .blue
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

// MARK: - Page 4 — Ready

private struct ReadyPage: View {
    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: appeared)
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 36)

            VStack(spacing: 10) {
                Text("You're all set.")
                    .font(.system(.largeTitle, design: .default, weight: .bold))

                Text("Tap the shield on the home screen to start protecting your voice.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            Spacer()

            Button("Start Using Nexus Shield", action: onDone)
                .buttonStyle(.nexusPrimary)
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
    }
}
