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

    var body: some View {
        Group {
            if let connection = connection {
                NavigationSplitView {
                    QueueListView(
                        queues: store.queues,
                        schedules: store.schedules,
                        selectedQueueId: Bindable(store).selectedQueueId,
                        isLoading: store.isLoadingQueues
                    )
                    .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
                } detail: {
                    if let queue = store.selectedQueue {
                        QueueDetailView(queue: queue, store: store, selectedTab: $selectedTab)
                    } else {
                        ContentUnavailableView {
                            Label("Select a Queue", systemImage: "list.bullet.rectangle")
                        } description: {
                            Text("Choose a queue from the sidebar to view its jobs.")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if store.selectedQueueId != nil {
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
                .onChange(of: store.selectedQueueId) {
                    Task {
                        store.selectedJobIds.removeAll()
                        store.currentPage = 0
                        await store.refreshJobs()
                    }
                }
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
