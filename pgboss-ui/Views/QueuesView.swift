//
//  QueuesView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct QueuesView: View {
    @Environment(ConnectionStore.self) private var connectionStore
    let connectionId: UUID

    @State private var store = QueueStore()
    @State private var selectedTab: QueueDetailTab = .jobs

    private var connection: Connection? {
        connectionStore.connections.first { $0.id == connectionId }
    }

    @ViewBuilder
    private func queueView(for connection: Connection) -> some View {
        NavigationSplitView {
                    QueueListView(
                        queues: store.queues,
                        schedules: store.schedules,
                        selectedItem: Bindable(store).selectedItem,
                        isLoading: store.isLoadingQueues
                    )
                    .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
                } detail: {
                    switch store.selectedItem {
                    case .queue:
                        if let queue = store.selectedQueue {
                            QueueDetailView(queue: queue, store: store, selectedTab: $selectedTab)
                        } else {
                            ContentUnavailableView {
                                Label("Queue Not Found", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text("The selected queue may have been deleted or is no longer available.")
                            }
                        }
                    case .schedule:
                        if let schedule = store.selectedSchedule {
                            ScheduleDetailView(schedule: schedule)
                        } else {
                            ContentUnavailableView {
                                Label("Schedule Not Found", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text("The selected schedule may have been deleted or schedules may not be supported in this pg-boss version.")
                            }
                        }
                    case .none:
                        ContentUnavailableView {
                            Label("Select a Queue or Schedule", systemImage: "list.bullet.rectangle")
                        } description: {
                            Text("Choose an item from the sidebar to view its details.")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        // Only show tab picker when a queue is selected (not a schedule)
                        if case .queue = store.selectedItem {
                            SegmentedTabPicker(
                                selection: $selectedTab,
                                displayName: { $0.displayName },
                                icon: { $0.icon }
                            )
                        }
                    }

                    ToolbarItemGroup(placement: .automatic) {
                        if let version = store.pgBossVersion {
                            VersionBadge(version: version)
                        }
                    }

                    ToolbarItemGroup(placement: .primaryAction) {
                        Menu {
                            Button {
                                store.autoRefreshEnabled = false
                            } label: {
                                HStack {
                                    Text("Off")
                                    if !store.autoRefreshEnabled {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                            Divider()

                            ForEach([2, 5, 10, 30, 60], id: \.self) { seconds in
                                Button {
                                    store.refreshInterval = TimeInterval(seconds)
                                    store.autoRefreshEnabled = true
                                } label: {
                                    HStack {
                                        Text("\(seconds)s")
                                        if store.autoRefreshEnabled && store.refreshInterval == TimeInterval(seconds) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Auto Refresh", systemImage: store.autoRefreshEnabled ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                        }
                        .help(store.autoRefreshEnabled ? "Auto-refresh: \(Int(store.refreshInterval))s" : "Auto-refresh: Off")

                        Button {
                            Task {
                                await store.refreshQueues()
                                await store.refreshSchedules()
                                if store.selectedQueueId != nil {
                                    await store.refreshJobs()
                                }
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .help("Refresh now")
                        .disabled(store.isLoadingQueues || store.isLoadingSchedules || store.isLoadingJobs)
                    }
                }
                .task {
                    store.setConnection(connection)
                    await store.refreshQueues()
                    await store.refreshSchedules()
                    store.startAutoRefresh()
                }
                .onDisappear {
                    store.stopAutoRefresh()
                }
                .alert("Error", isPresented: Binding(
                    get: { store.error != nil },
                    set: { if !$0 { store.clearError() } }
                )) {
                    Button("OK") {
                        store.clearError()
                    }
                } message: {
                    if let error = store.error {
                        Text(error)
                    }
                }
                .onChange(of: store.selectedItem) {
                    Task {
                        // Only refresh jobs when a queue is selected
                        if case .queue = store.selectedItem {
                            store.selectedJobIds.removeAll()
                            store.currentPage = 0
                            await store.refreshJobs()
                        }
                    }
                }
                .onChange(of: connection) { oldValue, newValue in
                    // Only refresh if schema or version changed
                    let schemaChanged = oldValue.schema != newValue.schema
                    let versionChanged = oldValue.pgBossVersion != newValue.pgBossVersion

                    if schemaChanged || versionChanged {
                        Task {
                            store.setConnection(newValue)
                            await store.refreshQueues()
                            await store.refreshSchedules()
                            if store.selectedQueueId != nil {
                                await store.refreshJobs()
                            }
                        }
                    }
                }
    }

    var body: some View {
        Group {
            if let connection = connection {
                queueView(for: connection)
            } else {
                ContentUnavailableView {
                    Label("Connection Not Found", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("The connection may have been deleted.")
                }
            }
        }
        .frame(minWidth: 1200, minHeight: 750)
        .navigationTitle(connection?.name ?? "Queues")
    }
}

#Preview {
    QueuesView(connectionId: MockData.connections[0].id)
        .environment(MockData.createPreviewStore())
}
