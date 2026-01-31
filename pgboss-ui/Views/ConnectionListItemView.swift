//
//  ConnectionListItemView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct ConnectionListItemView: View {
    let connection: Connection

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
            Text(connection.name)
                .font(.headline)
            Text("\(connection.host):\(connection.port)/\(connection.database)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, DesignTokens.Spacing.xxSmall)
    }
}

#Preview {
    ConnectionListItemView(connection: MockData.connections[0])
        .padding()
}
