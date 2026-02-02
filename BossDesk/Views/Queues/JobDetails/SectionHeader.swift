//
//  SectionHeader.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    VStack(alignment: .leading) {
        SectionHeader("TIMELINE")
        SectionHeader("METADATA")
        SectionHeader("INPUT DATA")
    }
    .padding()
}
