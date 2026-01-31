//
//  JobFilterBar.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobFilterBar: View {
    @Binding var stateFilter: JobState?
    @Binding var searchText: String
    @Binding var searchField: JobSearchField
    let queue: Queue?
    let selectedJobIds: Set<UUID>
    @Bindable var store: QueueStore

    let onFilterChange: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xLarge) {
            // State filter
            HStack(spacing: DesignTokens.Spacing.medium) {
                Text("State:")
                    .foregroundStyle(.secondary)

                Picker("State", selection: $stateFilter) {
                    Text("All").tag(nil as JobState?)
                    ForEach(JobState.allCases, id: \.self) { state in
                        HStack {
                            Image(systemName: state.icon)
                            Text(state.displayName)
                        }
                        .tag(state as JobState?)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .onChange(of: stateFilter) {
                    onFilterChange()
                }
            }

            // Text search filter
            HStack(spacing: DesignTokens.Spacing.medium) {
                Picker("Search Field", selection: $searchField) {
                    ForEach(JobSearchField.allCases, id: \.self) { field in
                        Text(field.displayName).tag(field)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 120)

                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onSubmit {
                        onFilterChange()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        onFilterChange()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Selection badge with clear button
            if !selectedJobIds.isEmpty {
                HStack(spacing: DesignTokens.Spacing.small) {
                    Text("\(selectedJobIds.count) selected")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Button {
                        store.clearSelection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear selection (⎋)")
                }
                .padding(.horizontal, DesignTokens.Spacing.medium)
                .padding(.vertical, DesignTokens.Spacing.small)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                .help("⌘A to select all • Delete to remove")
            }

            if let queue = queue {
                BulkActionsToolbar(queue: queue, selectedJobIds: selectedJobIds, store: store)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, DesignTokens.Spacing.medium)
        .background(.background.secondary)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var stateFilter: JobState? = nil
        @State private var searchText: String = ""
        @State private var searchField: JobSearchField = .uuid
        @State private var store = QueueStore()

        let queue = Queue(
            id: "email-notifications",
            stats: QueueStats(created: 5, retry: 2, active: 10, completed: 150, failed: 3, cancelled: 1)
        )

        var body: some View {
            JobFilterBar(
                stateFilter: $stateFilter,
                searchText: $searchText,
                searchField: $searchField,
                queue: queue,
                selectedJobIds: [],
                store: store,
                onFilterChange: {}
            )
        }
    }

    return PreviewWrapper()
}
