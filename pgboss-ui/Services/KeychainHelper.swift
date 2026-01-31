//
//  KeychainHelper.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import Foundation
import Security

struct KeychainHelper {
    private static let service = "pgboss-ui"

    enum KeychainError: LocalizedError {
        case encodingFailed
        case saveFailed(OSStatus)
        case deleteFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode password"
            case .saveFailed(let status):
                return "Failed to save password to Keychain (error \(status)): \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown")"
            case .deleteFailed(let status):
                return "Failed to delete password from Keychain (error \(status))"
            }
        }
    }

    static func savePassword(_ password: String, for connectionId: UUID) throws {
        let account = connectionId.uuidString
        guard let passwordData = password.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete existing item first (ignore errors - item may not exist)
        let _ = try? deletePassword(for: connectionId)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func loadPassword(for connectionId: UUID) -> String? {
        let account = connectionId.uuidString

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }

        return password
    }

    static func deletePassword(for connectionId: UUID) throws {
        let account = connectionId.uuidString

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
