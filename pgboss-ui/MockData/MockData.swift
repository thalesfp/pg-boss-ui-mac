//
//  MockData.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import Foundation

/// Mock data for SwiftUI previews only
struct MockData {
    static let connections: [Connection] = [
        Connection(
            name: "Local Development",
            host: "localhost",
            port: 5432,
            database: "pgboss_dev",
            username: "postgres",
            password: "postgres"
        ),
        Connection(
            name: "Staging Server",
            host: "staging.example.com",
            port: 5432,
            database: "pgboss_staging",
            username: "app_user",
            password: "staging_secret"
        ),
        Connection(
            name: "Production",
            host: "prod-db.example.com",
            port: 5432,
            database: "pgboss_prod",
            username: "app_user",
            password: "prod_secret"
        )
    ]

    static let queues: [Queue] = [
        Queue(
            id: "email-notifications",
            stats: QueueStats(
                created: 5,
                retry: 2,
                active: 10,
                completed: 150,
                failed: 3,
                cancelled: 1
            ),
            config: QueueConfig(
                retentionSeconds: 86400 * 14,  // 14 days
                deletionSeconds: 86400 * 7,    // 7 days (v11)
                expireSeconds: 900,            // 15 minutes
                retryLimit: 3,
                policy: "standard"
            )
        ),
        Queue(
            id: "process-payments",
            stats: QueueStats(
                created: 0,
                retry: 0,
                active: 3,
                completed: 500,
                failed: 0,
                cancelled: 0
            ),
            config: QueueConfig(
                retentionSeconds: 86400 * 30,  // 30 days
                deletionSeconds: nil,          // v10 style (no deletion)
                expireSeconds: 3600,           // 1 hour
                retryLimit: 5,
                policy: "standard"
            )
        ),
        Queue(
            id: "sync-data",
            stats: QueueStats(
                created: 100,
                retry: 0,
                active: 0,
                completed: 0,
                failed: 0,
                cancelled: 0
            ),
            config: nil  // Legacy/v9 style
        ),
        Queue(
            id: "generate-reports",
            stats: QueueStats(
                created: 0,
                retry: 1,
                active: 2,
                completed: 45,
                failed: 5,
                cancelled: 0
            ),
            config: QueueConfig(
                retentionSeconds: 86400 * 7,   // 7 days
                deletionSeconds: 86400 * 3,    // 3 days
                expireSeconds: 1800,           // 30 minutes
                retryLimit: 2,
                policy: "short"
            )
        ),
        Queue(
            id: "cleanup-tasks",
            stats: QueueStats(
                created: 10,
                retry: 0,
                active: 1,
                completed: 1000,
                failed: 2,
                cancelled: 50
            ),
            config: QueueConfig(
                retentionSeconds: 3600,        // 1 hour
                deletionSeconds: 1800,         // 30 minutes
                expireSeconds: 300,            // 5 minutes
                retryLimit: 1,
                policy: "stately"
            )
        )
    ]

    static let schedules: [Schedule] = [
        Schedule(
            name: "daily-report",
            cron: "0 9 * * *",
            timezone: "America/New_York",
            data: """
            {
                "reportType": "daily-summary",
                "recipients": ["admin@example.com"]
            }
            """,
            options: nil,
            createdOn: Date().addingTimeInterval(-86400 * 30),
            updatedOn: Date().addingTimeInterval(-86400)
        ),
        Schedule(
            name: "cleanup-old-jobs",
            cron: "0 0 * * *",
            timezone: nil,
            data: nil,
            options: nil,
            createdOn: Date().addingTimeInterval(-86400 * 60),
            updatedOn: Date().addingTimeInterval(-86400 * 60)
        ),
        Schedule(
            name: "sync-inventory",
            cron: "*/15 * * * *",
            timezone: "UTC",
            data: """
            {
                "source": "warehouse-api"
            }
            """,
            options: nil,
            createdOn: Date().addingTimeInterval(-86400 * 7),
            updatedOn: Date().addingTimeInterval(-3600)
        )
    ]

    static let jobs: [Job] = [
        Job(
            id: UUID(),
            name: "email-notifications",
            state: .completed,
            priority: 0,
            data: """
            {
                "to": "user@example.com",
                "subject": "Welcome!",
                "template": "welcome_email"
            }
            """,
            createdOn: Date().addingTimeInterval(-3600),
            startedOn: Date().addingTimeInterval(-3500),
            completedOn: Date().addingTimeInterval(-3400),
            retryCount: 0,
            retryLimit: 3,
            output: nil,
            singletonKey: nil,
            singletonOn: nil,
            expireIn: 900,
            keepUntil: Date().addingTimeInterval(86400 * 14)
        ),
        Job(
            id: UUID(),
            name: "email-notifications",
            state: .failed,
            priority: 1,
            data: """
            {
                "to": "another@example.com",
                "subject": "Password Reset",
                "template": "password_reset"
            }
            """,
            createdOn: Date().addingTimeInterval(-7200),
            startedOn: Date().addingTimeInterval(-7100),
            completedOn: nil,
            retryCount: 2,
            retryLimit: 3,
            output: """
            {
                "error": "SMTP connection timeout",
                "code": "ETIMEDOUT"
            }
            """,
            singletonKey: "password-reset-another@example.com",
            singletonOn: nil,
            expireIn: 300,
            keepUntil: Date().addingTimeInterval(86400 * 7)
        ),
        Job(
            id: UUID(),
            name: "email-notifications",
            state: .active,
            priority: 5,
            data: """
            {
                "to": "urgent@example.com",
                "subject": "Urgent: Action Required",
                "template": "urgent_notification"
            }
            """,
            createdOn: Date().addingTimeInterval(-60),
            startedOn: Date().addingTimeInterval(-30),
            completedOn: nil,
            retryCount: 0,
            retryLimit: 5,
            output: nil,
            singletonKey: nil,
            singletonOn: nil,
            expireIn: 600,
            keepUntil: nil
        ),
        Job(
            id: UUID(),
            name: "email-notifications",
            state: .created,
            priority: 0,
            data: """
            {
                "to": "new@example.com",
                "subject": "Newsletter",
                "template": "newsletter"
            }
            """,
            createdOn: Date(),
            startedOn: nil,
            completedOn: nil,
            retryCount: 0,
            retryLimit: 3,
            output: nil,
            singletonKey: "newsletter-daily",
            singletonOn: Date(),
            expireIn: nil,
            keepUntil: nil
        ),
        Job(
            id: UUID(),
            name: "email-notifications",
            state: .retry,
            priority: 2,
            data: """
            {
                "to": "retry@example.com",
                "subject": "Retry Test",
                "template": "test"
            }
            """,
            createdOn: Date().addingTimeInterval(-1800),
            startedOn: Date().addingTimeInterval(-1700),
            completedOn: nil,
            retryCount: 1,
            retryLimit: 3,
            output: nil,
            singletonKey: nil,
            singletonOn: nil,
            expireIn: 900,
            keepUntil: Date().addingTimeInterval(86400 * 3)
        ),
        Job(
            id: UUID(),
            name: "email-notifications",
            state: .cancelled,
            priority: 0,
            data: """
            {
                "to": "cancelled@example.com",
                "subject": "Cancelled Job",
                "template": "test"
            }
            """,
            createdOn: Date().addingTimeInterval(-5400),
            startedOn: nil,
            completedOn: Date().addingTimeInterval(-5000),
            retryCount: 0,
            retryLimit: 3,
            output: nil,
            singletonKey: nil,
            singletonOn: nil,
            expireIn: nil,
            keepUntil: nil
        )
    ]

    /// Creates a ConnectionStore pre-populated with mock data for previews
    static func createPreviewStore() -> ConnectionStore {
        let store = ConnectionStore()
        for connection in connections {
            try? store.add(connection)
        }
        return store
    }

    /// Creates a QueueStore pre-populated with mock data for previews
    static func createPreviewQueueStore() -> QueueStore {
        let store = QueueStore()
        store.queues = queues
        store.schedules = schedules
        store.jobs = jobs
        store.totalJobs = jobs.count
        return store
    }
}
