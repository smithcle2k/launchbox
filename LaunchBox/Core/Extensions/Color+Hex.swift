//
//  Color+Hex.swift
//  LaunchBox
//

import SwiftUI

extension Color {
    /// Parses `#RRGGBB` or `RRGGBB` for member chips.
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&rgb), s.count == 6 else {
            self = .accentColor
            return
        }
        let r = Double((rgb & 0xFF_0000) >> 16) / 255
        let g = Double((rgb & 0x00_FF00) >> 8) / 255
        let b = Double(rgb & 0x00_00FF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
