import SwiftUI

struct AccountView: View {
    let analyticsService: AnalyticsService
    let subscriptionManager: SubscriptionManager
    @AppStorage("nexus.onboarding.completed") private var onboardingCompleted = true

    @State private var showDeleteConfirmation = false
    @State private var showDeleteDataConfirmation = false

    private let appVersion: String = {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }()

    var body: some View {
        NavigationStack {
            List {
                statsSection
                dataSection
                dangerSection
                aboutSection
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.insetGrouped)
        }
        .confirmationDialog(
            "Delete Analytics Data",
            isPresented: $showDeleteDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                analyticsService.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all locally stored session history and analytics. This action cannot be undone.")
        }
        .confirmationDialog(
            "Reset App",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset & Restart Onboarding", role: .destructive) {
                resetApp()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all your settings, analytics data, and resets the app to its first-launch state.")
        }
    }

    // MARK: - Stats Section

    private var streakLabel: String {
        let streak = analyticsService.protectionStreak
        let prefix = streak >= 3 ? "🔥 " : ""
        return "\(prefix)\(streak)-day streak"
    }

    private var statsSection: some View {
        Section("Your Shield Stats") {
            statRow(
                icon: "flame.fill",
                label: "Protection Streak",
                value: streakLabel,
                color: analyticsService.protectionStreak >= 3 ? .orange : .secondary
            )
            statRow(
                icon: "shield.fill",
                label: "Total Activations",
                value: "\(analyticsService.totalActivations)",
                color: .blue
            )
            statRow(
                icon: "clock.fill",
                label: "Total Protected Time",
                value: formattedDuration(analyticsService.totalShieldTime),
                color: .green
            )
            statRow(
                icon: "waveform.badge.minus",
                label: "Peak ASR Jam Score",
                value: String(format: "%.0f%%", analyticsService.peakJamScore * 100),
                color: jammingColor(analyticsService.peakJamScore)
            )
            statRow(
                icon: "calendar",
                label: "Sessions Recorded",
                value: "\(analyticsService.sessionHistory.count)",
                color: .secondary
            )
        }
    }

    // MARK: - Data Management Section

    private var dataSection: some View {
        Section {
            NavigationLink {
                SessionHistoryView(analyticsService: analyticsService)
            } label: {
                Label("Session History", systemImage: "clock.arrow.circlepath")
            }

            Button(role: .destructive) {
                showDeleteDataConfirmation = true
            } label: {
                Label("Delete Analytics Data", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("All data is stored locally on this device and never shared. No account or network connection required.")
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Reset App", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Resetting the app will clear all settings and return to the onboarding screen.")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "app.badge")
                    .foregroundStyle(NexusTheme.textSecondary)
                Spacer()
                Text(appVersion)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(NexusTheme.textPrimary)
            }

            HStack {
                Label("Build", systemImage: "hammer")
                    .foregroundStyle(NexusTheme.textSecondary)
                Spacer()
                Text("iOS 26 · Swift 6")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(NexusTheme.textTertiary)
            }

            HStack {
                Label("Privacy", systemImage: "hand.raised.fill")
                    .foregroundStyle(NexusTheme.textSecondary)
                Spacer()
                Text("100% On-Device")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(NexusTheme.positive)
            }
        }
    }

    // MARK: - Helpers

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
                .foregroundStyle(NexusTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func formattedDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(Int(seconds))s"
    }

    private func jammingColor(_ score: Float) -> Color {
        // High jam score = great protection = green. Low = poor = red.
        if score < 0.33 { return .red }
        if score < 0.66 { return .orange }
        return .green
    }

    private func resetApp() {
        analyticsService.deleteAllData()
        UserDefaults.standard.removeObject(forKey: "perturbationConfig")
        onboardingCompleted = false
    }
}

// MARK: - Session History View

private struct SessionHistoryView: View {
    let analyticsService: AnalyticsService

    @State private var shareItem: ShareItem? = nil

    private var sortedHistory: [SessionSummary] {
        analyticsService.sessionHistory.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if sortedHistory.isEmpty {
                ContentUnavailableView(
                    "No Sessions Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Activate the shield to start recording sessions.")
                )
            } else {
                ForEach(sortedHistory) { session in
                    sessionRow(session)
                        .swipeActions(edge: .leading) {
                            if session.peakASRJamScore > 0.3 {
                                Button {
                                    shareItem = ShareItem(text: shareText(for: session))
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                        }
                }
            }
        }
        .navigationTitle("Session History")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(.insetGrouped)
        .sheet(item: $shareItem) { item in
            ShareSheet(text: item.text)
        }
    }

    private func sessionRow(_ session: SessionSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NexusTheme.textPrimary)
                Spacer()
                Text(jammingLabel(session.peakASRJamScore))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(jammingColor(session.peakASRJamScore))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(jammingColor(session.peakASRJamScore).opacity(0.12)))
            }

            HStack(spacing: 16) {
                Label("\(session.shieldActivations) activation\(session.shieldActivations == 1 ? "" : "s")",
                      systemImage: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(NexusTheme.textSecondary)

                Label(formattedDuration(session.totalShieldSeconds),
                      systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(NexusTheme.textSecondary)

                if !session.techniquesUsed.isEmpty {
                    Label("\(session.techniquesUsed.count) technique\(session.techniquesUsed.count == 1 ? "" : "s")",
                          systemImage: "waveform")
                        .font(.caption)
                        .foregroundStyle(NexusTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func shareText(for session: SessionSummary) -> String {
        let jam = Int(session.peakASRJamScore * 100)
        let duration = formattedDuration(session.totalShieldSeconds)
        // Platform-optimized: concise enough for Twitter (< 280 chars),
        // includes hook + brand + URL for all platforms.
        return "Blocked \(jam)% of AI transcription for \(duration) with Nexus Shield — free, on-device voice protection.\n\nYour voice. Your rules.\nnexusshield.app"
    }

    private func formattedDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(Int(seconds))s"
    }

    private func jammingColor(_ score: Float) -> Color {
        // High jam score = great protection = green. Low = poor = red.
        if score < 0.33 { return .red }
        if score < 0.66 { return .orange }
        return .green
    }

    private func jammingLabel(_ score: Float) -> String {
        if score < 0.33 { return "Low" }
        if score < 0.66 { return "Moderate" }
        return "High jam"
    }
}

// MARK: - Share helpers

private struct ShareItem: Identifiable {
    let id = UUID()
    let text: String
}

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
