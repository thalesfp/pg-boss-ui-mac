//
//  SchemaV11Provider.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Schema provider for pg-boss v11+
/// Uses snake_case columns with expire_seconds instead of expire_in
/// No archive table (removed in v11), uses partitioning
struct SchemaV11Provider: SchemaProvider {
    let version: PgBossVersion = .v11Plus
    let schema: String

    let jobColumns: JobColumnMapping = .v11Plus

    let scheduleColumns: ScheduleColumnMapping? = .snakeCaseV11Plus

    nonisolated init(schema: String = "pgboss") {
        self.schema = schema
    }

    /// Override to handle expire_seconds (integer) instead of expire_in (interval)
    func jobSelectColumns() -> String {
        let cols = jobColumns
        return """
            \(cols.id), \(cols.name), \(cols.state), \(cols.priority), \(cols.data)::text, \
            \(cols.createdOn), \(cols.startedOn), \(cols.completedOn), \
            \(cols.retryCount), \(cols.retryLimit), \(cols.output)::text, \
            \(cols.singletonKey), \(cols.singletonOn), \
            \(cols.expireIn), \(cols.keepUntil), \
            \(cols.startAfter), \(cols.retryDelay), \(cols.retryBackoff)
            """
    }

    func fetchSchedulesSQL() -> String? {
        let cols = scheduleColumns!
        return """
            SELECT \(cols.name), \(cols.key!), \(cols.cron), \(cols.timezone), \
            \(cols.data)::text, \(cols.options)::text, \
            \(cols.createdOn), \(cols.updatedOn)
            FROM \(schema).schedule
            ORDER BY \(cols.name), \(cols.key!)
            """
    }

    func fetchQueueConfigSQL() -> String? {
        """
        SELECT name, retention_seconds, deletion_seconds, expire_seconds, retry_limit, policy
        FROM \(schema).queue
        """
    }
}
