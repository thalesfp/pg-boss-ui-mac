//
//  Connection.swift
//  pgboss-ui
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

    let id: UUID
    var name: String
    var host: String
    var port: Int
    var database: String
    var username: String
    var password: String
    var sslMode: SSLMode
    var caCertificatePath: String
    var clientCertificatePath: String
    var clientKeyPath: String
    var pgBossVersion: PgBossVersion

    init(id: UUID = UUID(), name: String, host: String, port: Int = 5432, database: String, username: String, password: String = "", sslMode: SSLMode = .enabled, caCertificatePath: String = "", clientCertificatePath: String = "", clientKeyPath: String = "", pgBossVersion: PgBossVersion = .v11Plus) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.database = database
        self.username = username
        self.password = password
        self.sslMode = sslMode
        self.caCertificatePath = caCertificatePath
        self.clientCertificatePath = clientCertificatePath
        self.clientKeyPath = clientKeyPath
        self.pgBossVersion = pgBossVersion
    }

    // Custom Codable implementation to exclude password from encoding
    enum CodingKeys: String, CodingKey {
        case id, name, host, port, database, username
        case sslMode, caCertificatePath, clientCertificatePath, clientKeyPath
        case pgBossVersion
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
        caCertificatePath = try container.decodeIfPresent(String.self, forKey: .caCertificatePath) ?? ""
        clientCertificatePath = try container.decodeIfPresent(String.self, forKey: .clientCertificatePath) ?? ""
        clientKeyPath = try container.decodeIfPresent(String.self, forKey: .clientKeyPath) ?? ""
        pgBossVersion = try container.decodeIfPresent(PgBossVersion.self, forKey: .pgBossVersion) ?? .v11Plus
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
        try container.encode(caCertificatePath, forKey: .caCertificatePath)
        try container.encode(clientCertificatePath, forKey: .clientCertificatePath)
        try container.encode(clientKeyPath, forKey: .clientKeyPath)
        try container.encode(pgBossVersion, forKey: .pgBossVersion)
    }
}
