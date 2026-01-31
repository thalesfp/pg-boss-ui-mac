//
//  HealthCard.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

struct HealthCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let tooltip: String?

    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color, tooltip: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.tooltip = tooltip
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxSmall) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(DesignTokens.Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(color.opacity(DesignTokens.Opacity.backgroundTint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .help(tooltip ?? "")
    }
}

#Preview {
    HStack(spacing: DesignTokens.Spacing.xLarge) {
        HealthCard(
            title: "Total Jobs",
            value: "1,234",
            subtitle: "Last 24 hours",
            icon: "number.square.fill",
            color: .blue
        )

        HealthCard(
            title: "Failure Rate",
            value: "2.5%",
            subtitle: "25 failed of 1,000",
            icon: "exclamationmark.triangle.fill",
            color: .green
        )
    }
    .padding()
    .frame(width: 500)
}
