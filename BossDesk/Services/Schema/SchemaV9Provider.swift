//
//  SchemaV9Provider.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Schema provider for pg-boss v9
/// Uses camelCase columns (createdon, startedon, etc.)
/// Has archive tables but no schedule table
struct SchemaV9Provider: SchemaProvider {
    let version: PgBossVersion = .v9
    let schema: String

    let jobColumns: JobColumnMapping = .camelCase

    // v9 doesn't have schedule table
    let scheduleColumns: ScheduleColumnMapping? = nil

    nonisolated init(schema: String = "pgboss") {
        self.schema = schema
    }

    func fetchSchedulesSQL() -> String? {
        nil
    }
}
