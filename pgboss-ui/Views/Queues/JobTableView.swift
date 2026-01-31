//
//  JobTableView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobTableView: View {
    let jobs: [Job]
    @Binding var selectedJobIds: Set<UUID>
    @Binding var sortBy: JobSortField
    @Binding var sortOrder: SortOrder
    let isLoading: Bool
    let onSortChange: () -> Void
    var onJobDoubleClick: ((Job) -> Void)?
    var onSelectAll: (() -> Void)?
    var onDeleteSelected: (() -> Void)?

    @State private var tableSortOrder: [KeyPathComparator<Job>] = []
    @SceneStorage("JobTable.columnCustomization")
    private var columnCustomization: TableColumnCustomization<Job>


    var body: some View {
        ZStack {
            if jobs.isEmpty && !isLoading {
                ContentUnavailableView {
                    Label("No Jobs", systemImage: "doc.text")
                } description: {
                    Text("No jobs found matching the current filter.")
                }
            } else {
                Table(jobs, selection: $selectedJobIds, sortOrder: $tableSortOrder, columnCustomization: $columnCustomization) {
                    TableColumn("ID") { job in
                        Text(job.id.uuidString.prefix(8))
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .help(job.id.uuidString)
                    }
                    .width(min: DesignTokens.TableColumn.idMin, ideal: DesignTokens.TableColumn.idIdeal)
                    .customizationID("id")

                    TableColumn("State", value: \.state.rawValue) { job in
                        StateBadge(state: job.state)
                    }
                    .width(min: DesignTokens.TableColumn.stateMin, ideal: DesignTokens.TableColumn.stateIdeal)
                    .customizationID("state")

                    TableColumn("Priority", value: \.priority) { job in
                        Text("\(job.priority)")
                            .font(.callout)
                    }
                    .width(min: DesignTokens.TableColumn.numberMin, ideal: DesignTokens.TableColumn.numberIdeal)
                    .customizationID("priority")

                    TableColumn("Retries") { job in
                        if job.retryLimit > 0 {
                            Text("\(job.retryCount)/\(job.retryLimit)")
                                .font(.callout)
                                .foregroundStyle(job.retryCount > 0 ? DesignTokens.Colors.warning : .secondary)
                        } else {
                            Text("—")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(min: DesignTokens.TableColumn.numberMin, ideal: DesignTokens.TableColumn.numberIdeal)
                    .customizationID("retries")

                    TableColumn("Created", value: \.createdOn) { job in
                        Text(DesignTokens.DateFormat.shortDateTime.string(from: job.createdOn))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .width(min: DesignTokens.TableColumn.dateMin, ideal: DesignTokens.TableColumn.dateIdeal)
                    .customizationID("created")

                    TableColumn("Completed") { job in
                        if let completedOn = job.completedOn {
                            Text(DesignTokens.DateFormat.shortDateTime.string(from: completedOn))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .width(min: DesignTokens.TableColumn.dateMin, ideal: DesignTokens.TableColumn.dateIdeal)
                    .customizationID("completed")
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .onChange(of: tableSortOrder) { _, newValue in
                    guard let firstComparator = newValue.first else { return }

                    let newSortOrder: SortOrder = firstComparator.order == .forward ? .ascending : .descending

                    let newSortBy: JobSortField? = switch firstComparator.keyPath {
                    case \Job.priority: .priority
                    case \Job.createdOn: .createdOn
                    case \Job.state.rawValue: .state
                    default: nil
                    }

                    if let newSortBy, newSortBy != sortBy || newSortOrder != sortOrder {
                        sortBy = newSortBy
                        sortOrder = newSortOrder
                        onSortChange()
                    }
                }
                .onAppear {
                    tableSortOrder = [makeComparator(for: sortBy, order: sortOrder)]
                }
                .onChange(of: sortBy) { _, newValue in
                    tableSortOrder = [makeComparator(for: newValue, order: sortOrder)]
                }
                .onChange(of: sortOrder) { _, newValue in
                    tableSortOrder = [makeComparator(for: sortBy, order: newValue)]
                }
                .contextMenu(forSelectionType: UUID.self, menu: { _ in
                    // Empty menu - we only need primaryAction for double-click
                }, primaryAction: { selection in
                    guard let selectedId = selection.first,
                          let job = jobs.first(where: { $0.id == selectedId }) else { return }
                    onJobDoubleClick?(job)
                })
                .onKeyPress(.escape) {
                    if !selectedJobIds.isEmpty {
                        selectedJobIds.removeAll()
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(keys: [.init("a")], phases: .down) { press in
                    if press.modifiers.contains(.command) {
                        onSelectAll?()
                        return .handled
                    }
                    return .ignored
                }
                .onKeyPress(.delete) {
                    if !selectedJobIds.isEmpty {
                        onDeleteSelected?()
                        return .handled
                    }
                    return .ignored
                }
            }

            // Loading overlay (shows even with existing data)
            if isLoading {
                DesignTokens.Colors.overlayBackground

                ProgressView()
                    .controlSize(.large)
                    .padding(DesignTokens.Spacing.xLarge)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            }
        }
    }

    private func makeComparator(for field: JobSortField, order: SortOrder) -> KeyPathComparator<Job> {
        let sortOrder: SortOrder = order
        let comparatorOrder: Foundation.SortOrder = sortOrder == .ascending ? .forward : .reverse

        return switch field {
        case .priority:
            KeyPathComparator(\Job.priority, order: comparatorOrder)
        case .createdOn:
            KeyPathComparator(\Job.createdOn, order: comparatorOrder)
        case .startedOn:
            KeyPathComparator(\Job.startedOn, order: comparatorOrder)
        case .completedOn:
            KeyPathComparator(\Job.completedOn, order: comparatorOrder)
        case .state:
            KeyPathComparator(\Job.state.rawValue, order: comparatorOrder)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedJobIds: Set<UUID> = []
        @State private var sortBy: JobSortField = .createdOn
        @State private var sortOrder: SortOrder = .descending

        let jobs = [
            Job(id: UUID(), name: "send-email", state: .completed, priority: 0, data: "{}", createdOn: Date().addingTimeInterval(-3600), startedOn: Date().addingTimeInterval(-3500), completedOn: Date().addingTimeInterval(-3400), retryCount: 0, retryLimit: 3, output: nil),
            Job(id: UUID(), name: "send-email", state: .failed, priority: 1, data: "{}", createdOn: Date().addingTimeInterval(-7200), startedOn: Date().addingTimeInterval(-7100), completedOn: nil, retryCount: 2, retryLimit: 3, output: nil),
            Job(id: UUID(), name: "send-email", state: .active, priority: 5, data: "{}", createdOn: Date(), startedOn: Date(), completedOn: nil, retryCount: 0, retryLimit: 0, output: nil)
        ]

        var body: some View {
            VStack(spacing: 0) {
                JobTableView(
                    jobs: jobs,
                    selectedJobIds: $selectedJobIds,
                    sortBy: $sortBy,
                    sortOrder: $sortOrder,
                    isLoading: false,
                    onSortChange: {}
                )

                JobPaginationView(
                    currentPage: 0,
                    totalPages: 5,
                    totalJobs: 243,
                    pageSize: 50,
                    hasPrevious: false,
                    hasNext: true,
                    onPrevious: {},
                    onNext: {}
                )
            }
            .frame(width: 700, height: 300)
        }
    }

    return PreviewWrapper()
}

struct JobPaginationView: View {
    let currentPage: Int
    let totalPages: Int
    let totalJobs: Int
    let pageSize: Int
    let hasPrevious: Bool
    let hasNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var startItem: Int {
        currentPage * pageSize + 1
    }

    private var endItem: Int {
        min((currentPage + 1) * pageSize, totalJobs)
    }

    var body: some View {
        HStack {
            Text("Showing \(startItem)-\(endItem) of \(totalJobs)")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: DesignTokens.Spacing.medium) {
                Button {
                    onPrevious()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!hasPrevious)

                Text("Page \(currentPage + 1) of \(totalPages)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: DesignTokens.TableColumn.paginationInfo)

                Button {
                    onNext()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!hasNext)
            }
            .font(.body)
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .padding(.vertical, DesignTokens.Spacing.medium)
        .background(.background.secondary)
    }
}

