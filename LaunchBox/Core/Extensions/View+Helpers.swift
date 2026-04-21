//
//  View+Helpers.swift
//  LaunchBox
//

import SwiftUI

extension View {
    /// HIG: minimum 44×44 pt interactive target with generous content shape.
    func minTapTarget() -> some View {
        frame(
            minWidth: AppTheme.HitTarget.minimum,
            minHeight: AppTheme.HitTarget.minimum
        )
        .contentShape(Rectangle())
    }

    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
            .shadow(
                color: Color.black.opacity(AppTheme.Shadow.cardOpacity),
                radius: AppTheme.Shadow.cardRadius,
                x: 0,
                y: AppTheme.Shadow.cardYOffset
            )
    }

}

extension Text {
    /// Section title styled for grouped lists (Clarity + Dynamic Type).
    func sectionHeader() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.sm)
    }
}
