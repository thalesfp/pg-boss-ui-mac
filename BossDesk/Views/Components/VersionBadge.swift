//
//  VersionBadge.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import SwiftUI

/// A badge displaying the selected pg-boss version
struct VersionBadge: View {
    let version: PgBossVersion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
            Text(version.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(6)
        .help(helpText)
    }

    private var iconName: String {
        "server.rack"
    }

    private var backgroundColor: Color {
        switch version {
        case .legacy:
            return .orange.opacity(0.15)
        case .v9:
            return .yellow.opacity(0.15)
        case .v10:
            return .blue.opacity(0.15)
        case .v11Plus:
            return .green.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch version {
        case .legacy:
            return .orange
        case .v9:
            return .yellow
        case .v10:
            return .blue
        case .v11Plus:
            return .green
        }
    }

    private var helpText: String {
        var features: [String] = []

        if version.hasSnakeCaseColumns {
            features.append("snake_case columns")
        } else {
            features.append("camelCase columns")
        }

        if version.hasScheduleTable {
            features.append("schedules supported")
        }

        if version.hasArchiveTables {
            features.append("archive tables")
        }

        if version.usesPartitioning {
            features.append("partitioned tables")
        }

        return "Version: \(version.displayName)\n\(features.joined(separator: ", "))"
    }
}

#Preview("v11+") {
    VersionBadge(version: .v11Plus)
        .padding()
}

#Preview("v10") {
    VersionBadge(version: .v10)
        .padding()
}

#Preview("v9") {
    VersionBadge(version: .v9)
        .padding()
}

#Preview("Legacy") {
    VersionBadge(version: .legacy)
        .padding()
}

