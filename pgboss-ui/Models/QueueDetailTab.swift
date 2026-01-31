//
//  QueueDetailTab.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

enum QueueDetailTab: String, CaseIterable {
    case jobs
    case dashboard

    var displayName: String {
        switch self {
        case .jobs:
            return "Jobs"
        case .dashboard:
            return "Dashboard"
        }
    }

    var icon: String {
        switch self {
        case .jobs:
            return "list.bullet"
        case .dashboard:
            return "chart.bar.xaxis"
        }
    }
}
