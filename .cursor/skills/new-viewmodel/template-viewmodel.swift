//
//  __FEATURE__ViewModel.swift
//  LaunchBox
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class __FEATURE__ViewModel {
    /// Starts true to avoid empty-state flash before first load (optional pattern).
    var isLoading = true
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // TODO: load data (SwiftData, network, etc.)
    }
}
