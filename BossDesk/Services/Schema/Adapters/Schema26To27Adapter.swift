//
//  Schema26To27Adapter.swift
//  BossDesk
//
//  Created by Claude Code on 2026-02-02.
//

import Foundation

/// Adapter for schema versions 26-27 (pg-boss v11.1+)
/// - snake_case column naming
/// - Uses expire_seconds (integer) instead of expire_in
/// - Has group_id and group_tier columns (schema 27)
struct Schema26To27Adapter: SchemaProvider {
    let adapterGroup: AdapterGroup = .snakeCaseV11Plus
    let supportedVersionRange: ClosedRange<Int> = 26...27
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

    func fetchQueueConfigSQL() -> String? {
        """
        SELECT name, retention_seconds, deletion_seconds, expire_seconds, retry_limit, policy
        FROM \(schema).queue
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
}
