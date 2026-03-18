import SwiftUI

struct AudioRoutingView: View {
    @Bindable var state: AppState

    /// Shared session configurator — used for live route info and BT HQ toggle.
    private let session = AudioSessionConfigurator.shared

    /// Bluetooth HQ toggle state, mirroring AudioSessionConfigurator.
    @State private var bluetoothHQEnabled: Bool = AudioSessionConfigurator.shared.bluetoothHQEnabled
    @State private var bluetoothHQError: String? = nil

    var body: some View {
        NavigationStack {
            List {
                routingSection
                bluetoothSection
                routeInfoSection
            }
            .navigationTitle("Routing")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.insetGrouped)
        }
        .onReceive(NotificationCenter.default.publisher(for: .audioRouteChanged)) { _ in
            // Sync BT HQ state when route changes
            bluetoothHQEnabled = session.bluetoothHQEnabled
        }
    }

    // MARK: - Mode selection

    private var routingSection: some View {
        Section {
            routeRow(
                mode: .speakerPlayback,
                description: "Perturbation plays through the device speaker. Place your phone near the recording device for maximum effect. Works with any app, no setup required.",
                tags: ["No setup", "Any app", "Offline"],
                tagIcon: "checkmark.circle.fill"
            )

            routeRow(
                mode: .voipMix,
                description: "Mixes perturbation directly into outgoing VoIP audio via CallKit or WebRTC proxy. Requires additional configuration.",
                tags: ["Direct mix", "Inaudible"],
                tagIcon: "clock"
            )
        } header: {
            Text("Output Mode")
        }
    }

    private func routeRow(mode: AudioMode, description: String, tags: [String], tagIcon: String) -> some View {
        let isSelected = state.audioMode == mode
        let isAvailable = mode.isAvailable

        return Button {
            guard isAvailable else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                state.audioMode = mode
            }
        } label: {
            VStack(alignment: .leading, spacing: NexusTheme.spacingSM) {
                HStack(alignment: .top) {
                    Image(systemName: mode.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isAvailable ? (isSelected ? NexusTheme.accent : NexusTheme.textSecondary) : NexusTheme.textTertiary)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(mode.rawValue)
                                .font(.headline)
                                .foregroundStyle(isAvailable ? NexusTheme.textPrimary : NexusTheme.textTertiary)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(NexusTheme.accent)
                                    .transition(.scale.combined(with: .opacity))
                            } else if !isAvailable {
                                Text("Coming soon")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(NexusTheme.textTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(Color(.systemFill))
                                    )
                            }
                        }

                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(isAvailable ? NexusTheme.textSecondary : NexusTheme.textTertiary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)

                // Feature tags
                HStack(spacing: NexusTheme.spacingXS) {
                    ForEach(tags, id: \.self) { tag in
                        Label(tag, systemImage: tagIcon)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(isAvailable ? NexusTheme.accent : NexusTheme.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(isAvailable ? NexusTheme.accentFill : Color(.systemFill))
                            )
                    }
                }
                .padding(.leading, 36)
                .padding(.bottom, 4)
            }
        }
        .buttonStyle(.plain)
        .opacity(isAvailable ? 1 : 0.55)
    }

    // MARK: - Bluetooth HQ section

    private var bluetoothSection: some View {
        Section {
            Toggle(isOn: $bluetoothHQEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("AirPods High-Quality Input", systemImage: "airpodspro")
                        .font(.body)
                        .foregroundStyle(NexusTheme.textPrimary)
                    Text("Switches compatible AirPods into wide-band mic mode for cleaner analysis.")
                        .font(.caption)
                        .foregroundStyle(NexusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(NexusTheme.accent)
            .onChange(of: bluetoothHQEnabled) { _, enabled in
                do {
                    if enabled {
                        try session.enableBluetoothHQRecording()
                    } else {
                        try session.disableBluetoothHQRecording()
                    }
                    bluetoothHQError = nil
                } catch {
                    bluetoothHQEnabled = !enabled   // revert
                    bluetoothHQError = error.localizedDescription
                }
            }

            if session.isBluetoothInputActive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(NexusTheme.positive)
                        .frame(width: 7, height: 7)
                    Text("Bluetooth input is active")
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.positive)
                }
            }

            if let err = bluetoothHQError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(NexusTheme.warning)
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(NexusTheme.textSecondary)
                }
            }
        } header: {
            Text("Bluetooth")
        } footer: {
            Text("Requires AirPods Pro (2nd gen) or AirPods 4. Has no effect when Bluetooth input is not the active route.")
        }
    }

    // MARK: - Route info

    private var routeInfoSection: some View {
        Section("Current Route") {
            HStack {
                Label("Output", systemImage: "speaker.fill")
                    .foregroundStyle(NexusTheme.textSecondary)
                Spacer()
                Text(session.currentRoute.isEmpty ? "—" : session.currentRoute)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(NexusTheme.textPrimary)
            }

            HStack {
                Label("Microphone", systemImage: "mic.fill")
                    .foregroundStyle(NexusTheme.textSecondary)
                Spacer()
                Text(session.isMicrophoneAvailable ? "Available" : "Unavailable")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(session.isMicrophoneAvailable
                                     ? NexusTheme.positive : NexusTheme.danger)
            }
        }
    }
}
