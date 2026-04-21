//
//  Member.swift
//  LaunchBox
//

import Foundation
import SwiftData

@Model
final class Member {
    var id: UUID = UUID()
    var name: String = ""
    /// e.g. "#5AC8FA" for UI tint
    var colorHex: String = "#5AC8FA"
    var sortIndex: Int = 0
    var modifiedAt: Date = Date()

    var household: Household?

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        sortIndex: Int = 0,
        household: Household? = nil,
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortIndex = sortIndex
        self.household = household
        self.modifiedAt = modifiedAt
    }
}

enum MemberPalette {
    static let colors = ["#5AC8FA", "#FF9500", "#34C759", "#FF2D55", "#AF52DE", "#FFCC00", "#007AFF"]

    static func color(at index: Int) -> String {
        colors[index % colors.count]
    }
}
