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
        configuration.credential = .md5Password(password: connection.password)
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

        return try PostgresClientKit.Connection(configuration: configuration)
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

        let provider = createProvider(for: connection.pgBossVersion)

        // Cache the provider
        providerCache[connection.id] = provider

        return provider
    }

    /// Create a schema provider for a specific version
    func createProvider(for version: PgBossVersion) -> any SchemaProvider {
        Self.createProviderSync(for: version)
    }

    /// Create a schema provider for a specific version (non-isolated)
    nonisolated static func createProviderSync(for version: PgBossVersion) -> any SchemaProvider {
        switch version {
        case .legacy:
            return SchemaLegacyProvider()
        case .v9:
            return SchemaV9Provider()
        case .v10:
            return SchemaV10Provider()
        case .v11Plus:
            return SchemaV11Provider()
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
        configuration.credential = .md5Password(password: connection.password)
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

        return try PostgresClientKit.Connection(configuration: configuration)
    }
}
