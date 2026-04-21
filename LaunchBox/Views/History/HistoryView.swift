//
//  HistoryView.swift
//  LaunchBox
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Bindable var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @State private var vm = HistoryViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.sections.isEmpty {
                ContentUnavailableView {
                    Label(
                        String(localized: "No History Yet"),
                        systemImage: "clock.arrow.circlepath"
                    )
                } description: {
                    Text(String(localized: "Completed chores show up here so everyone can see who did what."))
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.Spacing.md)
            } else {
                List {
                    ForEach(vm.sections) { section in
                        Section {
                            if !section.countsLine.isEmpty {
                                Text(section.countsLine)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(section.rows) { row in
                                HStack(spacing: AppTheme.Spacing.md) {
                                    Circle()
                                        .fill(Color(hex: row.colorHex))
                                        .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        Text(row.choreTitle)
                                            .font(.body.weight(.semibold))
                                        Text(row.memberName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(row.log.completedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .minTapTarget()
                            }
                        } header: {
                            Text(section.title)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "History"))
        .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    NavigationStack {
        HistoryView(router: AppRouter())
    }
    .modelContainer(
        for: [Household.self, Member.self, Chore.self, ChoreLog.self],
        inMemory: true
    )
}
