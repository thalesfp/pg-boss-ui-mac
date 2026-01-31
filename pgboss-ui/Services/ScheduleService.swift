//
//  ScheduleService.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation
import PostgresClientKit

struct ScheduleService {
    enum ScheduleServiceError: LocalizedError {
        case connectionFailed(String)
        case queryFailed(String)
        case notSupported

        var errorDescription: String? {
            switch self {
            case .connectionFailed(let reason):
                return "Connection failed: \(reason)"
            case .queryFailed(let reason):
                return "Query failed: \(reason)"
            case .notSupported:
                return "Schedules not supported in this pg-boss version"
            }
        }
    }

    static func fetchSchedules(_ connection: Connection, provider: any SchemaProvider) async throws -> [Schedule] {
        // Check if this version supports schedules
        guard let sql = provider.fetchSchedulesSQL() else {
            // Return empty array for versions without schedule support
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute()
                    defer { cursor.close() }

                    var schedules: [Schedule] = []

                    for row in cursor {
                        let columns = try row.get().columns

                        let name = try columns[0].string()
                        let cron = try columns[1].string()
                        let timezone = try columns[2].optionalString()
                        let data = try columns[3].optionalString()
                        let options = try columns[4].optionalString()
                        let createdOn = try columns[5].timestampWithTimeZone().date
                        let updatedOn = try columns[6].timestampWithTimeZone().date

                        schedules.append(Schedule(
                            name: name,
                            cron: cron,
                            timezone: timezone,
                            data: data,
                            options: options,
                            createdOn: createdOn,
                            updatedOn: updatedOn
                        ))
                    }

                    continuation.resume(returning: schedules)
                } catch let error as PostgresError {
                    continuation.resume(throwing: ScheduleServiceError.queryFailed(String(describing: error)))
                } catch {
                    continuation.resume(throwing: ScheduleServiceError.connectionFailed(error.localizedDescription))
                }
            }
        }
    }
}
