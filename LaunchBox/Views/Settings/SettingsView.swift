//
//  SettingsView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @State private var vm = SettingsViewModel()

    @AppStorage(AppStorageKeys.choreRemindersEnabled) private var remindersEnabled = false
    @AppStorage(AppStorageKeys.notifyHousemateCompletions) private var notifyHousemateCompletions = true
    @AppStorage(AppStorageKeys.myMemberID) private var myMemberIDRaw = ""
    @AppStorage("reduceHaptics") private var reduceHaptics = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    @State private var newMemberName: String = ""
    @FocusState private var nameFieldFocused: Bool
    @State private var showCloudSharing = false
    @State private var showLeaveConfirm = false

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        Form {
            Section {
                if vm.allHouseholds.count > 1 {
                    Picker(
                        String(localized: "Active household"),
                        selection: Binding(
                            get: { vm.activeHouseholdSelection },
                            set: { new in
                                vm.switchToHousehold(id: new, context: modelContext)
                            }
                        )
                    ) {
                        ForEach(vm.allHouseholds, id: \.id) { h in
                            Text(h.name).tag(h.id)
                        }
                    }
                }

                ForEach(vm.members, id: \.id) { member in
                    Button {
                        router.settingsPath.append(AppRoute.editMember(member.id))
                    } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Circle()
                                .fill(Color(hex: member.colorHex))
                                .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)
                            Text(member.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .minTapTarget()
                }
                .onMove { source, dest in
                    vm.moveMembers(from: source, to: dest, context: modelContext)
                }

                HStack {
                    TextField(String(localized: "New name"), text: $newMemberName)
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { addMember() }

                    Button(String(localized: "Add")) {
                        addMember()
                    }
                    .disabled(newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .minTapTarget()
                }
            } header: {
                Text(String(localized: "Household"))
            } footer: {
                Text(String(localized: "Drag to reorder. This order is the default when you create a new chore."))
            }

            if !vm.members.isEmpty {
                Section {
                    Picker(String(localized: "This is me"), selection: $myMemberIDRaw) {
                        Text(String(localized: "Not set")).tag("")
                        ForEach(vm.members, id: \.id) { m in
                            Text(m.name).tag(m.id.uuidString)
                        }
                    }
                } footer: {
                    Text(String(localized: "Used for a small “your turn” hint on the chore list on this device."))
                }
            }

            Section {
                if HouseholdCloudKitStore.shared.sharingRole == .none {
                    Button {
                        showCloudSharing = true
                    } label: {
                        Label(String(localized: "Invite housemate"), systemImage: "person.badge.plus")
                    }
                    .disabled(vm.household == nil)
                    .minTapTarget()
                } else if HouseholdCloudKitStore.shared.sharingRole == .owner {
                    Button {
                        showCloudSharing = true
                    } label: {
                        Label(String(localized: "Manage household sharing"), systemImage: "person.3")
                    }
                    .minTapTarget()
                } else {
                    Button(String(localized: "Leave shared household"), role: .destructive) {
                        showLeaveConfirm = true
                    }
                    .minTapTarget()
                }
            } header: {
                Text(String(localized: "Sharing"))
            } footer: {
                Text(
                    String(localized: "Invite sends a standard iCloud link (like shared Notes). Everyone you add can edit chores.")
                )
            }

            Section {
                Toggle(isOn: $remindersEnabled) {
                    Label(String(localized: "Chore reminders"), systemImage: "bell")
                }
                .onChange(of: remindersEnabled) { _, on in
                    Task {
                        if on {
                            let ok = await NotificationScheduler.requestAuthorization()
                            if !ok {
                                remindersEnabled = false
                            }
                        }
                        await NotificationScheduler.rescheduleFromModelContext(modelContext)
                    }
                }

                if HouseholdCloudKitStore.shared.sharingRole != .none {
                    Toggle(isOn: $notifyHousemateCompletions) {
                        Label(String(localized: "When housemates finish a chore"), systemImage: "person.2")
                    }
                    .onChange(of: notifyHousemateCompletions) { _, on in
                        Task {
                            if on {
                                _ = await NotificationScheduler.requestAuthorization()
                            }
                        }
                    }
                }

                if remindersEnabled {
                    Text(String(localized: "We’ll send a gentle local reminder around 9:00 on the day a chore is due. No accounts or internet required."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if notifyHousemateCompletions, HouseholdCloudKitStore.shared.sharingRole != .none {
                    Text(
                        String(localized: "When you’re sharing a home over iCloud, you’ll get a short local alert when someone else checks off a chore. Set “This is me” so your own changes don’t notify you on this device.")
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text(String(localized: "Notifications"))
            }

            Section {
                Picker(selection: $appearanceRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(title(for: mode)).tag(mode.rawValue)
                    }
                } label: {
                    Label(String(localized: "Appearance"), systemImage: "circle.lefthalf.filled")
                }

                Toggle(isOn: $reduceHaptics) {
                    Label(String(localized: "Reduce Haptics"), systemImage: "waveform.path")
                }
            } header: {
                Text(String(localized: "Preferences"))
            }

            Section {
                Text(
                    String(localized: "Whose Turn? can sync your household through iCloud when you share it. We don’t run our own servers or collect analytics.")
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Label(String(localized: "Acknowledgements"), systemImage: "heart.text.square")
                }
            } header: {
                Text(String(localized: "Privacy"))
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .task {
            await vm.load(context: modelContext)
        }
        .sheet(isPresented: $showCloudSharing) {
            if let home = vm.household {
                CloudSharingSheet(household: home, isPresented: $showCloudSharing)
            }
        }
        .confirmationDialog(
            String(localized: "Leave this shared household?"),
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Leave"), role: .destructive) {
                try? HouseholdCloudKitStore.shared.leaveSharedHousehold(context: modelContext)
                Task { await vm.load(context: modelContext) }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "Local data for this home will be cleared. You can start a new household after."))
        }
        .onReceive(NotificationCenter.default.publisher(for: .whosTurnCloudDataDidChange)) { _ in
            Task { await vm.load(context: modelContext) }
        }
        .alert(
            String(localized: "Couldn’t Load"),
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {
                vm.errorMessage = nil
            }
        } message: {
            if let message = vm.errorMessage {
                Text(message)
            }
        }
    }

    private func addMember() {
        let trimmed = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        vm.addMember(name: trimmed, context: modelContext)
        newMemberName = ""
        nameFieldFocused = false
        Task {
            await NotificationScheduler.rescheduleFromModelContext(modelContext)
        }
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
            Text(String(localized: "This app uses Lottie from Airbnb for onboarding animations."))
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
        SettingsView(router: AppRouter())
    }
    .modelContainer(
        for: [Household.self, Member.self, Chore.self, ChoreLog.self],
        inMemory: true
    )
}
