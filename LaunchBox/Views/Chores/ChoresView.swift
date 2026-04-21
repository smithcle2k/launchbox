//
//  ChoresView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct ChoresView: View {
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var vm = ChoresViewModel()

    @AppStorage(AppStorageKeys.myMemberID) private var myMemberIDRaw = ""
    @State private var undoChore: Chore?
    @State private var undoDismissTask: Task<Void, Never>?

    private var myMemberUUID: UUID? {
        UUID(uuidString: myMemberIDRaw)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.members.isEmpty {
                    ContentUnavailableView {
                        Label(
                            String(localized: "Add People First"),
                            systemImage: "person.2"
                        )
                    } description: {
                        Text(String(localized: "Add everyone who shares chores in Settings, then come back here."))
                            .multilineTextAlignment(.center)
                    } actions: {
                        Button(String(localized: "Open Settings")) {
                            router.selectedTab = .settings
                        }
                        .buttonStyle(.borderedProminent)
                        .minTapTarget()
                    }
                    .padding(AppTheme.Spacing.md)
                } else if vm.chores.isEmpty {
                    ContentUnavailableView {
                        Label(
                            String(localized: "No Chores Yet"),
                            systemImage: "checklist"
                        )
                    } description: {
                        Text(String(localized: "Add a chore and we’ll rotate who’s up."))
                            .multilineTextAlignment(.center)
                    } actions: {
                        Button(String(localized: "Add Chore")) {
                            router.choresPath.append(AppRoute.addChore)
                        }
                        .buttonStyle(.borderedProminent)
                        .minTapTarget()
                    }
                    .padding(AppTheme.Spacing.md)
                } else {
                    choreList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let chore = undoChore {
                UndoDoneToast(
                    onUndo: {
                        undoDismissTask?.cancel()
                        undoChore = nil
                        Task {
                            await vm.undoLastDone(chore: chore, context: modelContext)
                        }
                    },
                    onDismiss: {
                        undoDismissTask?.cancel()
                        undoChore = nil
                    }
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.lg)
                .transition(
                    accessibilityReduceMotion
                    ? .opacity
                    : .move(edge: .bottom).combined(with: .opacity)
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Whose Turn?"))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.choresPath.append(AppRoute.history)
                } label: {
                    Label(String(localized: "History"), systemImage: "clock.arrow.circlepath")
                }
                .accessibilityLabel(String(localized: "History"))
                .minTapTarget()
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.choresPath.append(AppRoute.addChore)
                } label: {
                    Label(String(localized: "Add Chore"), systemImage: "plus.circle.fill")
                }
                .accessibilityLabel(String(localized: "Add Chore"))
                .minTapTarget()
            }
        }
        .task {
            await vm.load(context: modelContext)
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

    private var choreList: some View {
        List {
            if !vm.dueToday.isEmpty {
                Section {
                    ForEach(vm.dueToday, id: \.id) { chore in
                        choreRow(chore)
                    }
                } header: {
                    Text(String(localized: "Due Today"))
                }
            }

            if !vm.upcoming.isEmpty {
                Section {
                    ForEach(vm.upcoming, id: \.id) { chore in
                        choreRow(chore)
                    }
                } header: {
                    Text(String(localized: "Upcoming"))
                }
            }

            if !vm.later.isEmpty {
                Section {
                    ForEach(vm.later, id: \.id) { chore in
                        choreRow(chore)
                    }
                } header: {
                    Text(String(localized: "Later"))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    private func choreRow(_ chore: Chore) -> some View {
        ChoreTaskRow(
            chore: chore,
            members: vm.members,
            myMemberID: myMemberUUID,
            onTap: {
                router.choresPath.append(AppRoute.choreDetail(chore.id))
            },
            onDone: {
                HapticManager.impact(.medium)
                Task {
                    await vm.markDone(chore: chore, context: modelContext)
                    undoDismissTask?.cancel()
                    undoChore = chore
                    undoDismissTask = Task {
                        try? await Task.sleep(for: .seconds(5))
                        await MainActor.run {
                            undoChore = nil
                        }
                    }
                }
            }
        )
    }
}

private struct UndoDoneToast: View {
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(String(localized: "Marked done"))
                .font(.subheadline.weight(.medium))
            Spacer()
            Button(String(localized: "Undo")) {
                onUndo()
            }
            .font(.subheadline.weight(.semibold))
            .minTapTarget()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .minTapTarget()
        }
        .padding(AppTheme.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}

private struct ChoreTaskRow: View {
    let chore: Chore
    let members: [Member]
    let myMemberID: UUID?
    let onTap: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(chore.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        assigneeChip
                    }
                    Spacer(minLength: AppTheme.Spacing.sm)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDone) {
                Text(String(localized: "Done"))
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .minTapTarget()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private var assigneeChip: some View {
        let name = chore.displayAssigneeName(members: members)
        let id = chore.currentAssigneeID ?? chore.rotationMemberIDs.first
        let hex = members.first(where: { $0.id == id })?.colorHex ?? "#8E8E93"
        let isMyTurn = myMemberID != nil && chore.currentAssigneeID == myMemberID
        return HStack(spacing: AppTheme.Spacing.sm) {
            (Text(name) + Text(String(localized: "’s turn")))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: hex))
            if isMyTurn {
                Text(String(localized: "Your turn"))
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isMyTurn
            ? String(localized: "\(name) is up next for this chore, your turn to do it")
            : String(localized: "\(name) is up next for this chore")
        )
    }
}

#Preview {
    NavigationStack {
        ChoresView(router: AppRouter())
    }
    .modelContainer(
        for: [Household.self, Member.self, Chore.self, ChoreLog.self],
        inMemory: true
    )
}
