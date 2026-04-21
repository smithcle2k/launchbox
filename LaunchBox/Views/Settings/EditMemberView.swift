//
//  EditMemberView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct EditMemberView: View {
    let memberID: UUID
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var members: [Member]

    @State private var name: String = ""
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    init(memberID: UUID, router: AppRouter) {
        self.memberID = memberID
        self.router = router
        _members = Query(filter: #Predicate<Member> { $0.id == memberID })
    }

    var body: some View {
        Group {
            if let member = members.first {
                Form {
                    Section {
                        TextField(String(localized: "Name"), text: $name)
                            .onAppear {
                                name = member.name
                            }
                    }

                    Section {
                        Button(String(localized: "Save")) {
                            save(member: member)
                        }
                        .minTapTarget()
                    }

                    Section {
                        Button(String(localized: "Remove Person"), role: .destructive) {
                            showDeleteConfirm = true
                        }
                        .minTapTarget()
                    }
                }
                .navigationTitle(String(localized: "Edit Person"))
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView {
                    Label(
                        String(localized: "Not Found"),
                        systemImage: "person.crop.circle.badge.questionmark"
                    )
                }
                .onAppear {
                    router.settingsPath.removeLast()
                }
            }
        }
        .confirmationDialog(
            String(localized: "Remove this person from your home? They’ll be taken off every chore rotation."),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Remove"), role: .destructive) {
                if let member = members.first {
                    remove(member)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
        .alert(
            String(localized: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func save(member: Member) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = String(localized: "Name can’t be empty.")
            return
        }
        member.name = trimmed
        member.touchModified()
        member.household?.touchModified()
        do {
            try modelContext.save()
            HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
            Task {
                await NotificationScheduler.rescheduleFromModelContext(modelContext)
            }
            router.settingsPath.removeLast()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(_ member: Member) {
        do {
            try MemberDeletion.delete(member, context: modelContext)
            HouseholdCloudKitStore.shared.scheduleSync(context: modelContext)
            Task {
                await NotificationScheduler.rescheduleFromModelContext(modelContext)
            }
            router.settingsPath.removeLast()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        EditMemberView(memberID: UUID(), router: AppRouter())
    }
    .modelContainer(
        for: [Household.self, Member.self, Chore.self, ChoreLog.self],
        inMemory: true
    )
}
