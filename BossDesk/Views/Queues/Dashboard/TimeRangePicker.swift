//
//  TimeRangePicker.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

struct TimeRangePicker: View {
    @Binding var selection: TimeRange

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xSmall) {
            ForEach(TimeRange.allCases) { range in
                Button {
                    selection = range
                } label: {
                    Text(range.rawValue)
                        .font(.subheadline)
                        .fontWeight(selection == range ? .semibold : .regular)
                        .padding(.horizontal, DesignTokens.Spacing.medium)
                        .padding(.vertical, DesignTokens.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(selection == range ? Color.accentColor : Color.clear)
                        )
                        .foregroundStyle(selection == range ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.xSmall)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    @Previewable @State var selection: TimeRange = .twentyFourHours
    TimeRangePicker(selection: $selection)
        .padding()
}
