//
//  View+Utilities.swift
//  LaunchBox
//

import SwiftUI
import UIKit

extension View {
    /// Resign first responder (dismiss keyboard).
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Tap outside controls to dismiss the keyboard (use on scroll backgrounds).
    func onTapDismissKeyboard() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
    }

    /// Overlay placeholder for `TextField` / `TextEditor` when text is empty.
    func placeholder<Placeholder: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Placeholder
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder()
                .opacity(shouldShow ? 1 : 0)
            self
        }
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
