//
//  ConnectionStore.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import Foundation
import Observation

@Observable
class ConnectionStore {
    private static let storageKey = "savedConnections"

    private(set) var connections: [Connection] = []
    private(set) var lastError: String?

    init() {
        load()
    }

    func add(_ connection: Connection) throws {
        connections.append(connection)
        do {
            try KeychainHelper.savePassword(connection.password, for: connection.id)
            try save()  // Save AFTER keychain succeeds to avoid partial state
            lastError = nil
        } catch {
            // Rollback on failure
            connections.removeAll { $0.id == connection.id }
            lastError = error.localizedDescription
            throw error
        }
    }

    func update(_ connection: Connection) throws {
        guard let index = connections.firstIndex(where: { $0.id == connection.id }) else {
            let error = ConnectionStoreError.connectionNotFound
            lastError = error.localizedDescription
            throw error
        }

        let previousConnection = connections[index]
        connections[index] = connection

        do {
            try KeychainHelper.savePassword(connection.password, for: connection.id)
            try save()  // Save AFTER keychain succeeds to avoid partial state
            lastError = nil
        } catch {
            // Rollback on failure
            connections[index] = previousConnection
            lastError = error.localizedDescription
            throw error
        }
    }

    func delete(_ connection: Connection) throws {
        let previousConnections = connections
        connections.removeAll { $0.id == connection.id }

        do {
            try KeychainHelper.deletePassword(for: connection.id)
            try save()  // Save AFTER keychain succeeds to avoid partial state
            lastError = nil
        } catch {
            // Rollback on failure
            connections = previousConnections
            lastError = error.localizedDescription
            throw error
        }
    }

    func clearError() {
        lastError = nil
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            return
        }

        do {
            var loadedConnections = try JSONDecoder().decode([Connection].self, from: data)

            // Load passwords from Keychain
            for i in loadedConnections.indices {
                if let password = KeychainHelper.loadPassword(for: loadedConnections[i].id) {
                    loadedConnections[i].password = password
                }
            }

            connections = loadedConnections
        } catch {
            lastError = "Failed to load connections: \(error.localizedDescription)"
        }
    }

    private func save() throws {
        do {
            let data = try JSONEncoder().encode(connections)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            throw ConnectionStoreError.saveFailed(error.localizedDescription)
        }
    }

    enum ConnectionStoreError: LocalizedError {
        case connectionNotFound
        case saveFailed(String)

        var errorDescription: String? {
            switch self {
            case .connectionNotFound:
                return "Connection not found"
            case .saveFailed(let reason):
                return "Failed to save: \(reason)"
            }
        }
    }
}
