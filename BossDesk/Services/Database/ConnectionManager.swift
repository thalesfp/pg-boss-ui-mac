//
//  ConnectionManager.swift
//  BossDesk
//
//  Created by thales on 2026-01-30.
//

import Foundation
import PostgresClientKit
import SSLService

/// Cache key for schema providers, including both connection ID and schema name
private struct ProviderCacheKey: Hashable {
    let connectionId: UUID
    let schema: String
}

/// Centralized connection management
actor ConnectionManager {
    static let shared = ConnectionManager()

    private let connectionTimeoutSeconds = 30

    /// Cache of schema providers per connection (keyed by connection ID + schema)
    private var providerCache: [ProviderCacheKey: any SchemaProvider] = [:]

    /// Cache of detected schema versions per connection (keyed by connection ID + schema)
    private var detectedVersionCache: [ProviderCacheKey: SchemaVersion] = [:]

    /// Schema detector service
    private let detector: any SchemaDetecting

    private init(detector: any SchemaDetecting = SchemaDetector()) {
        self.detector = detector
    }

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

    /// Get provider with automatic schema detection
    /// - Parameter connection: The Connection configuration
    /// - Returns: A SchemaProvider for the connection's detected schema version
    func getProvider(for connection: Connection) async throws -> any SchemaProvider {
        let cacheKey = ProviderCacheKey(connectionId: connection.id, schema: connection.schema)

        // Check cache first
        if let cached = providerCache[cacheKey] {
            return cached
        }

        // Detect schema version
        let version = try await detector.detectSchemaVersion(connection: connection)
        detectedVersionCache[cacheKey] = version

        // Create appropriate adapter based on version
        let provider = createAdapter(for: version, schema: connection.schema)
        providerCache[cacheKey] = provider

        return provider
    }

    /// Create adapter for a specific schema version
    func createAdapter(for version: SchemaVersion, schema: String) -> any SchemaProvider {
        Self.createAdapterSync(for: version, schema: schema)
    }

    /// Create adapter for a specific schema version (non-isolated)
    nonisolated static func createAdapterSync(for version: SchemaVersion, schema: String = "pgboss") -> any SchemaProvider {
        // Map schema version number to appropriate adapter
        switch version.adapterGroup {
        case .camelCase:
            return Schema20To23Adapter(schema: schema)
        case .snakeCaseV10:
            return Schema24To25Adapter(schema: schema)
        case .snakeCaseV11Plus:
            return Schema26To27Adapter(schema: schema)
        case .unknown:
            // Fallback to latest adapter for forward compatibility
            return Schema26To27Adapter(schema: schema)
        }
    }

    /// Get detected schema version for a connection (for display purposes)
    /// - Parameters:
    ///   - connectionId: The connection ID
    ///   - schema: The schema name
    /// - Returns: The detected SchemaVersion, if available in cache
    func getDetectedVersion(for connectionId: UUID, schema: String) -> SchemaVersion? {
        let cacheKey = ProviderCacheKey(connectionId: connectionId, schema: schema)
        return detectedVersionCache[cacheKey]
    }

    /// Check if a schema version is supported
    func isVersionSupported(_ version: SchemaVersion) -> Bool {
        version.rawValue >= 20 && version.rawValue <= 27
    }

    // MARK: - Cache Management

    /// Clear cached provider for a connection and schema
    /// - Parameters:
    ///   - connectionId: The connection ID
    ///   - schema: The schema name (if nil, clears all schemas for this connection)
    func clearCache(for connectionId: UUID, schema: String? = nil) {
        if let schema = schema {
            let cacheKey = ProviderCacheKey(connectionId: connectionId, schema: schema)
            providerCache.removeValue(forKey: cacheKey)
            detectedVersionCache.removeValue(forKey: cacheKey)
        } else {
            // Clear all schemas for this connection
            providerCache = providerCache.filter { $0.key.connectionId != connectionId }
            detectedVersionCache = detectedVersionCache.filter { $0.key.connectionId != connectionId }
        }
    }

    /// Clear all cached data
    func clearAllCaches() {
        providerCache.removeAll()
        detectedVersionCache.removeAll()
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
