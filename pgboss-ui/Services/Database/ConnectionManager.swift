//
//  ConnectionManager.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation
import PostgresClientKit
import SSLService

/// Centralized connection management
actor ConnectionManager {
    static let shared = ConnectionManager()

    private let connectionTimeoutSeconds = 30

    /// Cache of schema providers per connection (keyed by connection ID)
    private var providerCache: [UUID: any SchemaProvider] = [:]

    private init() {}

    // MARK: - Connection Creation

    /// Create a new PostgresClientKit connection from a Connection model
    /// - Parameter connection: The Connection configuration
    /// - Returns: An open PostgresClientKit.Connection
    func createConnection(_ connection: Connection) throws -> PostgresClientKit.Connection {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = connection.host
        configuration.port = connection.port
        configuration.database = connection.database
        configuration.user = connection.username

        // Set credential based on auth method
        switch connection.authMethod {
        case .scramSHA256:
            configuration.credential = .scramSHA256(password: connection.password)
        case .md5:
            configuration.credential = .md5Password(password: connection.password)
        case .auto:
            // Try SCRAM first
            configuration.credential = .scramSHA256(password: connection.password)
        }

        configuration.socketTimeout = connectionTimeoutSeconds

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

        // For auto mode, catch auth errors and retry with MD5
        if connection.authMethod == .auto {
            do {
                return try PostgresClientKit.Connection(configuration: configuration)
            } catch let error as PostgresError {
                // If SCRAM failed with MD5 required error, retry with MD5
                if case .md5PasswordCredentialRequired = error {
                    configuration.credential = .md5Password(password: connection.password)
                    return try PostgresClientKit.Connection(configuration: configuration)
                }
                throw error
            }
        } else {
            return try PostgresClientKit.Connection(configuration: configuration)
        }
    }

    // MARK: - Schema Provider

    /// Get the appropriate schema provider for a connection
    /// - Parameter connection: The Connection configuration
    /// - Returns: A SchemaProvider for the connection's selected pg-boss version
    func getProvider(for connection: Connection) -> any SchemaProvider {
        // Check provider cache first
        if let cached = providerCache[connection.id] {
            return cached
        }

        let provider = createProvider(for: connection.pgBossVersion, schema: connection.schema)

        // Cache the provider
        providerCache[connection.id] = provider

        return provider
    }

    /// Create a schema provider for a specific version
    func createProvider(for version: PgBossVersion, schema: String) -> any SchemaProvider {
        Self.createProviderSync(for: version, schema: schema)
    }

    /// Create a schema provider for a specific version (non-isolated)
    nonisolated static func createProviderSync(for version: PgBossVersion, schema: String = "pgboss") -> any SchemaProvider {
        switch version {
        case .legacy:
            return SchemaLegacyProvider(schema: schema)
        case .v9:
            return SchemaV9Provider(schema: schema)
        case .v10:
            return SchemaV10Provider(schema: schema)
        case .v11Plus:
            return SchemaV11Provider(schema: schema)
        }
    }

    // MARK: - Cache Management

    /// Clear cached provider for a connection
    func clearCache(for connectionId: UUID) {
        providerCache.removeValue(forKey: connectionId)
    }

    /// Clear all cached data
    func clearAllCaches() {
        providerCache.removeAll()
    }
}

// MARK: - Non-Actor Static Helpers

extension ConnectionManager {
    /// Create a connection synchronously (for use in non-async contexts)
    /// This is a static helper that doesn't use the actor
    static func createConnectionSync(_ connection: Connection, timeout: Int = 30) throws -> PostgresClientKit.Connection {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = connection.host
        configuration.port = connection.port
        configuration.database = connection.database
        configuration.user = connection.username

        // Set credential based on auth method
        switch connection.authMethod {
        case .scramSHA256:
            configuration.credential = .scramSHA256(password: connection.password)
        case .md5:
            configuration.credential = .md5Password(password: connection.password)
        case .auto:
            configuration.credential = .scramSHA256(password: connection.password)
        }

        configuration.socketTimeout = timeout

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

        // For auto mode, catch auth errors and retry with MD5
        if connection.authMethod == .auto {
            do {
                return try PostgresClientKit.Connection(configuration: configuration)
            } catch let error as PostgresError {
                if case .md5PasswordCredentialRequired = error {
                    configuration.credential = .md5Password(password: connection.password)
                    return try PostgresClientKit.Connection(configuration: configuration)
                }
                throw error
            }
        } else {
            return try PostgresClientKit.Connection(configuration: configuration)
        }
    }
}
