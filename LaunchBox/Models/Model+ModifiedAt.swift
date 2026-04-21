//
//  Model+ModifiedAt.swift
//  LaunchBox
//

import Foundation

extension Household {
    func touchModified(at date: Date = Date()) {
        modifiedAt = date
    }
}

extension Member {
    func touchModified(at date: Date = Date()) {
        modifiedAt = date
    }
}

extension Chore {
    func touchModified(at date: Date = Date()) {
        modifiedAt = date
    }
}

extension ChoreLog {
    func touchModified(at date: Date = Date()) {
        modifiedAt = date
    }
}
