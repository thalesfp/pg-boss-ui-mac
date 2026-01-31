//
//  SchemaLegacyProvider.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Schema provider for pg-boss v7/v8 (legacy versions)
/// Uses camelCase columns, may have fewer features
struct SchemaLegacyProvider: SchemaProvider {
    let version: PgBossVersion = .legacy

    let jobColumns: JobColumnMapping = .camelCase

    // Legacy versions don't have schedule table
    let scheduleColumns: ScheduleColumnMapping? = nil

    nonisolated init() {}

    func fetchSchedulesSQL() -> String? {
        nil
    }
}
