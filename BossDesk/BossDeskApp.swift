//
//  BossDeskApp.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

@main
struct BossDeskApp: App {
    @State private var connectionStore = ConnectionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(connectionStore)
        }

        WindowGroup("Queues", for: UUID.self) { $connectionId in
            if let connectionId = connectionId {
                QueuesView(connectionId: connectionId)
                    .environment(connectionStore)
            }
        }
        .defaultSize(width: 1200, height: 900)
        .restorationBehavior(.disabled)
    }
}
