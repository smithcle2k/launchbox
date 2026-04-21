//
//  WhoseTurnNextChoreWidget.swift
//  WhoseTurnWidget
//

import SwiftUI
import WidgetKit

@main
struct WhoseTurnWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhoseTurnNextChoreWidget()
    }
}

/// Matches JSON from the main app’s `WidgetSnapshot` (shape must stay in sync).
fileprivate struct DecodedChoreRow: Decodable, Sendable {
    var title: String
    var colorHex: String
    var assigneeName: String
}

fileprivate struct DecodedSnapshot: Decodable, Sendable {
    var householdName: String
    var caughtUp: Bool
    var primaryLine: String
    var rows: [DecodedChoreRow]
}

private let appGroup = "group.com.csmith.LaunchBox"
private let fileName = "widget-snapshot.json"

private nonisolated func loadSnapshot() -> DecodedSnapshot? {
    guard let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else { return nil }
    let url = base.appendingPathComponent(fileName, isDirectory: false)
    return try? JSONDecoder().decode(
        DecodedSnapshot.self,
        from: Data(contentsOf: url)
    )
}

fileprivate struct WhoseTurnNextChoreEntry: TimelineEntry {
    let date: Date
    let householdName: String
    let primaryLine: String
    let rows: [DecodedChoreRow]
    let caughtUp: Bool
}

fileprivate struct WhoseTurnNextChoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> WhoseTurnNextChoreEntry {
        WhoseTurnNextChoreEntry(
            date: Date(),
            householdName: "Home",
            primaryLine: "Next: Dishes — Alex",
            rows: [DecodedChoreRow(title: "Dishes", colorHex: "#3B82F6", assigneeName: "Alex")],
            caughtUp: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WhoseTurnNextChoreEntry) -> Void) {
        let snap = loadSnapshot()
        let entry = WhoseTurnNextChoreEntry(
            date: Date(),
            householdName: snap?.householdName ?? "Home",
            primaryLine: snap?.primaryLine ?? "You’re all caught up",
            rows: snap?.rows ?? [],
            caughtUp: snap?.caughtUp ?? true
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WhoseTurnNextChoreEntry>) -> Void) {
        let snap = loadSnapshot()
        let entry = WhoseTurnNextChoreEntry(
            date: Date(),
            householdName: snap?.householdName ?? "Home",
            primaryLine: snap?.primaryLine ?? "You’re all caught up",
            rows: snap?.rows ?? [],
            caughtUp: snap?.caughtUp ?? true
        )
        let next = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

fileprivate struct WhoseTurnNextChoreWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "WhoseTurnWidget",
            provider: WhoseTurnNextChoreProvider()
        ) { entry in
            WhoseTurnWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Whose Turn?")
        .description("Next chores and whose turn in your household.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

fileprivate struct WhoseTurnWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WhoseTurnNextChoreEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallContent
        case .systemMedium:
            mediumContent
        default:
            smallContent
        }
    }

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.householdName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if entry.caughtUp {
                Text("You’re all caught up")
                    .font(.headline)
            } else if let r = entry.rows.first {
                Text("Your turn: \(r.title)")
                    .font(.headline)
                    .widgetAccentable()
            } else {
                Text(entry.primaryLine)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(8)
    }

    private var mediumContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.householdName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if entry.caughtUp {
                Text("You’re all caught up")
                    .font(.body.weight(.semibold))
            } else {
                ForEach(0..<min(entry.rows.count, 3), id: \.self) { i in
                    let r = entry.rows[i]
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color(from: r.colorHex))
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(r.title)
                                .font(.subheadline.weight(.semibold))
                            Text(r.assigneeName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }

    private func color(from hex: String) -> Color {
        // Minimal hex (widget can't import app Color+Hex without sharing)
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = Int(s, radix: 16) else { return .gray }
        return Color(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
