//
//  SettingsView.swift
//  LaunchBox
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("profileDisplayName") private var profileDisplayName = ""
    @AppStorage("profileEmail") private var profileEmail = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reduceHaptics") private var reduceHaptics = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        Form {
            Section {
                HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        TextField(
                            String(localized: "Display name"),
                            text: $profileDisplayName
                        )
                        .placeholder(when: profileDisplayName.isEmpty) {
                            Text(String(localized: "Your name"))
                                .foregroundStyle(.tertiary)
                        }

                        TextField(
                            String(localized: "Email"),
                            text: $profileEmail
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .placeholder(when: profileEmail.isEmpty) {
                            Text(String(localized: "you@example.com"))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            } header: {
                Text(String(localized: "Profile"))
            }

            Section {
                Picker(selection: $appearanceRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(title(for: mode)).tag(mode.rawValue)
                    }
                } label: {
                    Label(String(localized: "Appearance"), systemImage: "circle.lefthalf.filled")
                }

                Toggle(isOn: $notificationsEnabled) {
                    Label(String(localized: "Notifications"), systemImage: "bell")
                }
                .onChange(of: notificationsEnabled) { _, enabled in
                    if enabled {
                        Task {
                            _ = await OneSignalService.requestPermission()
                        }
                    }
                }

                Toggle(isOn: $reduceHaptics) {
                    Label(String(localized: "Reduce Haptics"), systemImage: "waveform.path")
                }
            } header: {
                Text(String(localized: "Preferences"))
            }

            Section {
                Link(destination: Secrets.privacyPolicyURL) {
                    Label(String(localized: "Privacy Policy"), systemImage: "hand.raised")
                }

                Link(destination: Secrets.termsURL) {
                    Label(String(localized: "Terms of Service"), systemImage: "doc.text")
                }

                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Label(String(localized: "Acknowledgements"), systemImage: "heart.text.square")
                }
            } header: {
                Text(String(localized: "Legal"))
            }

            Section {
                LabeledContent(String(localized: "Version")) {
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(String(localized: "About"))
            }
        }
        .navigationTitle(String(localized: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func title(for mode: AppearanceMode) -> String {
        switch mode {
        case .system: String(localized: "System")
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

private struct AcknowledgementsView: View {
    var body: some View {
        ScrollView {
            Text(String(localized: "Add third-party license text here (e.g. Lottie, OneSignal)."))
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.md)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Acknowledgements"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
