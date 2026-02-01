//
//  Schedule.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

struct Schedule: Identifiable, Hashable {
    let name: String
    let key: String?          // nil for v10, value for v11+
    let cron: String
    let timezone: String?
    let data: String?
    let options: String?
    let createdOn: Date
    let updatedOn: Date

    // Composite identity: v10 uses name, v11+ uses name:key
    var id: String {
        if let key = key {
            // Percent-encode components to prevent separator injection
            let encodedName = name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? name
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
            return "\(encodedName):\(encodedKey)"  // v11+ composite with safe separator
        }
        return name  // v10 backward compatibility (no encoding needed for single component)
    }

    // Explicit Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(key)
    }

    static func == (lhs: Schedule, rhs: Schedule) -> Bool {
        lhs.name == rhs.name && lhs.key == rhs.key
    }
}
