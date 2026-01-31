//
//  JobDetailsModalView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobDetailsModalView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentJob: Job
    @State private var currentIndex: Int
    let jobs: [Job]
    let onNavigate: ((Job) -> Void)?
    let onRetry: () async -> Bool
    let onCancel: () async -> Bool
    let onDelete: () async -> Bool

    init(
        job: Job,
        jobs: [Job],
        currentIndex: Int,
        onNavigate: ((Job) -> Void)?,
        onRetry: @escaping () async -> Bool,
        onCancel: @escaping () async -> Bool,
        onDelete: @escaping () async -> Bool
    ) {
        _currentJob = State(initialValue: job)
        _currentIndex = State(initialValue: currentIndex)
        self.jobs = jobs
        self.onNavigate = onNavigate
        self.onRetry = onRetry
        self.onCancel = onCancel
        self.onDelete = onDelete
    }

    private var hasPrevious: Bool { currentIndex > 0 }
    private var hasNext: Bool { currentIndex < jobs.count - 1 }

    private func goToPrevious() {
        if hasPrevious {
            currentIndex -= 1
            currentJob = jobs[currentIndex]
            onNavigate?(currentJob)
        }
    }

    private func goToNext() {
        if hasNext {
            currentIndex += 1
            currentJob = jobs[currentIndex]
            onNavigate?(currentJob)
        }
    }

    @State private var showDeleteConfirmation = false
    @State private var showRetryConfirmation = false
    @State private var showCancelConfirmation = false
    @State private var isPerformingAction = false
    @State private var actionError: String?

    private var canRetry: Bool {
        switch currentJob.state {
        case .completed, .cancelled, .failed:
            return true
        case .created, .retry, .active:
            return false
        }
    }

    private var canCancel: Bool {
        switch currentJob.state {
        case .created, .retry, .active:
            return true
        case .completed, .cancelled, .failed:
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xLarge) {
                    JobIdentityView(job: currentJob)

                    Divider()

                    JobTimelineView(
                        createdOn: currentJob.createdOn,
                        startedOn: currentJob.startedOn,
                        completedOn: currentJob.completedOn
                    )

                    Divider()

                    JobMetadataView(
                        priority: currentJob.priority,
                        retryCount: currentJob.retryCount,
                        retryLimit: currentJob.retryLimit,
                        singletonKey: currentJob.singletonKey,
                        singletonOn: currentJob.singletonOn,
                        expireIn: currentJob.expireIn,
                        keepUntil: currentJob.keepUntil,
                        startAfter: currentJob.startAfter,
                        retryDelay: currentJob.retryDelay,
                        retryBackoff: currentJob.retryBackoff
                    )

                    Divider()

                    JobDataSectionView(title: "INPUT DATA", json: currentJob.data)

                    if let output = currentJob.output {
                        Divider()
                        JobDataSectionView(title: "OUTPUT DATA", json: output)
                    }
                }
                .padding(DesignTokens.Spacing.xLarge)
            }

            Divider()

            actionButtonsView
        }
        .frame(width: 500, height: 600)
        .onKeyPress(.upArrow) {
            goToPrevious()
            return .handled
        }
        .onKeyPress(.downArrow) {
            goToNext()
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .confirmationDialog(
            "Delete Job",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                performAction(onDelete, errorMessage: "Failed to delete job")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this job? This action cannot be undone.")
        }
        .confirmationDialog(
            "Retry Job",
            isPresented: $showRetryConfirmation,
            titleVisibility: .visible
        ) {
            Button("Retry") {
                performAction(onRetry, errorMessage: "Failed to retry job")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to retry this job?")
        }
        .confirmationDialog(
            "Cancel Job",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Job", role: .destructive) {
                performAction(onCancel, errorMessage: "Failed to cancel job")
            }
            Button("Go Back", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel this job?")
        }
        .alert("Action Failed", isPresented: .init(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button("OK") {
                actionError = nil
            }
        } message: {
            if let error = actionError {
                Text(error)
            }
        }
        .overlay {
            if isPerformingAction {
                ZStack {
                    DesignTokens.Colors.overlayBackground
                        .ignoresSafeArea()

                    VStack(spacing: DesignTokens.Spacing.large) {
                        ProgressView()
                            .controlSize(.regular)
                        Text("Processing...")
                    }
                    .padding(DesignTokens.Spacing.xxLarge)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Spacer()

            if jobs.count > 1 {
                HStack(spacing: DesignTokens.Spacing.small) {
                    Button {
                        goToPrevious()
                    } label: {
                        Image(systemName: "chevron.up")
                            .foregroundStyle(hasPrevious ? .secondary : .quaternary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasPrevious)

                    Text("\(currentIndex + 1) of \(jobs.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    Button {
                        goToNext()
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(hasNext ? .secondary : .quaternary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasNext)
                }
            } else {
                Text("Job Details")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Spacer to keep the title centered without a trailing control
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, DesignTokens.Spacing.xLarge)
        .padding(.vertical, DesignTokens.Spacing.medium)
        .background(.thinMaterial)
    }

    // MARK: - Actions

    private func performAction(_ action: @escaping () async -> Bool, errorMessage: String) {
        Task {
            isPerformingAction = true
            actionError = nil
            let success = await action()
            isPerformingAction = false
            if success {
                dismiss()
            } else {
                actionError = errorMessage
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack {
            if canRetry {
                Button {
                    showRetryConfirmation = true
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .disabled(isPerformingAction)
            }

            if canCancel {
                Button {
                    showCancelConfirmation = true
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
                .disabled(isPerformingAction)
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(isPerformingAction)

            Spacer()

            Button("Close") {
                dismiss()
            }
            .disabled(isPerformingAction)
        }
        .padding(DesignTokens.Spacing.xLarge)
    }
}

#Preview {
    let job = Job(
        id: UUID(),
        name: "send-email",
        state: .completed,
        priority: 5,
        data: "{\"to\": \"user@example.com\", \"subject\": \"Welcome!\", \"template\": \"onboarding\"}",
        createdOn: Date().addingTimeInterval(-3600),
        startedOn: Date().addingTimeInterval(-3500),
        completedOn: Date().addingTimeInterval(-3400),
        retryCount: 1,
        retryLimit: 3,
        output: "{\"success\": true, \"messageId\": \"abc123\"}",
        singletonKey: nil,
        singletonOn: nil,
        expireIn: nil,
        keepUntil: nil
    )

    JobDetailsModalView(
        job: job,
        jobs: [job],
        currentIndex: 0,
        onNavigate: nil,
        onRetry: { true },
        onCancel: { true },
        onDelete: { true }
    )
}

#Preview("Failed Job") {
    let job = Job(
        id: UUID(),
        name: "process-payment",
        state: .failed,
        priority: 10,
        data: "{\"orderId\": \"ORD-12345\", \"amount\": 99.99}",
        createdOn: Date().addingTimeInterval(-7200),
        startedOn: Date().addingTimeInterval(-7100),
        completedOn: nil,
        retryCount: 3,
        retryLimit: 3,
        output: "{\"error\": \"Payment gateway timeout\", \"code\": \"GATEWAY_TIMEOUT\"}",
        singletonKey: "payment-ORD-12345",
        singletonOn: nil,
        expireIn: 300,
        keepUntil: Date().addingTimeInterval(86400 * 14)
    )

    JobDetailsModalView(
        job: job,
        jobs: [job],
        currentIndex: 0,
        onNavigate: nil,
        onRetry: { true },
        onCancel: { true },
        onDelete: { true }
    )
}

#Preview("Active Job") {
    let job = Job(
        id: UUID(),
        name: "generate-report",
        state: .active,
        priority: 0,
        data: "{\"reportType\": \"monthly\", \"userId\": 42}",
        createdOn: Date().addingTimeInterval(-300),
        startedOn: Date().addingTimeInterval(-60),
        completedOn: nil,
        retryCount: 0,
        retryLimit: 5,
        output: nil,
        singletonKey: "report-monthly-42",
        singletonOn: Date(),
        expireIn: 3600,
        keepUntil: Date().addingTimeInterval(86400 * 7)
    )

    JobDetailsModalView(
        job: job,
        jobs: [job],
        currentIndex: 0,
        onNavigate: nil,
        onRetry: { true },
        onCancel: { true },
        onDelete: { true }
    )
}
