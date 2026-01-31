//
//  SchemaProvider.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

/// Column name mappings for job table fields across pg-boss versions
struct JobColumnMapping {
    let id: String
    let name: String
    let state: String
    let priority: String
    let data: String
    let createdOn: String
    let startedOn: String
    let completedOn: String
    let retryCount: String
    let retryLimit: String
    let output: String
    let singletonKey: String
    let singletonOn: String
    let expireIn: String
    let keepUntil: String
    let startAfter: String
    let retryDelay: String
    let retryBackoff: String

    /// v9 and earlier: camelCase columns
    static let camelCase = JobColumnMapping(
        id: "id",
        name: "name",
        state: "state",
        priority: "priority",
        data: "data",
        createdOn: "createdon",
        startedOn: "startedon",
        completedOn: "completedon",
        retryCount: "retrycount",
        retryLimit: "retrylimit",
        output: "output",
        singletonKey: "singletonkey",
        singletonOn: "singletonon",
        expireIn: "expirein",
        keepUntil: "keepuntil",
        startAfter: "startafter",
        retryDelay: "retrydelay",
        retryBackoff: "retrybackoff"
    )

    /// v10+: snake_case columns
    static let snakeCase = JobColumnMapping(
        id: "id",
        name: "name",
        state: "state",
        priority: "priority",
        data: "data",
        createdOn: "created_on",
        startedOn: "started_on",
        completedOn: "completed_on",
        retryCount: "retry_count",
        retryLimit: "retry_limit",
        output: "output",
        singletonKey: "singleton_key",
        singletonOn: "singleton_on",
        expireIn: "expire_in",
        keepUntil: "keep_until",
        startAfter: "start_after",
        retryDelay: "retry_delay",
        retryBackoff: "retry_backoff"
    )
}

/// Column name mappings for schedule table fields
struct ScheduleColumnMapping {
    let name: String
    let cron: String
    let timezone: String
    let data: String
    let options: String
    let createdOn: String
    let updatedOn: String

    /// v10+: snake_case columns (schedule table didn't exist before v10)
    static let snakeCase = ScheduleColumnMapping(
        name: "name",
        cron: "cron",
        timezone: "timezone",
        data: "data",
        options: "options",
        createdOn: "created_on",
        updatedOn: "updated_on"
    )
}

/// Protocol defining SQL queries and column mappings for a pg-boss schema version
protocol SchemaProvider {
    /// The pg-boss version this provider supports
    var version: PgBossVersion { get }

    /// Column mappings for the job table
    var jobColumns: JobColumnMapping { get }

    /// Column mappings for the schedule table (nil if not supported)
    var scheduleColumns: ScheduleColumnMapping? { get }

    // MARK: - Queue Queries

    /// SQL to fetch queue statistics grouped by name
    func fetchQueuesSQL() -> String

    // MARK: - Job Queries

    /// SQL to count jobs with optional state and search filters
    /// - Parameters:
    ///   - hasStateFilter: Whether a state filter parameter will be provided
    ///   - searchField: Optional search field for text search
    ///   - searchText: Optional search text (used for ILIKE pattern)
    /// - Returns: SQL with $1 for queue name, $2 for state (if hasStateFilter), then search pattern
    func countJobsSQL(hasStateFilter: Bool, searchField: JobSearchField?, searchText: String?) -> String

    /// SQL to fetch jobs with sorting and pagination
    /// - Parameters:
    ///   - hasStateFilter: Whether a state filter parameter will be provided
    ///   - searchField: Optional search field for text search
    ///   - searchText: Optional search text (used for ILIKE pattern)
    ///   - sortColumn: The column name to sort by
    ///   - sortDirection: ASC or DESC
    /// - Returns: SQL with parameters for queue name, optional state, optional search, limit, offset
    func fetchJobsSQL(hasStateFilter: Bool, searchField: JobSearchField?, searchText: String?, sortColumn: String, sortDirection: String) -> String

    /// Column select list for job queries
    func jobSelectColumns() -> String

    // MARK: - Job Mutations

    /// SQL to update a job's state
    func updateJobStateSQL() -> String

    /// SQL to delete a job by ID
    func deleteJobSQL() -> String

    /// SQL to retry all failed jobs in a queue
    func retryAllFailedSQL() -> String

    /// SQL to cancel all pending jobs in a queue
    func cancelAllPendingSQL() -> String

    /// SQL to purge completed jobs from a queue
    func purgeCompletedSQL() -> String

    /// SQL to purge failed jobs from a queue
    func purgeFailedSQL() -> String

    // MARK: - Schedule Queries

    /// SQL to fetch schedules (returns nil if schedules not supported)
    func fetchSchedulesSQL() -> String?

    // MARK: - Dashboard Queries

    /// SQL to fetch live queue status (not time-filtered)
    /// - Returns: SQL with $1 for queue name
    func queueStatusSQL() -> String

    /// SQL to fetch historical dashboard statistics for a queue (time-filtered)
    /// - Parameter hasTimeFilter: Whether a time filter parameter will be provided
    /// - Returns: SQL with $1 for queue name, $2 for start date (if hasTimeFilter)
    func dashboardStatsSQL(hasTimeFilter: Bool) -> String

    // MARK: - Queue Config Queries

    /// SQL to fetch queue configuration from the pgboss.queue table
    /// Returns nil for versions without a queue table (v9 and earlier)
    func fetchQueueConfigSQL() -> String?

    // MARK: - Throughput Queries

    /// SQL to fetch throughput data bucketed by time
    /// - Parameter bucketSeconds: The size of each time bucket in seconds
    /// - Returns: SQL with $1 for queue name, $2 for start date
    func throughputSQL(bucketSeconds: Int) -> String

    // MARK: - Recent Completion Queries

    /// SQL to fetch average processing time from recently completed jobs
    /// - Returns: SQL with $1 for queue name
    func recentCompletionMetricsSQL() -> String
}

// MARK: - Default Implementations

extension SchemaProvider {
    func fetchQueuesSQL() -> String {
        """
        SELECT name,
            COUNT(*) FILTER (WHERE state = 'created') as created,
            COUNT(*) FILTER (WHERE state = 'retry') as retry,
            COUNT(*) FILTER (WHERE state = 'active') as active,
            COUNT(*) FILTER (WHERE state = 'completed') as completed,
            COUNT(*) FILTER (WHERE state = 'failed') as failed,
            COUNT(*) FILTER (WHERE state = 'cancelled') as cancelled
        FROM pgboss.job
        GROUP BY name
        ORDER BY name
        """
    }

    func countJobsSQL(hasStateFilter: Bool, searchField: JobSearchField?, searchText: String?) -> String {
        var conditions = ["name = $1"]
        var paramIndex = 2

        if hasStateFilter {
            conditions.append("state = $\(paramIndex)")
            paramIndex += 1
        }

        if let field = searchField, let text = searchText, !text.isEmpty {
            let columnExpr = searchColumnExpression(for: field)
            conditions.append("\(columnExpr) ILIKE $\(paramIndex)")
        }

        let whereClause = conditions.joined(separator: " AND ")
        return "SELECT COUNT(*) FROM pgboss.job WHERE \(whereClause)"
    }

    func fetchJobsSQL(hasStateFilter: Bool, searchField: JobSearchField?, searchText: String?, sortColumn: String, sortDirection: String) -> String {
        var conditions = ["name = $1"]
        var paramIndex = 2

        if hasStateFilter {
            conditions.append("state = $\(paramIndex)")
            paramIndex += 1
        }

        if let field = searchField, let text = searchText, !text.isEmpty {
            let columnExpr = searchColumnExpression(for: field)
            conditions.append("\(columnExpr) ILIKE $\(paramIndex)")
            paramIndex += 1
        }

        let whereClause = conditions.joined(separator: " AND ")
        let limitParam = "$\(paramIndex)"
        let offsetParam = "$\(paramIndex + 1)"

        return """
            SELECT \(jobSelectColumns())
            FROM pgboss.job
            WHERE \(whereClause)
            ORDER BY \(sortColumn) \(sortDirection) NULLS LAST
            LIMIT \(limitParam) OFFSET \(offsetParam)
            """
    }

    /// Get the column expression for a search field
    func searchColumnExpression(for field: JobSearchField) -> String {
        let cols = jobColumns
        switch field {
        case .uuid:
            return "\(cols.id)::text"
        case .inputData:
            return "\(cols.data)::text"
        case .outputData:
            return "\(cols.output)::text"
        }
    }

    func jobSelectColumns() -> String {
        let cols = jobColumns
        return """
            \(cols.id), \(cols.name), \(cols.state), \(cols.priority), \(cols.data)::text, \
            \(cols.createdOn), \(cols.startedOn), \(cols.completedOn), \
            \(cols.retryCount), \(cols.retryLimit), \(cols.output)::text, \
            \(cols.singletonKey), \(cols.singletonOn), \
            EXTRACT(EPOCH FROM \(cols.expireIn))::int, \(cols.keepUntil), \
            \(cols.startAfter), \(cols.retryDelay), \(cols.retryBackoff)
            """
    }

    func updateJobStateSQL() -> String {
        "UPDATE pgboss.job SET state = $1 WHERE id = $2"
    }

    func deleteJobSQL() -> String {
        "DELETE FROM pgboss.job WHERE id = $1"
    }

    func retryAllFailedSQL() -> String {
        """
        UPDATE pgboss.job
        SET state = 'retry'
        WHERE name = $1 AND state = 'failed'
        """
    }

    func cancelAllPendingSQL() -> String {
        """
        UPDATE pgboss.job
        SET state = 'cancelled'
        WHERE name = $1 AND state IN ('created', 'retry')
        """
    }

    func purgeCompletedSQL() -> String {
        """
        DELETE FROM pgboss.job
        WHERE name = $1 AND state = 'completed'
        """
    }

    func purgeFailedSQL() -> String {
        """
        DELETE FROM pgboss.job
        WHERE name = $1 AND state = 'failed'
        """
    }

    func queueStatusSQL() -> String {
        """
        SELECT
            COUNT(*) FILTER (WHERE state = 'created') as created_jobs,
            COUNT(*) FILTER (WHERE state = 'active') as active_jobs,
            COUNT(*) FILTER (WHERE state = 'retry') as retry_jobs
        FROM pgboss.job
        WHERE name = $1
        """
    }

    func dashboardStatsSQL(hasTimeFilter: Bool) -> String {
        let cols = jobColumns
        let timeFilter = hasTimeFilter ? " AND \(cols.createdOn) >= $2" : ""

        return """
            SELECT
                COUNT(*) FILTER (WHERE true\(timeFilter)) as total_jobs,
                COUNT(*) FILTER (WHERE state = 'completed'\(timeFilter)) as completed_jobs,
                COUNT(*) FILTER (WHERE state = 'failed'\(timeFilter)) as failed_jobs,
                COUNT(*) FILTER (WHERE state = 'cancelled'\(timeFilter)) as cancelled_jobs,
                AVG(EXTRACT(EPOCH FROM (\(cols.completedOn) - \(cols.startedOn))))
                    FILTER (WHERE \(cols.completedOn) IS NOT NULL AND \(cols.startedOn) IS NOT NULL\(timeFilter)) as avg_processing_time,
                AVG(EXTRACT(EPOCH FROM (\(cols.startedOn) - \(cols.createdOn))))
                    FILTER (WHERE \(cols.startedOn) IS NOT NULL\(timeFilter)) as avg_wait_time,
                AVG(EXTRACT(EPOCH FROM (\(cols.completedOn) - \(cols.createdOn))))
                    FILTER (WHERE \(cols.completedOn) IS NOT NULL\(timeFilter)) as avg_end_to_end_time
            FROM pgboss.job
            WHERE name = $1
            """
    }

    func fetchQueueConfigSQL() -> String? {
        nil  // v9 and earlier don't have a queue table
    }

    func throughputSQL(bucketSeconds: Int) -> String {
        let cols = jobColumns
        return """
            WITH buckets AS (
                SELECT
                    to_timestamp(floor(EXTRACT(EPOCH FROM \(cols.completedOn)) / \(bucketSeconds)) * \(bucketSeconds)) as bucket,
                    state
                FROM pgboss.job
                WHERE name = $1
                  AND \(cols.completedOn) >= $2
                  AND state IN ('completed', 'failed')
            )
            SELECT
                bucket as timestamp,
                COUNT(*) FILTER (WHERE state = 'completed') as completed,
                COUNT(*) FILTER (WHERE state = 'failed') as failed
            FROM buckets
            GROUP BY bucket
            ORDER BY bucket
            """
    }

    func recentCompletionMetricsSQL() -> String {
        let cols = jobColumns
        return """
            SELECT
                COUNT(*) as completed_count,
                AVG(EXTRACT(EPOCH FROM (\(cols.completedOn) - \(cols.startedOn)))) as avg_processing_time
            FROM pgboss.job
            WHERE name = $1
                AND state = 'completed'
                AND \(cols.completedOn) >= NOW() - INTERVAL '15 minutes'
                AND \(cols.startedOn) IS NOT NULL
                AND \(cols.completedOn) IS NOT NULL
            """
    }
}
