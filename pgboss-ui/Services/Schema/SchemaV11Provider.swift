//
//  SchemaV11Provider.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Schema provider for pg-boss v11+
/// Uses snake_case columns (same as v10)
/// No archive table (removed in v11), uses partitioning
struct SchemaV11Provider: SchemaProvider {
    let version: PgBossVersion = .v11Plus
    let schema: String

    let jobColumns: JobColumnMapping = .snakeCase

    let scheduleColumns: ScheduleColumnMapping? = .snakeCase

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
        SELECT name, retention_seconds, deletion_seconds, expire_seconds, retry_limit, policy
        FROM \(schema).queue
        """
    }
}
