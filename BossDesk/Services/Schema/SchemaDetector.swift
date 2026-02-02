//
//  SchemaDetector.swift
//  BossDesk
//
//  Created by Claude Code on 2026-02-02.
//

import Foundation
@preconcurrency import PostgresClientKit

@preconcurrency
protocol SchemaDetecting: Sendable {
    func detectSchemaVersion(connection: Connection) async throws -> SchemaVersion
}

@preconcurrency
actor SchemaDetector: SchemaDetecting {
    enum DetectionError: LocalizedError {
        case versionTableNotFound
        case noVersionFound
        case unsupportedVersion(Int)
        case connectionFailed(String)

        var errorDescription: String? {
            switch self {
            case .versionTableNotFound:
                return "pg-boss schema not found. Ensure pg-boss is initialized in the database."

            case .noVersionFound:
                return "Could not detect pg-boss schema version. The version table may be empty."

            case .unsupportedVersion(let version):
                return "Unsupported pg-boss schema version \(version). BossDesk supports versions 20-27 (pg-boss v7-v11+). Please upgrade or downgrade your pg-boss installation."

            case .connectionFailed(let message):
                return "Failed to connect: \(message)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .versionTableNotFound:
                return "Verify that pg-boss has been initialized by running a job queue in your application."

            case .noVersionFound:
                return "Check that the version table exists and contains at least one version record."

            case .unsupportedVersion(let version):
                if version < 20 {
                    return "Your pg-boss installation (schema v\(version)) is too old. Upgrade to pg-boss v7 or later."
                } else {
                    return "Your pg-boss installation (schema v\(version)) is newer than supported. BossDesk may need an update."
                }

            case .connectionFailed:
                return "Check your connection settings and database credentials."
            }
        }
    }

    func detectSchemaVersion(connection: Connection) async throws -> SchemaVersion {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conn = try ConnectionManager.createConnectionSync(connection)
                    defer { conn.close() }

                    // Query the version table directly
                    let sql = "SELECT version FROM \(connection.schema).version ORDER BY version DESC LIMIT 1"
                    let statement = try conn.prepareStatement(text: sql)
                    defer { statement.close() }

                    let cursor = try statement.execute()
                    defer { cursor.close() }

                    guard let row = cursor.next() else {
                        throw DetectionError.noVersionFound
                    }

                    let columns = try row.get().columns
                    let versionNumber = try columns[0].int()

                    let schemaVersion = SchemaVersion(rawValue: versionNumber)

                    // Validate supported range (20-27)
                    guard versionNumber >= 20 && versionNumber <= 27 else {
                        throw DetectionError.unsupportedVersion(versionNumber)
                    }

                    continuation.resume(returning: schemaVersion)
                } catch let error as PostgresError {
                    // Use SQLSTATE codes for precise error detection
                    if case .sqlError(let notice) = error {
                        // SQLSTATE 42P01 = relation (table/view) does not exist
                        if notice.code == "42P01" {
                            continuation.resume(throwing: DetectionError.versionTableNotFound)
                        } else {
                            // All other SQL errors (auth, missing database, etc.)
                            continuation.resume(throwing: DetectionError.connectionFailed(notice.message ?? String(describing: error)))
                        }
                    } else {
                        // Non-SQL PostgresErrors (network issues, etc.)
                        continuation.resume(throwing: DetectionError.connectionFailed(String(describing: error)))
                    }
                } catch let error as DetectionError {
                    continuation.resume(throwing: error)
                } catch {
                    continuation.resume(throwing: DetectionError.connectionFailed(String(describing: error)))
                }
            }
        }
    }
}
