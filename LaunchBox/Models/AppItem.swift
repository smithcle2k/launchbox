//
//  AppItem.swift
//  LaunchBox
//

import Foundation
import SwiftData

@Model
final class AppItem {
    var id: UUID
    var title: String
    var subtitle: String
    var createdAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        createdAt: Date = Date(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }
}
