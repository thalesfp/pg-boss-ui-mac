//
//  SchemaV10Provider.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Schema provider for pg-boss v10
/// Uses snake_case columns (created_on, started_on, etc.)
/// Has both archive and schedule tables
struct SchemaV10Provider: SchemaProvider {
    let version: PgBossVersion = .v10

    let jobColumns: JobColumnMapping = .snakeCase

    let scheduleColumns: ScheduleColumnMapping? = .snakeCase

    nonisolated init() {}

    func fetchSchedulesSQL() -> String? {
        let cols = scheduleColumns!
        return """
            SELECT \(cols.name), \(cols.cron), \(cols.timezone), \
            \(cols.data)::text, \(cols.options)::text, \
            \(cols.createdOn), \(cols.updatedOn)
            FROM pgboss.schedule
            ORDER BY \(cols.name)
            """
    }

    func fetchQueueConfigSQL() -> String? {
        """
        SELECT name, retention_minutes, expire_seconds, retry_limit, policy
        FROM pgboss.queue
        """
    }
}
