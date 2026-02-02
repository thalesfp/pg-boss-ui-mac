//
//  QueueService.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import Foundation
import PostgresClientKit

struct QueueService {
    enum QueueServiceError: LocalizedError {
        case connectionFailed(String)
        case queryFailed(String)
        case invalidData(String)

        var errorDescription: String? {
            switch self {
            case .connectionFailed(let reason):
                return "Connection failed: \(reason)"
            case .queryFailed(let reason):
                return "Query failed: \(reason)"
            case .invalidData(let reason):
                return "Invalid data: \(reason)"
            }
        }
    }

    static func fetchQueues(_ connection: Connection, provider: any SchemaProvider) async throws -> [Queue] {
        let isV11Plus = provider.adapterGroup == .snakeCaseV11Plus

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    // Fetch queue configs if supported by this schema version
                    var configsByName: [String: QueueConfig] = [:]
                    if let configSQL = provider.fetchQueueConfigSQL() {
                        let configStatement = try conn.prepareStatement(text: configSQL)
                        defer { configStatement.close() }

                        let configCursor = try configStatement.execute()
                        defer { configCursor.close() }

                        for row in configCursor {
                            let columns = try row.get().columns
                            let name = try columns[0].string()

                            let config: QueueConfig
                            if isV11Plus {
                                // v11: retention_seconds, deletion_seconds, expire_seconds, retry_limit, policy
                                let retentionSeconds = try columns[1].optionalInt()
                                let deletionSeconds = try columns[2].optionalInt()
                                let expireSeconds = try columns[3].optionalInt()
                                let retryLimit = try columns[4].optionalInt()
                                let policy = try columns[5].optionalString()
                                config = QueueConfig(
                                    retentionSeconds: retentionSeconds,
                                    deletionSeconds: deletionSeconds,
                                    expireSeconds: expireSeconds,
                                    retryLimit: retryLimit,
                                    policy: policy
                                )
                            } else {
                                // v10: retention_minutes, expire_seconds, retry_limit, policy
                                let retentionMinutes = try columns[1].optionalInt()
                                let expireSeconds = try columns[2].optionalInt()
                                let retryLimit = try columns[3].optionalInt()
                                let policy = try columns[4].optionalString()
                                config = QueueConfig(
                                    retentionSeconds: retentionMinutes.map { $0 * 60 },  // Convert to seconds if present
                                    deletionSeconds: nil,
                                    expireSeconds: expireSeconds,
                                    retryLimit: retryLimit,
                                    policy: policy
                                )
                            }
                            configsByName[name] = config
                        }
                    }

                    let sql = provider.fetchQueuesSQL()

                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute()
                    defer { cursor.close() }

                    var queues: [Queue] = []

                    for row in cursor {
                        let columns = try row.get().columns

                        let name = try columns[0].string()
                        let created = try columns[1].int()
                        let retry = try columns[2].int()
                        let active = try columns[3].int()
                        let completed = try columns[4].int()
                        let failed = try columns[5].int()
                        let cancelled = try columns[6].int()

                        let stats = QueueStats(
                            created: created,
                            retry: retry,
                            active: active,
                            completed: completed,
                            failed: failed,
                            cancelled: cancelled
                        )

                        queues.append(Queue(id: name, stats: stats, config: configsByName[name]))
                    }

                    continuation.resume(returning: queues)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    static func fetchJobs(
        _ connection: Connection,
        provider: any SchemaProvider,
        queueName: String,
        state: JobState?,
        searchText: String?,
        searchField: JobSearchField?,
        sortBy: JobSortField,
        sortOrder: SortOrder,
        limit: Int,
        offset: Int
    ) async throws -> (jobs: [Job], total: Int) {
        // Capture values for use in closure
        let hasStateFilter = state != nil
        let hasSearchFilter = searchText != nil && searchField != nil && !(searchText?.isEmpty ?? true)
        let searchPattern = searchText.map { "%\($0)%" }
        let stateRawValue = state?.rawValue
        let jobColumns = provider.jobColumns
        let sortColumn = sortBy.columnName(for: jobColumns)
        let sortDirection = sortOrder.rawValue

        let countSql = provider.countJobsSQL(
            hasStateFilter: hasStateFilter,
            searchField: searchField,
            searchText: searchText
        )
        let fetchSql = provider.fetchJobsSQL(
            hasStateFilter: hasStateFilter,
            searchField: searchField,
            searchText: searchText,
            sortColumn: sortColumn,
            sortDirection: sortDirection
        )

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    // Build parameter values for count query
                    var countParams: [String] = [queueName]
                    if let stateValue = stateRawValue {
                        countParams.append(stateValue)
                    }
                    if hasSearchFilter, let pattern = searchPattern {
                        countParams.append(pattern)
                    }

                    // First, get total count
                    let countStatement = try conn.prepareStatement(text: countSql)
                    defer { countStatement.close() }

                    let countCursor = try countStatement.execute(parameterValues: countParams)
                    defer { countCursor.close() }

                    var total = 0
                    for row in countCursor {
                        total = try row.get().columns[0].int()
                    }

                    let statement = try conn.prepareStatement(text: fetchSql)
                    defer { statement.close() }

                    // Build parameter values for main query - execute with proper parameter handling
                    let cursor: Cursor
                    if hasStateFilter && hasSearchFilter {
                        cursor = try statement.execute(parameterValues: [queueName, stateRawValue!, searchPattern!, limit, offset])
                    } else if hasStateFilter {
                        cursor = try statement.execute(parameterValues: [queueName, stateRawValue!, limit, offset])
                    } else if hasSearchFilter {
                        cursor = try statement.execute(parameterValues: [queueName, searchPattern!, limit, offset])
                    } else {
                        cursor = try statement.execute(parameterValues: [queueName, limit, offset])
                    }
                    defer { cursor.close() }

                    var jobs: [Job] = []

                    for row in cursor {
                        let columns = try row.get().columns

                        let idString = try columns[0].string()
                        guard let id = UUID(uuidString: idString) else {
                            continue
                        }

                        let name = try columns[1].string()
                        let stateString = try columns[2].string()
                        let jobState = JobState(rawValue: stateString) ?? .created
                        let priority = try columns[3].int()
                        let data = try columns[4].optionalString() ?? "{}"

                        let createdOn = try columns[5].timestampWithTimeZone().date
                        let startedOn = try? columns[6].timestampWithTimeZone().date
                        let completedOn = try? columns[7].timestampWithTimeZone().date

                        let retryCount = try columns[8].int()
                        let retryLimit = try columns[9].int()
                        let output = try columns[10].optionalString()

                        // Job-level settings
                        let singletonKey = try columns[11].optionalString()
                        let singletonOn = try? columns[12].timestampWithTimeZone().date
                        let expireInSeconds = try columns[13].optionalInt()
                        let expireIn = expireInSeconds.map { TimeInterval($0) }
                        let keepUntil = try? columns[14].timestampWithTimeZone().date
                        let startAfter = try? columns[15].timestampWithTimeZone().date
                        let retryDelaySeconds = try columns[16].optionalInt()
                        let retryDelay = retryDelaySeconds.map { TimeInterval($0) }
                        let retryBackoff = try columns[17].optionalBool()

                        let job = Job(
                            id: id,
                            name: name,
                            state: jobState,
                            priority: priority,
                            data: data,
                            createdOn: createdOn,
                            startedOn: startedOn,
                            completedOn: completedOn,
                            retryCount: retryCount,
                            retryLimit: retryLimit,
                            output: output,
                            singletonKey: singletonKey,
                            singletonOn: singletonOn,
                            expireIn: expireIn,
                            keepUntil: keepUntil,
                            startAfter: startAfter,
                            retryDelay: retryDelay,
                            retryBackoff: retryBackoff
                        )

                        jobs.append(job)
                    }

                    continuation.resume(returning: (jobs: jobs, total: total))
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    static func retryJob(_ connection: Connection, provider: any SchemaProvider, jobId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let sql = provider.updateJobStateSQL()
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    try statement.execute(parameterValues: ["retry", jobId.uuidString])

                    continuation.resume()
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    static func cancelJob(_ connection: Connection, provider: any SchemaProvider, jobId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let sql = provider.updateJobStateSQL()
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    try statement.execute(parameterValues: ["cancelled", jobId.uuidString])

                    continuation.resume()
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    static func deleteJob(_ connection: Connection, provider: any SchemaProvider, jobId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let sql = provider.deleteJobSQL()
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    try statement.execute(parameterValues: [jobId.uuidString])

                    continuation.resume()
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Bulk Operations

    static func retryAllFailed(_ connection: Connection, provider: any SchemaProvider, queueName: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let sql = provider.retryAllFailedSQL()
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute(parameterValues: [queueName])
                    let affectedRows = cursor.rowCount ?? 0
                    cursor.close()

                    continuation.resume(returning: affectedRows)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    static func cancelAllPending(_ connection: Connection, provider: any SchemaProvider, queueName: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let sql = provider.cancelAllPendingSQL()
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute(parameterValues: [queueName])
                    let affectedRows = cursor.rowCount ?? 0
                    cursor.close()

                    continuation.resume(returning: affectedRows)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    static func purgeCompleted(_ connection: Connection, provider: any SchemaProvider, queueName: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let sql = provider.purgeCompletedSQL()
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute(parameterValues: [queueName])
                    let affectedRows = cursor.rowCount ?? 0
                    cursor.close()

                    continuation.resume(returning: affectedRows)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    static func purgeFailed(_ connection: Connection, provider: any SchemaProvider, queueName: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let sql = provider.purgeFailedSQL()
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute(parameterValues: [queueName])
                    let affectedRows = cursor.rowCount ?? 0
                    cursor.close()

                    continuation.resume(returning: affectedRows)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Dashboard

    /// Fetch recent completion metrics (last 15 minutes)
    static func fetchRecentCompletionMetrics(
        _ connection: Connection,
        provider: any SchemaProvider,
        queueName: String
    ) async throws -> RecentCompletionMetrics {
        let sql = provider.recentCompletionMetricsSQL()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute(parameterValues: [queueName])
                    defer { cursor.close() }

                    var completedCount = 0
                    var avgProcessingTime: TimeInterval?

                    for row in cursor {
                        let columns = try row.get().columns
                        completedCount = try columns[0].int()
                        avgProcessingTime = try columns[1].optionalDouble()
                    }

                    let metrics = RecentCompletionMetrics(
                        completedCount: completedCount,
                        avgProcessingTime: avgProcessingTime
                    )

                    continuation.resume(returning: metrics)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch live queue status (not time-filtered)
    static func fetchQueueStatus(
        _ connection: Connection,
        provider: any SchemaProvider,
        queueName: String,
        recentMetrics: RecentCompletionMetrics?
    ) async throws -> QueueStatus {
        let sql = provider.queueStatusSQL()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute(parameterValues: [queueName])
                    defer { cursor.close() }

                    var createdJobs = 0
                    var activeJobs = 0
                    var retryJobs = 0

                    for row in cursor {
                        let columns = try row.get().columns
                        createdJobs = try columns[0].int()
                        activeJobs = try columns[1].int()
                        retryJobs = try columns[2].int()
                    }

                    // Calculate estimated completion using live pending count and recent completion metrics
                    let estimatedCompletion: TimeInterval?
                    if let metrics = recentMetrics,
                       metrics.completedCount > 0,
                       let avgTime = metrics.avgProcessingTime,
                       avgTime > 0 {
                        // Estimate based on pending jobs and average processing time
                        let pendingJobs = createdJobs + retryJobs
                        estimatedCompletion = Double(pendingJobs) * avgTime
                    } else {
                        estimatedCompletion = nil
                    }

                    let status = QueueStatus(
                        createdJobs: createdJobs,
                        activeJobs: activeJobs,
                        retryJobs: retryJobs,
                        estimatedCompletion: estimatedCompletion
                    )

                    continuation.resume(returning: status)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch historical dashboard stats (time-filtered)
    static func fetchDashboardStats(
        _ connection: Connection,
        provider: any SchemaProvider,
        queueName: String,
        timeRange: TimeRange
    ) async throws -> DashboardStats {
        let hasTimeFilter = timeRange != .all
        let sql = provider.dashboardStatsSQL(hasTimeFilter: hasTimeFilter)

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor: Cursor
                    if hasTimeFilter, let startDate = timeRange.startDate() {
                        let timestamp = PostgresTimestampWithTimeZone(date: startDate)
                        cursor = try statement.execute(parameterValues: [queueName, timestamp])
                    } else {
                        cursor = try statement.execute(parameterValues: [queueName])
                    }
                    defer { cursor.close() }

                    var totalJobs = 0
                    var completedJobs = 0
                    var failedJobs = 0
                    var cancelledJobs = 0
                    var avgProcessingTime: TimeInterval?
                    var avgWaitTime: TimeInterval?
                    var avgEndToEndTime: TimeInterval?

                    for row in cursor {
                        let columns = try row.get().columns
                        totalJobs = try columns[0].int()
                        completedJobs = try columns[1].int()
                        failedJobs = try columns[2].int()
                        cancelledJobs = try columns[3].int()
                        avgProcessingTime = try columns[4].optionalDouble()
                        avgWaitTime = try columns[5].optionalDouble()
                        avgEndToEndTime = try columns[6].optionalDouble()
                    }

                    let stats = DashboardStats(
                        totalJobs: totalJobs,
                        completedJobs: completedJobs,
                        failedJobs: failedJobs,
                        cancelledJobs: cancelledJobs,
                        timeRange: timeRange,
                        avgProcessingTime: avgProcessingTime,
                        avgWaitTime: avgWaitTime,
                        avgEndToEndTime: avgEndToEndTime
                    )

                    continuation.resume(returning: stats)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch throughput data for a queue within a time range
    static func fetchThroughput(
        _ connection: Connection,
        provider: any SchemaProvider,
        queueName: String,
        timeRange: TimeRange
    ) async throws -> [ThroughputDataPoint] {
        let bucketSeconds = timeRange.bucketIntervalSeconds
        let sql = provider.throughputSQL(bucketSeconds: bucketSeconds)

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    // For "all" time range, use a very old date as start
                    let startDate = timeRange.startDate() ?? Date(timeIntervalSince1970: 0)
                    let timestamp = PostgresTimestampWithTimeZone(date: startDate)

                    let cursor = try statement.execute(parameterValues: [queueName, timestamp])
                    defer { cursor.close() }

                    var points: [ThroughputDataPoint] = []

                    for row in cursor {
                        let columns = try row.get().columns
                        let bucketTimestamp = try columns[0].timestampWithTimeZone().date
                        let completedCount = try columns[1].int()
                        let failedCount = try columns[2].int()

                        // Always add both points, even if count is 0
                        // This ensures both series have the same x-axis coverage
                        points.append(ThroughputDataPoint(
                            timestamp: bucketTimestamp,
                            category: "Completed",
                            count: completedCount
                        ))

                        points.append(ThroughputDataPoint(
                            timestamp: bucketTimestamp,
                            category: "Failed",
                            count: failedCount
                        ))
                    }

                    continuation.resume(returning: points)
                } catch let error as PostgresError {
                    continuation.resume(throwing: QueueServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: QueueServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }
}
