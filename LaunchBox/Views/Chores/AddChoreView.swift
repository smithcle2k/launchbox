//
//  AddChoreView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct AddChoreView: View {
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @State private var vm = AddChoreViewModel()
    @State private var household: Household?
    @State private var allMembers: [Member] = []

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "Chore name"), text: $vm.title)
                TextField(String(localized: "Notes (optional)"), text: $vm.notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Picker(String(localized: "Repeats"), selection: $vm.cadenceMode) {
                    Text(String(localized: "Daily")).tag(ChoreCadence.Mode.daily)
                    Text(String(localized: "Weekly")).tag(ChoreCadence.Mode.weekly)
                    Text(String(localized: "Every N days")).tag(ChoreCadence.Mode.everyNDays)
                }
                .pickerStyle(.segmented)

                if vm.cadenceMode == .weekly {
                    Picker(String(localized: "Day of week"), selection: $vm.weeklyWeekday) {
                        ForEach(1...7, id: \.self) { w in
                            Text(weekdayLabel(w)).tag(w)
                        }
                    }
                }

                if vm.cadenceMode == .everyNDays {
                    Stepper(value: $vm.everyNDays, in: 1...60) {
                        Text(String(localized: "Every \(vm.everyNDays) days"))
                    }
                }
            } header: {
                Text(String(localized: "Schedule"))
            }

            Section {
                ForEach(vm.rotationMemberIDs, id: \.self) { id in
                    if let m = member(for: id) {
                        HStack {
                            Circle()
                                .fill(Color(hex: m.colorHex))
                                .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)
                            Text(m.name)
                            Spacer()
                            Button {
                                vm.toggleMemberInRotation(id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(String(localized: "Remove from rotation"))
                            .minTapTarget()
                        }
                    }
                }
                .onMove { source, dest in
                    vm.moveRotation(from: source, to: dest)
                }

                ForEach(unselectedMembers, id: \.id) { m in
                    Button {
                        vm.rotationMemberIDs.append(m.id)
                    } label: {
                        Label {
                            Text(String(localized: "Add")) + Text(verbatim: " ") + Text(m.name)
                        } icon: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            } header: {
                Text(String(localized: "Rotation order"))
            } footer: {
                Text(String(localized: "Drag to reorder. Whoever is first is up next after you save."))
            }
        }
        .navigationTitle(String(localized: "Add Chore"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Cancel")) {
                    router.choresPath.removeLast()
                }
                .minTapTarget()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Save")) {
                    save()
                }
                .fontWeight(.semibold)
                .minTapTarget()
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .task {
            await loadMembers()
        }
        .alert(
            String(localized: "Can’t Save"),
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {
                vm.errorMessage = nil
            }
        } message: {
            if let msg = vm.errorMessage {
                Text(msg)
            }
        }
    }

    private func loadMembers() async {
        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: modelContext)
            household = home
            allMembers = (home.members ?? []).sorted {
                if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            vm.prepareRotation(from: allMembers)
            if vm.cadenceMode == .weekly {
                vm.weeklyWeekday = Calendar.current.component(.weekday, from: Date())
            }
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }

    private func member(for id: UUID) -> Member? {
        allMembers.first { $0.id == id }
    }

    private var unselectedMembers: [Member] {
        allMembers.filter { !vm.rotationMemberIDs.contains($0.id) }
    }

    private func weekdayLabel(_ weekday: Int) -> String {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        let idx = weekday - 1
        guard idx >= 0, idx < symbols.count else { return "\(weekday)" }
        return symbols[idx]
    }

    private func save() {
        guard let household else { return }
        if vm.save(household: household, context: modelContext) {
            do {
                try modelContext.save()
                HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
                Task {
                    await NotificationScheduler.rescheduleFromModelContext(modelContext)
                }
                router.choresPath.removeLast()
            } catch {
                vm.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddChoreView(router: AppRouter())
    }
    .modelContainer(
        for: [Household.self, Member.self, Chore.self, ChoreLog.self],
        inMemory: true
    )
}
