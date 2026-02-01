//
//  StateBadge.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

// MARK: - Badge Style Modifier

enum BadgeSize {
    case regular
    case compact
}

struct BadgeStyle: ViewModifier {
    let color: Color
    let size: BadgeSize

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, size == .regular ? DesignTokens.Spacing.medium : DesignTokens.Spacing.small - 1)
            .padding(.vertical, size == .regular ? DesignTokens.Spacing.xSmall : DesignTokens.Spacing.xxSmall + 1)
            .background(color.opacity(DesignTokens.Opacity.backgroundTint))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

extension View {
    func badgeStyle(color: Color, size: BadgeSize = .regular) -> some View {
        modifier(BadgeStyle(color: color, size: size))
    }
}

// MARK: - State Badge

struct StateBadge: View {
    let state: JobState
    let count: Int?

    init(state: JobState, count: Int? = nil) {
        self.state = state
        self.count = count
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xSmall) {
            Image(systemName: state.icon)
                .font(.body)

            if let count = count {
                Text("\(count)")
                    .font(.callout)
                    .fontWeight(.medium)
            } else {
                Text(state.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
            }
        }
        .badgeStyle(color: state.color)
    }
}

// MARK: - Count Badge

struct CountBadge: View {
    let count: Int
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xSmall) {
            Text("\(count)")
                .font(.system(size: 11))
                .fontWeight(.semibold)
                .monospacedDigit()
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
            }
        }
        .badgeStyle(color: color, size: .compact)
    }
}

// MARK: - Previews

#Preview("State Badges") {
    VStack(spacing: 12) {
        HStack {
            ForEach(JobState.allCases, id: \.self) { state in
                StateBadge(state: state)
            }
        }

        HStack {
            ForEach(JobState.allCases, id: \.self) { state in
                StateBadge(state: state, count: Int.random(in: 1...100))
            }
        }
    }
    .padding()
}
