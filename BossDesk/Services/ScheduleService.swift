//
//  ScheduleService.swift
//  BossDesk
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
                    let hasKeyColumn = provider.scheduleColumns?.key != nil

                    for row in cursor {
                        let columns = try row.get().columns

                        var columnIndex = 0
                        let name = try columns[columnIndex].string()
                        columnIndex += 1

                        // Parse key if present (v11+)
                        let key: String?
                        if hasKeyColumn {
                            key = try columns[columnIndex].string()
                            columnIndex += 1
                        } else {
                            key = nil
                        }

                        let cron = try columns[columnIndex].string()
                        columnIndex += 1

                        let timezone = try columns[columnIndex].optionalString()
                        columnIndex += 1

                        let data = try columns[columnIndex].optionalString()
                        columnIndex += 1

                        let options = try columns[columnIndex].optionalString()
                        columnIndex += 1

                        let createdOn = try columns[columnIndex].timestampWithTimeZone().date
                        columnIndex += 1

                        let updatedOn = try columns[columnIndex].timestampWithTimeZone().date

                        schedules.append(Schedule(
                            name: name,
                            key: key,
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
