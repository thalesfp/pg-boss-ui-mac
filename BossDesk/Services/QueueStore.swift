//
//  QueueStore.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import Foundation
import Observation

@Observable
class QueueStore {
    // Queue state
    var queues: [Queue] = []
    var selectedItem: SidebarSelection?

    // Schedule state
    var schedules: [Schedule] = []

    // Job state
    var jobs: [Job] = []
    var totalJobs: Int = 0
    var selectedJobIds: Set<UUID> = []

    var selectedJobs: [Job] {
        jobs.filter { selectedJobIds.contains($0.id) }
    }

    func selectAllJobs() {
        selectedJobIds = Set(jobs.map(\.id))
    }

    func clearSelection() {
        selectedJobIds.removeAll()
    }

    // Filters and sorting
    var stateFilter: JobState?
    var searchText: String = ""
    var searchField: JobSearchField = .uuid
    var sortBy: JobSortField = .createdOn
    var sortOrder: SortOrder = .descending
    var currentPage: Int = 0
    let pageSize: Int = 50

    // Dashboard state
    var dashboardTimeRange: TimeRange = .twentyFourHours
    var queueStatus: QueueStatus = .empty
    var dashboardStats: DashboardStats = .empty
    var throughputData: ThroughputData = .empty
    var isLoadingQueueStatus = false
    var isLoadingDashboard = false
    var isLoadingThroughput = false

    // Loading states
    var isLoadingQueues = false
    var isLoadingSchedules = false
    var isLoadingJobs = false
    var isMutatingJob = false
    var error: String?
    var mutationError: String?

    // Auto-refresh
    var autoRefreshEnabled = false
    var refreshInterval: TimeInterval = 30.0
    private var refreshTask: Task<Void, Never>?

    // Connection reference
    private var connection: Connection?

    // Schema provider (cached)
    private var schemaProvider: (any SchemaProvider)?

    /// Computed property for backward compatibility
    var selectedQueueId: String? {
        guard case .queue(let id) = selectedItem else { return nil }
        return id
    }

    var selectedQueue: Queue? {
        guard let id = selectedQueueId else { return nil }
        return queues.first { $0.id == id }
    }

    var selectedSchedule: Schedule? {
        guard case .schedule(let scheduleId) = selectedItem else { return nil }
        return schedules.first { $0.id == scheduleId }
    }

    var totalPages: Int {
        guard totalJobs > 0 else { return 1 }
        return (totalJobs + pageSize - 1) / pageSize
    }

    var hasNextPage: Bool {
        currentPage < totalPages - 1
    }

    var hasPreviousPage: Bool {
        currentPage > 0
    }

    /// The pg-boss version from the current connection
    var pgBossVersion: PgBossVersion? {
        connection?.pgBossVersion
    }

    /// Whether schedules are supported by the selected version
    var supportsSchedules: Bool {
        pgBossVersion?.hasScheduleTable ?? false
    }

    func setConnection(_ connection: Connection) {
        self.connection = connection
        // Clear cached provider when connection changes
        self.schemaProvider = nil
    }

    /// Get or create the schema provider for the current connection
    private func getProvider() throws -> any SchemaProvider {
        if let provider = schemaProvider {
            return provider
        }

        guard let connection = connection else {
            throw QueueService.QueueServiceError.connectionFailed("No connection configured")
        }

        // Use the user-selected pg-boss version and schema from the connection
        let provider = ConnectionManager.createProviderSync(
            for: connection.pgBossVersion,
            schema: connection.schema
        )
        self.schemaProvider = provider
        return provider
    }

    func startAutoRefresh() {
        stopAutoRefresh()

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.autoRefreshEnabled else {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }

                await self.refreshQueues()
                await self.refreshSchedules()

                if self.selectedQueueId != nil {
                    await self.refreshJobs()
                    await self.refreshQueueStatus()
                }

                try? await Task.sleep(for: .seconds(self.refreshInterval))
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    @MainActor
    func refreshQueues() async {
        guard let connection = connection else {
            error = "No connection configured"
            return
        }

        isLoadingQueues = true
        error = nil

        do {
            let provider = try getProvider()

            queues = try await QueueService.fetchQueues(connection, provider: provider)

            // If selected queue no longer exists, clear selection
            if let selectedId = selectedQueueId, !queues.contains(where: { $0.id == selectedId }) {
                selectedItem = nil
                jobs = []
                totalJobs = 0
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoadingQueues = false
    }

    @MainActor
    func refreshSchedules() async {
        guard let connection = connection else {
            return
        }

        // Skip if version doesn't support schedules
        if let version = pgBossVersion, !version.hasScheduleTable {
            schedules = []
            return
        }

        isLoadingSchedules = true

        do {
            let provider = try getProvider()
            schedules = try await ScheduleService.fetchSchedules(connection, provider: provider)
        } catch {
            // Silently handle schedule fetch errors - schedules may not exist in older pg-boss versions
            schedules = []
        }

        isLoadingSchedules = false
    }

    @MainActor
    func refreshJobs() async {
        guard let connection = connection, let queueName = selectedQueueId else {
            jobs = []
            totalJobs = 0
            return
        }

        isLoadingJobs = true

        do {
            let provider = try getProvider()

            let result = try await QueueService.fetchJobs(
                connection,
                provider: provider,
                queueName: queueName,
                state: stateFilter,
                searchText: searchText.isEmpty ? nil : searchText,
                searchField: searchText.isEmpty ? nil : searchField,
                sortBy: sortBy,
                sortOrder: sortOrder,
                limit: pageSize,
                offset: currentPage * pageSize
            )

            jobs = result.jobs
            totalJobs = result.total

            // Clamp current page to valid range if job count has shrunk
            if currentPage >= totalPages {
                currentPage = max(0, totalPages - 1)
                // Refetch for the new valid page
                await refreshJobs()
                return
            }

        } catch {
            self.error = error.localizedDescription
            jobs = []
            totalJobs = 0
        }

        isLoadingJobs = false
    }

    @MainActor
    func selectQueue(_ queueId: String?) async {
        selectedItem = queueId.map { .queue($0) }
        selectedJobIds.removeAll()
        currentPage = 0
        await refreshJobs()
    }

    @MainActor
    func setStateFilter(_ state: JobState?) async {
        stateFilter = state
        currentPage = 0
        await refreshJobs()
    }

    @MainActor
    func setSearchFilter(text: String, field: JobSearchField) async {
        searchText = text
        searchField = field
        currentPage = 0
        await refreshJobs()
    }

    @MainActor
    func setSorting(by field: JobSortField, order: SortOrder) async {
        sortBy = field
        sortOrder = order
        await refreshJobs()
    }

    @MainActor
    func toggleSortOrder() async {
        sortOrder.toggle()
        await refreshJobs()
    }

    @MainActor
    func nextPage() async {
        guard hasNextPage else { return }
        currentPage += 1
        await refreshJobs()
    }

    @MainActor
    func previousPage() async {
        guard hasPreviousPage else { return }
        currentPage -= 1
        await refreshJobs()
    }

    @MainActor
    func goToPage(_ page: Int) async {
        guard page >= 0 && page < totalPages else { return }
        currentPage = page
        await refreshJobs()
    }

    func clearError() {
        error = nil
    }

    func clearMutationError() {
        mutationError = nil
    }

    // MARK: - Dashboard

    @MainActor
    func refreshQueueStatus() async {
        guard let connection = connection, let queueName = selectedQueueId else {
            queueStatus = .empty
            return
        }

        isLoadingQueueStatus = true

        do {
            let provider = try getProvider()

            // Fetch recent completion metrics for estimated completion calculation
            let recentMetrics = try await QueueService.fetchRecentCompletionMetrics(
                connection,
                provider: provider,
                queueName: queueName
            )

            queueStatus = try await QueueService.fetchQueueStatus(
                connection,
                provider: provider,
                queueName: queueName,
                recentMetrics: recentMetrics
            )
        } catch {
            self.error = error.localizedDescription
            queueStatus = .empty
        }

        isLoadingQueueStatus = false
    }

    @MainActor
    func refreshDashboardStats() async {
        guard let connection = connection, let queueName = selectedQueueId else {
            dashboardStats = .empty
            return
        }

        isLoadingDashboard = true

        do {
            let provider = try getProvider()
            dashboardStats = try await QueueService.fetchDashboardStats(
                connection,
                provider: provider,
                queueName: queueName,
                timeRange: dashboardTimeRange
            )

            // Refresh throughput data for the chart
            await refreshThroughput()

            // After updating historical stats, refresh queue status to update estimated completion
            await refreshQueueStatus()
        } catch {
            self.error = error.localizedDescription
            dashboardStats = .empty
        }

        isLoadingDashboard = false
    }

    @MainActor
    func refreshThroughput() async {
        guard let connection = connection, let queueName = selectedQueueId else {
            throughputData = .empty
            return
        }

        isLoadingThroughput = true

        do {
            let provider = try getProvider()
            let now = Date()
            let points = try await QueueService.fetchThroughput(
                connection,
                provider: provider,
                queueName: queueName,
                timeRange: dashboardTimeRange
            )
            let normalizedPoints = normalizeThroughputPoints(points, timeRange: dashboardTimeRange, now: now)
            throughputData = ThroughputData(points: normalizedPoints)
        } catch {
            self.error = error.localizedDescription
            throughputData = .empty
        }

        isLoadingThroughput = false
    }

    private func normalizeThroughputPoints(
        _ points: [ThroughputDataPoint],
        timeRange: TimeRange,
        now: Date = Date()
    ) -> [ThroughputDataPoint] {
        guard !points.isEmpty else { return points }

        let bucketSeconds = timeRange.bucketIntervalSeconds
        guard bucketSeconds > 0 else { return points }

        let bucketSize = Double(bucketSeconds)
        func bucketKey(for date: Date) -> Int {
            let seconds = date.timeIntervalSince1970
            return Int(floor(seconds / bucketSize) * bucketSize)
        }

        var bucketed: [Int: [String: Int]] = [:]
        var categorySet: Set<String> = []

        for point in points {
            let key = bucketKey(for: point.timestamp)
            var counts = bucketed[key, default: [:]]
            counts[point.category, default: 0] += point.count
            bucketed[key] = counts
            categorySet.insert(point.category)
        }

        guard let minKey = bucketed.keys.min(),
              let maxKey = bucketed.keys.max() else {
            return points
        }

        let startKey: Int
        let endKey: Int

        if timeRange == .all {
            startKey = minKey
            endKey = maxKey
        } else if let rangeStart = timeRange.startDate(from: now) {
            startKey = bucketKey(for: rangeStart)
            endKey = bucketKey(for: now)
        } else {
            startKey = minKey
            endKey = maxKey
        }

        guard endKey >= startKey else { return points }

        let preferredOrder = ["Completed", "Failed"]
        let categories = preferredOrder.filter { categorySet.contains($0) }

        let bucketCount = (endKey - startKey) / bucketSeconds + 1
        var normalized: [ThroughputDataPoint] = []
        normalized.reserveCapacity(bucketCount * max(categories.count, 1))

        var key = startKey
        while key <= endKey {
            let timestamp = Date(timeIntervalSince1970: TimeInterval(key))
            let counts = bucketed[key] ?? [:]

            for category in categories {
                normalized.append(ThroughputDataPoint(
                    timestamp: timestamp,
                    category: category,
                    count: counts[category, default: 0]
                ))
            }

            key += bucketSeconds
        }

        return normalized
    }

    @MainActor
    func setDashboardTimeRange(_ timeRange: TimeRange) async {
        dashboardTimeRange = timeRange
        // Only refresh historical stats - queue status remains unchanged
        guard let connection = connection, let queueName = selectedQueueId else {
            dashboardStats = .empty
            throughputData = .empty
            return
        }

        isLoadingDashboard = true

        do {
            let provider = try getProvider()
            dashboardStats = try await QueueService.fetchDashboardStats(
                connection,
                provider: provider,
                queueName: queueName,
                timeRange: dashboardTimeRange
            )

            // Refresh throughput data for the chart
            await refreshThroughput()

            // Update estimated completion with new throughput data
            // but don't flash the queue status cards
            if queueStatus.pendingJobs > 0 && dashboardStats.completedJobs > 0 {
                let estimatedCompletion = calculateEstimatedCompletion(
                    pendingJobs: queueStatus.pendingJobs,
                    completedJobs: dashboardStats.completedJobs,
                    timeRange: dashboardTimeRange
                )
                queueStatus = QueueStatus(
                    createdJobs: queueStatus.createdJobs,
                    activeJobs: queueStatus.activeJobs,
                    retryJobs: queueStatus.retryJobs,
                    estimatedCompletion: estimatedCompletion
                )
            }
        } catch {
            self.error = error.localizedDescription
            dashboardStats = .empty
        }

        isLoadingDashboard = false
    }

    private func calculateEstimatedCompletion(
        pendingJobs: Int,
        completedJobs: Int,
        timeRange: TimeRange
    ) -> TimeInterval? {
        guard pendingJobs > 0, completedJobs > 0 else { return nil }

        let rangeSeconds: TimeInterval
        switch timeRange {
        case .oneHour:
            rangeSeconds = 3600
        case .threeHours:
            rangeSeconds = 3600 * 3
        case .twentyFourHours:
            rangeSeconds = 3600 * 24
        case .sevenDays:
            rangeSeconds = 3600 * 24 * 7
        case .thirtyDays:
            rangeSeconds = 3600 * 24 * 30
        case .all:
            return nil
        }

        let throughput = Double(completedJobs) / rangeSeconds
        guard throughput > 0 else { return nil }

        return Double(pendingJobs) / throughput
    }

    @MainActor
    func retryJob(jobId: UUID) async -> Bool {
        guard let connection = connection else {
            mutationError = "No connection configured"
            return false
        }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            try await QueueService.retryJob(connection, provider: provider, jobId: jobId)
            await refreshJobs()
            await refreshQueues()
            isMutatingJob = false
            return true
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return false
        }
    }

    @MainActor
    func cancelJob(jobId: UUID) async -> Bool {
        guard let connection = connection else {
            mutationError = "No connection configured"
            return false
        }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            try await QueueService.cancelJob(connection, provider: provider, jobId: jobId)
            await refreshJobs()
            await refreshQueues()
            isMutatingJob = false
            return true
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return false
        }
    }

    @MainActor
    func deleteJob(jobId: UUID) async -> Bool {
        guard let connection = connection else {
            mutationError = "No connection configured"
            return false
        }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            try await QueueService.deleteJob(connection, provider: provider, jobId: jobId)
            selectedJobIds.remove(jobId)
            await refreshJobs()
            await refreshQueues()
            isMutatingJob = false
            return true
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return false
        }
    }

    // MARK: - Selection-Based Bulk Operations

    @MainActor
    func retryJobs(ids: Set<UUID>) async -> Int {
        guard let connection = connection else {
            mutationError = "No connection configured"
            return 0
        }

        guard !ids.isEmpty else { return 0 }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            var successCount = 0

            for jobId in ids {
                do {
                    try await QueueService.retryJob(connection, provider: provider, jobId: jobId)
                    successCount += 1
                } catch {
                    // Continue with remaining jobs even if one fails
                }
            }

            selectedJobIds.removeAll()
            await refreshQueues()
            await refreshJobs()
            isMutatingJob = false
            return successCount
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return 0
        }
    }

    @MainActor
    func cancelJobs(ids: Set<UUID>) async -> Int {
        guard let connection = connection else {
            mutationError = "No connection configured"
            return 0
        }

        guard !ids.isEmpty else { return 0 }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            var successCount = 0

            for jobId in ids {
                do {
                    try await QueueService.cancelJob(connection, provider: provider, jobId: jobId)
                    successCount += 1
                } catch {
                    // Continue with remaining jobs even if one fails
                }
            }

            selectedJobIds.removeAll()
            await refreshQueues()
            await refreshJobs()
            isMutatingJob = false
            return successCount
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return 0
        }
    }

    @MainActor
    func deleteJobs(ids: Set<UUID>) async -> Int {
        guard let connection = connection else {
            mutationError = "No connection configured"
            return 0
        }

        guard !ids.isEmpty else { return 0 }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            var successCount = 0

            for jobId in ids {
                do {
                    try await QueueService.deleteJob(connection, provider: provider, jobId: jobId)
                    successCount += 1
                } catch {
                    // Continue with remaining jobs even if one fails
                }
            }

            selectedJobIds.removeAll()
            await refreshQueues()
            await refreshJobs()
            isMutatingJob = false
            return successCount
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return 0
        }
    }

    // MARK: - Queue-Wide Bulk Operations

    @MainActor
    func retryAllFailed() async -> Int {
        guard let connection = connection, let queueName = selectedQueueId else {
            mutationError = "No connection or queue selected"
            return 0
        }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            let count = try await QueueService.retryAllFailed(connection, provider: provider, queueName: queueName)
            await refreshQueues()
            await refreshJobs()
            isMutatingJob = false
            return count
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return 0
        }
    }

    @MainActor
    func cancelAllPending() async -> Int {
        guard let connection = connection, let queueName = selectedQueueId else {
            mutationError = "No connection or queue selected"
            return 0
        }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            let count = try await QueueService.cancelAllPending(connection, provider: provider, queueName: queueName)
            await refreshQueues()
            await refreshJobs()
            isMutatingJob = false
            return count
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return 0
        }
    }

    @MainActor
    func purgeCompleted() async -> Int {
        guard let connection = connection, let queueName = selectedQueueId else {
            mutationError = "No connection or queue selected"
            return 0
        }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            let count = try await QueueService.purgeCompleted(connection, provider: provider, queueName: queueName)
            selectedJobIds.removeAll()
            await refreshQueues()
            await refreshJobs()
            isMutatingJob = false
            return count
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return 0
        }
    }

    @MainActor
    func purgeFailed() async -> Int {
        guard let connection = connection, let queueName = selectedQueueId else {
            mutationError = "No connection or queue selected"
            return 0
        }

        isMutatingJob = true
        mutationError = nil

        do {
            let provider = try getProvider()
            let count = try await QueueService.purgeFailed(connection, provider: provider, queueName: queueName)
            selectedJobIds.removeAll()
            await refreshQueues()
            await refreshJobs()
            isMutatingJob = false
            return count
        } catch {
            mutationError = error.localizedDescription
            isMutatingJob = false
            return 0
        }
    }
}
