//
//  SchemaV10Provider.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Schema provider for pg-boss v10
/// Uses snake_case columns (created_on, started_on, etc.)
/// Has both archive and schedule tables
struct SchemaV10Provider: SchemaProvider {
    let version: PgBossVersion = .v10
    let schema: String

    let jobColumns: JobColumnMapping = .snakeCase

    let scheduleColumns: ScheduleColumnMapping? = .snakeCaseV10

    nonisolated init(schema: String = "pgboss") {
        self.schema = schema
    }

    func fetchSchedulesSQL() -> String? {
        let cols = scheduleColumns!
        return """
            SELECT \(cols.name), \(cols.cron), \(cols.timezone), \
            \(cols.data)::text, \(cols.options)::text, \
            \(cols.createdOn), \(cols.updatedOn)
            FROM \(schema).schedule
            ORDER BY \(cols.name)
            """
    }

    func fetchQueueConfigSQL() -> String? {
        """
        SELECT name, retention_minutes, expire_seconds, retry_limit, policy
        FROM \(schema).queue
        """
    }
}
