//
//  DatabaseService.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import Foundation
import PostgresClientKit
import SSLService

struct DatabaseService {
    private static let connectionTimeoutSeconds = 30

    enum TestResult: Sendable {
        case success
        case failure(String)
    }

    /// Thread-safe cancellation state shared between Task and GCD queue
    private final class CancellationState: @unchecked Sendable {
        private let lock = NSLock()
        private var _isCancelled = false

        var isCancelled: Bool {
            lock.lock()
            defer { lock.unlock() }
            return _isCancelled
        }

        func cancel() {
            lock.lock()
            _isCancelled = true
            lock.unlock()
        }
    }

    static func testConnection(_ connection: Connection) async -> TestResult {
        let cancellation = CancellationState()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    // Check for cancellation before starting
                    if cancellation.isCancelled {
                        continuation.resume(returning: .failure("Cancelled"))
                        return
                    }

                    do {
                        var configuration = PostgresClientKit.ConnectionConfiguration()
                        configuration.host = connection.host
                        configuration.port = connection.port
                        configuration.database = connection.database
                        configuration.user = connection.username
                        configuration.credential = .md5Password(password: connection.password)
                        configuration.socketTimeout = connectionTimeoutSeconds

                        // Configure SSL based on connection settings
                        switch connection.sslMode {
                        case .disabled:
                            configuration.ssl = false
                        case .enabled:
                            configuration.ssl = true
                        case .verifyCA:
                            configuration.ssl = true
                            configuration.sslServiceConfiguration = SSLService.Configuration(
                                withCACertificateFilePath: connection.caCertificatePath.isEmpty ? nil : connection.caCertificatePath,
                                usingCertificateFile: connection.clientCertificatePath.isEmpty ? nil : connection.clientCertificatePath,
                                withKeyFile: connection.clientKeyPath.isEmpty ? nil : connection.clientKeyPath
                            )
                        }

                        let conn = try PostgresClientKit.Connection(configuration: configuration)
                        defer { conn.close() }

                        // Check for cancellation after connection established
                        if cancellation.isCancelled {
                            continuation.resume(returning: .failure("Cancelled"))
                            return
                        }

                        // Execute a simple query to verify the connection works
                        let statement = try conn.prepareStatement(text: "SELECT 1")
                        defer { statement.close() }
                        let cursor = try statement.execute()
                        cursor.close()

                        continuation.resume(returning: .success)
                    } catch let error as PostgresError {
                        continuation.resume(returning: .failure(String(describing: error)))
                    } catch {
                        continuation.resume(returning: .failure(error.localizedDescription))
                    }
                }
            }
        } onCancel: {
            cancellation.cancel()
        }
    }
}
