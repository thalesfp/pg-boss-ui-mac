//
//  ConnectionManagerView.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct ConnectionManagerView: View {
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(\.openWindow) private var openWindow
    @State private var selectedConnection: Connection?
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var showingDuplicateSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isConnecting = false

    var body: some View {
        NavigationSplitView {
            List(connectionStore.connections, selection: $selectedConnection) { connection in
                ConnectionListItemView(connection: connection)
                    .tag(connection)
            }
            .contextMenu(forSelectionType: Connection.self, menu: { selection in
                if let connection = selection.first {
                    Button {
                        selectedConnection = connection
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        selectedConnection = connection
                        showingDuplicateSheet = true
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive) {
                        selectedConnection = connection
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }, primaryAction: { selection in
                guard let connection = selection.first else { return }
                connect(to: connection)
            })
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        } detail: {
            if let connection = selectedConnection {
                ConnectionDetailView(connection: connection)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("BossDesk")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if isConnecting {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Connect") {
                    if let connection = selectedConnection {
                        connect(to: connection)
                    }
                }
                .disabled(selectedConnection == nil || isConnecting)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ConnectionFormView(existingConnection: nil) { newConnection in
                do {
                    try connectionStore.add(newConnection)
                    return true
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                    return false
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let connection = selectedConnection {
                ConnectionFormView(existingConnection: connection) { updatedConnection in
                    do {
                        try connectionStore.update(updatedConnection)
                        selectedConnection = updatedConnection
                        return true
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                        return false
                    }
                }
            }
        }
        .sheet(isPresented: $showingDuplicateSheet) {
            if let connection = selectedConnection {
                let duplicateConnection = Connection(
                    id: UUID(),
                    name: connection.name + " (Copy)",
                    host: connection.host,
                    port: connection.port,
                    database: connection.database,
                    username: connection.username,
                    password: connection.password,
                    sslMode: connection.sslMode,
                    authMethod: connection.authMethod,
                    caCertificatePath: connection.caCertificatePath,
                    clientCertificatePath: connection.clientCertificatePath,
                    clientKeyPath: connection.clientKeyPath,
                    schema: connection.schema
                )

                ConnectionFormView(existingConnection: duplicateConnection) { newConnection in
                    do {
                        try connectionStore.add(newConnection)
                        return true
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                        return false
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Connection",
            isPresented: $showingDeleteConfirmation,
            presenting: selectedConnection
        ) { connection in
            Button("Delete \"\(connection.name)\"", role: .destructive) {
                deleteSelectedConnection()
            }
        } message: { connection in
            Text("Are you sure you want to delete \"\(connection.name)\"? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Connection Selected", systemImage: "server.rack")
        } description: {
            Text("Select a connection from the sidebar or add a new one.")
        } actions: {
            Button("Add Connection") {
                showingAddSheet = true
            }
        }
    }

    private func deleteSelectedConnection() {
        guard let connection = selectedConnection else { return }
        do {
            try connectionStore.delete(connection)
            selectedConnection = nil
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func connect(to connection: Connection) {
        isConnecting = true

        Task {
            let result = await DatabaseService.testConnection(connection)

            await MainActor.run {
                isConnecting = false

                switch result {
                case .success:
                    openWindow(value: connection.id)
                case .failure(let message):
                    errorMessage = "Failed to connect: \(message)"
                    showingError = true
                }
            }
        }
    }
}

struct ConnectionDetailView: View {
    let connection: Connection

    var body: some View {
        Form {
            Section("Connection") {
                LabeledContent("Name", value: connection.name)
                LabeledContent("Host", value: connection.host)
                LabeledContent("Port", value: String(connection.port))
                LabeledContent("Database", value: connection.database)
                LabeledContent("Schema", value: connection.schema)
            }

            Section("Authentication") {
                LabeledContent("Username", value: connection.username)
                LabeledContent("Password", value: String(repeating: "•", count: max(connection.password.count, 8)))
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 300)
    }
}

#Preview {
    ConnectionManagerView()
        .environment(MockData.createPreviewStore())
}
