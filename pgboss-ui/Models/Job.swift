//
//  Job.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import Foundation
import SwiftUI

struct Job: Identifiable, Hashable {
    let id: UUID
    let name: String
    let state: JobState
    let priority: Int
    let data: String       // JSON string
    let createdOn: Date
    let startedOn: Date?
    let completedOn: Date?
    let retryCount: Int
    let retryLimit: Int
    let output: String?    // JSON string

    // Job-level settings (can override queue defaults)
    let singletonKey: String?
    let singletonOn: Date?
    let expireIn: TimeInterval?   // seconds until job expires
    let keepUntil: Date?          // when job record can be deleted
    let startAfter: Date?         // when job becomes eligible to run
    let retryDelay: TimeInterval? // base delay between retries in seconds
    let retryBackoff: Bool?       // whether to use exponential backoff

    init(
        id: UUID,
        name: String,
        state: JobState,
        priority: Int,
        data: String,
        createdOn: Date,
        startedOn: Date?,
        completedOn: Date?,
        retryCount: Int,
        retryLimit: Int,
        output: String?,
        singletonKey: String? = nil,
        singletonOn: Date? = nil,
        expireIn: TimeInterval? = nil,
        keepUntil: Date? = nil,
        startAfter: Date? = nil,
        retryDelay: TimeInterval? = nil,
        retryBackoff: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.state = state
        self.priority = priority
        self.data = data
        self.createdOn = createdOn
        self.startedOn = startedOn
        self.completedOn = completedOn
        self.retryCount = retryCount
        self.retryLimit = retryLimit
        self.output = output
        self.singletonKey = singletonKey
        self.singletonOn = singletonOn
        self.expireIn = expireIn
        self.keepUntil = keepUntil
        self.startAfter = startAfter
        self.retryDelay = retryDelay
        self.retryBackoff = retryBackoff
    }
}

enum JobState: String, CaseIterable, Hashable {
    case created
    case retry
    case active
    case completed
    case cancelled
    case failed

    var color: Color {
        switch self {
        case .created:
            return .blue
        case .retry:
            return .yellow
        case .active:
            return .purple
        case .completed:
            return .green
        case .cancelled:
            return .gray
        case .failed:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .created:
            return "plus.circle"
        case .retry:
            return "arrow.clockwise"
        case .active:
            return "play.circle"
        case .completed:
            return "checkmark.circle"
        case .cancelled:
            return "minus.circle"
        case .failed:
            return "xmark.circle"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

enum JobSortField: CaseIterable {
    case createdOn
    case startedOn
    case completedOn
    case priority
    case state

    var displayName: String {
        switch self {
        case .createdOn:
            return "Created"
        case .startedOn:
            return "Started"
        case .completedOn:
            return "Completed"
        case .priority:
            return "Priority"
        case .state:
            return "State"
        }
    }

    /// Get the column name for this sort field using the provided column mapping
    func columnName(for mapping: JobColumnMapping) -> String {
        switch self {
        case .createdOn:
            return mapping.createdOn
        case .startedOn:
            return mapping.startedOn
        case .completedOn:
            return mapping.completedOn
        case .priority:
            return mapping.priority
        case .state:
            return mapping.state
        }
    }
}

enum SortOrder: String {
    case ascending = "ASC"
    case descending = "DESC"

    var displayName: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

enum JobSearchField: String, CaseIterable {
    case uuid
    case inputData
    case outputData

    var displayName: String {
        switch self {
        case .uuid: return "UUID"
        case .inputData: return "Input Data"
        case .outputData: return "Output Data"
        }
    }
}
