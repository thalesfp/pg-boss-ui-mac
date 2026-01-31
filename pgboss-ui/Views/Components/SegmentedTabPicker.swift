//
//  SegmentedTabPicker.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

struct SegmentedTabPicker<T: Hashable & CaseIterable>: View where T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    let displayName: (T) -> String
    let icon: (T) -> String

    @Namespace private var segmentedControl

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = item
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: icon(item))
                        Text(displayName(item))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if selection == item {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.background)
                                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                                    .matchedGeometryEffect(id: "selection", in: segmentedControl)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == item ? .primary : .secondary)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
        )
    }
}

#Preview {
    @Previewable @State var selectedTab: QueueDetailTab = .jobs

    SegmentedTabPicker(
        selection: $selectedTab,
        displayName: { $0.displayName },
        icon: { $0.icon }
    )
    .padding()
}
