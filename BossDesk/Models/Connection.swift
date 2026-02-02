//
//  Connection.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import Foundation

struct Connection: Identifiable, Hashable, Codable {
    enum SSLMode: String, Codable, CaseIterable {
        case disabled = "Disabled"
        case enabled = "Enabled"
        case verifyCA = "Verify CA"
    }

    enum AuthMethod: String, Codable, CaseIterable, Hashable, Sendable {
        case auto = "Auto"
        case scramSHA256 = "SCRAM-SHA-256"
        case md5 = "MD5"

        var displayName: String {
            return rawValue
        }
    }

    let id: UUID
    var name: String
    var host: String
    var port: Int
    var database: String
    var username: String
    var password: String
    var sslMode: SSLMode
    var authMethod: AuthMethod
    var caCertificatePath: String
    var clientCertificatePath: String
    var clientKeyPath: String
    var pgBossVersion: PgBossVersion
    var schema: String

    init(id: UUID = UUID(), name: String, host: String, port: Int = 5432, database: String, username: String, password: String = "", sslMode: SSLMode = .enabled, authMethod: AuthMethod = .auto, caCertificatePath: String = "", clientCertificatePath: String = "", clientKeyPath: String = "", pgBossVersion: PgBossVersion = .v11Plus, schema: String = "pgboss") {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.database = database
        self.username = username
        self.password = password
        self.sslMode = sslMode
        self.authMethod = authMethod
        self.caCertificatePath = caCertificatePath
        self.clientCertificatePath = clientCertificatePath
        self.clientKeyPath = clientKeyPath
        self.pgBossVersion = pgBossVersion
        self.schema = schema
    }

    // Custom Codable implementation to exclude password from encoding
    enum CodingKeys: String, CodingKey {
        case id, name, host, port, database, username
        case sslMode, authMethod, caCertificatePath, clientCertificatePath, clientKeyPath
        case pgBossVersion, schema
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(Int.self, forKey: .port)
        database = try container.decode(String.self, forKey: .database)
        username = try container.decode(String.self, forKey: .username)
        password = "" // Password loaded separately from Keychain
        sslMode = try container.decodeIfPresent(SSLMode.self, forKey: .sslMode) ?? .enabled
        authMethod = try container.decodeIfPresent(AuthMethod.self, forKey: .authMethod) ?? .auto
        caCertificatePath = try container.decodeIfPresent(String.self, forKey: .caCertificatePath) ?? ""
        clientCertificatePath = try container.decodeIfPresent(String.self, forKey: .clientCertificatePath) ?? ""
        clientKeyPath = try container.decodeIfPresent(String.self, forKey: .clientKeyPath) ?? ""
        pgBossVersion = try container.decodeIfPresent(PgBossVersion.self, forKey: .pgBossVersion) ?? .v11Plus
        let decodedSchema = try container.decodeIfPresent(String.self, forKey: .schema) ?? "pgboss"
        schema = Connection.isValidSchemaName(decodedSchema) ? decodedSchema : "pgboss"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(database, forKey: .database)
        try container.encode(username, forKey: .username)
        // Password intentionally not encoded - stored in Keychain
        try container.encode(sslMode, forKey: .sslMode)
        try container.encode(authMethod, forKey: .authMethod)
        try container.encode(caCertificatePath, forKey: .caCertificatePath)
        try container.encode(clientCertificatePath, forKey: .clientCertificatePath)
        try container.encode(clientKeyPath, forKey: .clientKeyPath)
        try container.encode(pgBossVersion, forKey: .pgBossVersion)
        try container.encode(schema, forKey: .schema)
    }

    // MARK: - Schema Validation

    /// Validates that a schema name is a safe PostgreSQL identifier.
    ///
    /// Safe identifiers:
    /// - Start with a lowercase letter or underscore
    /// - Contain only lowercase letters, digits, underscores, or dollar signs
    /// - Do not require quoting in SQL
    /// - Cannot be used for SQL injection
    ///
    /// This prevents SQL injection and ensures compatibility across all PostgreSQL versions.
    /// Schema names requiring quotes (mixed case, spaces, special chars) are rejected.
    ///
    /// - Parameter schema: The schema name to validate
    /// - Returns: true if the schema name is safe to use in SQL without quoting
    static func isValidSchemaName(_ schema: String) -> Bool {
        guard !schema.isEmpty else { return false }

        // PostgreSQL safe identifier pattern: must start with letter or underscore,
        // followed by letters, digits, underscores, or dollar signs (all lowercase)
        let pattern = "^[a-z_][a-z0-9_$]*$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(schema.startIndex..<schema.endIndex, in: schema)

        return regex?.firstMatch(in: schema, range: range) != nil
    }

    /// Human-readable description of valid schema name requirements
    static var schemaNameRequirements: String {
        "Schema names must start with a lowercase letter or underscore, and contain only lowercase letters, numbers, underscores, or dollar signs."
    }
}
