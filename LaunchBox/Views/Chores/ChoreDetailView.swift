//
//  ChoreDetailView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct ChoreDetailView: View {
    let choreID: UUID
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var chores: [Chore]
    @Query(sort: [SortDescriptor(\Member.sortIndex), SortDescriptor(\Member.name)])
    private var allMembers: [Member]

    init(choreID: UUID, router: AppRouter) {
        self.choreID = choreID
        self.router = router
        _chores = Query(filter: #Predicate<Chore> { $0.id == choreID })
    }

    var body: some View {
        Group {
            if let chore = chores.first {
                ChoreDetailForm(
                    chore: chore,
                    allMembers: allMembers,
                    router: router,
                    modelContext: modelContext
                )
            } else {
                ContentUnavailableView {
                    Label(
                        String(localized: "Chore Not Found"),
                        systemImage: "questionmark.circle"
                    )
                }
                .onAppear {
                    router.choresPath.removeLast()
                }
            }
        }
    }
}

private struct ChoreDetailForm: View {
    @Bindable var chore: Chore
    let allMembers: [Member]
    @Bindable var router: AppRouter
    let modelContext: ModelContext

    @State private var cadenceMode: ChoreCadence.Mode = .daily
    @State private var weeklyWeekday: Int = 1
    @State private var everyNDays: Int = 3
    @State private var rotationIDs: [UUID] = []
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "Chore name"), text: $chore.title)
                    .onChange(of: chore.title) { _, _ in
                        chore.touchModified()
                        chore.household?.touchModified()
                        try? modelContext.save()
                        HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
                    }
                TextField(String(localized: "Notes"), text: $chore.notes, axis: .vertical)
                    .lineLimit(2...6)
                    .onChange(of: chore.notes) { _, _ in
                        chore.touchModified()
                        chore.household?.touchModified()
                        try? modelContext.save()
                        HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
                    }
            }

            Section {
                Picker(String(localized: "Repeats"), selection: $cadenceMode) {
                    Text(String(localized: "Daily")).tag(ChoreCadence.Mode.daily)
                    Text(String(localized: "Weekly")).tag(ChoreCadence.Mode.weekly)
                    Text(String(localized: "Every N days")).tag(ChoreCadence.Mode.everyNDays)
                }
                .pickerStyle(.segmented)
                .onChange(of: cadenceMode) { _, _ in
                    persistCadence()
                    reschedule()
                }

                if cadenceMode == .weekly {
                    Picker(String(localized: "Day of week"), selection: $weeklyWeekday) {
                        ForEach(1...7, id: \.self) { w in
                            Text(weekdayLabel(w)).tag(w)
                        }
                    }
                    .onChange(of: weeklyWeekday) { _, _ in
                        persistCadence()
                        reschedule()
                    }
                }

                if cadenceMode == .everyNDays {
                    Stepper(value: $everyNDays, in: 1...60) {
                        Text(String(localized: "Every \(everyNDays) days"))
                    }
                    .onChange(of: everyNDays) { _, _ in
                        persistCadence()
                        reschedule()
                    }
                }
            } header: {
                Text(String(localized: "Schedule"))
            }

            Section {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(String(localized: "Next up"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(chore.displayAssigneeName(members: allMembers))
                        .font(.body.weight(.semibold))
                }

                ForEach(rotationIDs, id: \.self) { id in
                    if let m = allMembers.first(where: { $0.id == id }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: m.colorHex))
                                .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)
                            Text(m.name)
                            Spacer()
                            Button {
                                removeFromRotation(id)
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
                    rotationIDs.move(fromOffsets: source, toOffset: dest)
                    applyRotation()
                }

                ForEach(unselectedMembers, id: \.id) { m in
                    Button {
                        rotationIDs.append(m.id)
                        applyRotation()
                    } label: {
                        Label {
                            Text(String(localized: "Add")) + Text(verbatim: " ") + Text(m.name)
                        } icon: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            } header: {
                Text(String(localized: "Rotation"))
            }

            Section {
                Button(String(localized: "Mark Done")) {
                    markDone()
                }
                .minTapTarget()
            }

            if !historyLogs.isEmpty {
                Section(String(localized: "History")) {
                    ForEach(historyLogs, id: \.id) { log in
                        HStack {
                            Text(memberName(log.memberID))
                            Spacer()
                            Text(log.completedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button(String(localized: "Delete Chore"), role: .destructive) {
                    showDeleteConfirm = true
                }
                .minTapTarget()
            }
        }
        .navigationTitle(String(localized: "Chore"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onAppear {
            loadFromChore()
        }
        .confirmationDialog(
            String(localized: "Delete this chore?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                deleteChore()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }

    private var historyLogs: [ChoreLog] {
        (chore.logs ?? []).sorted { $0.completedAt > $1.completedAt }
    }

    private var unselectedMembers: [Member] {
        allMembers.filter { !rotationIDs.contains($0.id) }
    }

    private func loadFromChore() {
        let c = chore.cadence
        cadenceMode = c.mode
        weeklyWeekday = c.weekday ?? Calendar.current.component(.weekday, from: Date())
        everyNDays = max(1, c.intervalDays ?? 3)
        rotationIDs = chore.rotationMemberIDs
    }

    private func persistCadence() {
        switch cadenceMode {
        case .daily:
            chore.cadence = .dailyDefault
        case .weekly:
            chore.cadence = .weekly(weekday: weeklyWeekday)
        case .everyNDays:
            chore.cadence = .every(days: everyNDays)
        }
        chore.touchModified()
        chore.household?.touchModified()
        try? modelContext.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
        reschedule()
    }

    private func applyRotation() {
        chore.rotationMemberIDs = rotationIDs
        if let current = chore.currentAssigneeID, !rotationIDs.contains(current) {
            chore.currentAssigneeID = rotationIDs.first
        }
        chore.recomputeAssigneeFromLogs()
        chore.touchModified()
        chore.household?.touchModified()
        try? modelContext.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
        reschedule()
    }

    private func removeFromRotation(_ id: UUID) {
        rotationIDs.removeAll { $0 == id }
        applyRotation()
    }

    private func weekdayLabel(_ weekday: Int) -> String {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        let idx = weekday - 1
        guard idx >= 0, idx < symbols.count else { return "\(weekday)" }
        return symbols[idx]
    }

    private func memberName(_ id: UUID) -> String {
        allMembers.first(where: { $0.id == id })?.name ?? String(localized: "Someone")
    }

    private func markDone() {
        let order = chore.rotationMemberIDs
        guard !order.isEmpty else { return }
        let assignee = chore.currentAssigneeID ?? order[0]
        let log = ChoreLog(memberID: assignee, chore: chore)
        log.touchModified()
        modelContext.insert(log)
        chore.lastCompletedAt = Date()
        chore.touchModified()
        chore.household?.touchModified()
        chore.recomputeAssigneeFromLogs()
        try? modelContext.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
        Task {
            await NotificationScheduler.rescheduleFromModelContext(modelContext)
        }
        HapticManager.impact(.medium)
    }

    private func deleteChore() {
        chore.household?.touchModified()
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [chore.id.uuidString]
        )
        modelContext.delete(chore)
        try? modelContext.save()
        HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
        router.choresPath.removeLast()
    }

    private func reschedule() {
        Task {
            await NotificationScheduler.rescheduleFromModelContext(modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        ChoreDetailView(choreID: UUID(), router: AppRouter())
    }
    .modelContainer(
        for: [Household.self, Member.self, Chore.self, ChoreLog.self],
        inMemory: true
    )
}
