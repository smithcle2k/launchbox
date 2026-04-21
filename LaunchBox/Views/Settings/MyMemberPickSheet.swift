//
//  MyMemberPickSheet.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct MyMemberPickSheet: View {
    @Binding var isPresented: Bool
    @AppStorage(AppStorageKeys.myMemberID) private var myMemberIDRaw = ""
    @Environment(\.modelContext) private var modelContext
    @State private var members: [Member] = []

    var body: some View {
        List {
            ForEach(members, id: \.id) { m in
                Button {
                    myMemberIDRaw = m.id.uuidString
                    isPresented = false
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Circle()
                            .fill(Color(hex: m.colorHex))
                            .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)
                        Text(m.name)
                            .foregroundStyle(.primary)
                    }
                }
                .minTapTarget()
            }
        }
        .navigationTitle(String(localized: "Which one is you?"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Skip")) {
                    isPresented = false
                }
            }
        }
        .task {
            await loadMembers()
        }
    }

    private func loadMembers() async {
        do {
            let home = try PersistenceBootstrap.ensureHousehold(context: modelContext)
            members = (home.members ?? []).sorted {
                if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } catch {
            members = []
        }
    }
}
