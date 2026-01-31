//
//  Schedule.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import Foundation

struct Schedule: Identifiable, Hashable {
    let name: String
    let cron: String
    let timezone: String?
    let data: String?
    let options: String?
    let createdOn: Date
    let updatedOn: Date

    var id: String { name }
}
