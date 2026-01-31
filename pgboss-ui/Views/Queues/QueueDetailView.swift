//
//  QueueDetailView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct QueueDetailView: View {
    let queue: Queue
    @Bindable var store: QueueStore
    @Binding var selectedTab: QueueDetailTab

    @State private var jobForDetails: Job?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .jobs:
                jobsTabContent
            case .dashboard:
                QueueDashboardView(queue: queue, store: store)
            }
        }
        .frame(minWidth: 500)
        .navigationTitle(queue.name)
        .sheet(item: $jobForDetails) { job in
            let index = store.jobs.firstIndex(where: { $0.id == job.id }) ?? 0
            JobDetailsModalView(
                job: job,
                jobs: store.jobs,
                currentIndex: index,
                onNavigate: { newJob in jobForDetails = newJob },
                onRetry: { await store.retryJob(jobId: job.id) },
                onCancel: { await store.cancelJob(jobId: job.id) },
                onDelete: { await store.deleteJob(jobId: job.id) }
            )
        }
    }

    @ViewBuilder
    private var jobsTabContent: some View {
        QueueStatsCardsView(stats: queue.stats, config: queue.config)
            .padding()

        Divider()

        JobFilterBar(
            stateFilter: $store.stateFilter,
            searchText: $store.searchText,
            searchField: $store.searchField,
            queue: queue,
            selectedJobIds: store.selectedJobIds,
            store: store
        ) {
            store.currentPage = 0
            Task { await store.refreshJobs() }
        }

        Divider()

        JobTableView(
            jobs: store.jobs,
            selectedJobIds: $store.selectedJobIds,
            sortBy: $store.sortBy,
            sortOrder: $store.sortOrder,
            isLoading: store.isLoadingJobs,
            onSortChange: {
                Task { await store.refreshJobs() }
            },
            onJobDoubleClick: { job in
                jobForDetails = job
            },
            onSelectAll: {
                store.selectAllJobs()
            },
            onDeleteSelected: {
                showDeleteConfirmation = true
            }
        )
        .confirmationDialog(
            "Delete Selected Jobs",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(store.selectedJobIds.count) Job\(store.selectedJobIds.count == 1 ? "" : "s")", role: .destructive) {
                Task {
                    _ = await store.deleteJobs(ids: store.selectedJobIds)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let count = store.selectedJobIds.count
            Text("This will permanently delete \(count) job\(count == 1 ? "" : "s") from the queue. This action cannot be undone.")
        }
        .frame(maxHeight: .infinity)

        Divider()

        if store.totalJobs > 0 {
            JobPaginationView(
                currentPage: store.currentPage,
                totalPages: store.totalPages,
                totalJobs: store.totalJobs,
                pageSize: store.pageSize,
                hasPrevious: store.hasPreviousPage,
                hasNext: store.hasNextPage,
                onPrevious: {
                    Task { await store.previousPage() }
                },
                onNext: {
                    Task { await store.nextPage() }
                }
            )
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var store = QueueStore()
        @State private var selectedTab: QueueDetailTab = .jobs

        let queue = Queue(
            id: "email-notifications",
            stats: QueueStats(created: 5, retry: 2, active: 10, completed: 150, failed: 3, cancelled: 1),
            config: QueueConfig(
                retentionSeconds: 86400 * 14,
                deletionSeconds: 86400 * 7,
                expireSeconds: 900,
                retryLimit: 3,
                policy: "standard"
            )
        )

        var body: some View {
            QueueDetailView(queue: queue, store: store, selectedTab: $selectedTab)
                .frame(width: 1000, height: 600)
                .onAppear {
                    // Simulate some job data
                    store.jobs = [
                        Job(id: UUID(), name: "send-email", state: .completed, priority: 0, data: "{\"to\": \"user@example.com\"}", createdOn: Date().addingTimeInterval(-3600), startedOn: Date().addingTimeInterval(-3500), completedOn: Date().addingTimeInterval(-3400), retryCount: 0, retryLimit: 3, output: nil, singletonKey: nil, singletonOn: nil, expireIn: 900, keepUntil: nil),
                        Job(id: UUID(), name: "send-email", state: .failed, priority: 1, data: "{}", createdOn: Date().addingTimeInterval(-7200), startedOn: Date().addingTimeInterval(-7100), completedOn: nil, retryCount: 2, retryLimit: 3, output: "{\"error\": \"SMTP timeout\"}", singletonKey: "email-test", singletonOn: nil, expireIn: 300, keepUntil: Date().addingTimeInterval(86400)),
                        Job(id: UUID(), name: "send-email", state: .active, priority: 5, data: "{}", createdOn: Date(), startedOn: Date(), completedOn: nil, retryCount: 0, retryLimit: 0, output: nil, singletonKey: nil, singletonOn: nil, expireIn: nil, keepUntil: nil)
                    ]
                    store.totalJobs = 171
                }
        }
    }

    return PreviewWrapper()
}
