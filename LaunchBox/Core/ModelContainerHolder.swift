//
//  ModelContainerHolder.swift
//  LaunchBox
//

import SwiftData

enum ModelContainerHolder {
    @MainActor
    static var container: ModelContainer?
}
