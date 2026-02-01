//
//  ConnectionFormView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Form Data Model

private struct ConnectionFormData {
    var name: String = ""
    var host: String = ""
    var port: String = "5432"
    var database: String = ""
    var username: String = ""
    var password: String = ""
    var sslMode: Connection.SSLMode = .enabled
    var authMethod: Connection.AuthMethod = .auto
    var caCertificatePath: String = ""
    var clientCertificatePath: String = ""
    var clientKeyPath: String = ""
    var pgBossVersion: PgBossVersion = .v11Plus

    var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !database.isEmpty && !username.isEmpty && Int(port) != nil
    }

    init() {}

    init(from connection: Connection) {
        name = connection.name
        host = connection.host
        port = String(connection.port)
        database = connection.database
        username = connection.username
        password = connection.password
        sslMode = connection.sslMode
        authMethod = connection.authMethod
        caCertificatePath = connection.caCertificatePath
        clientCertificatePath = connection.clientCertificatePath
        clientKeyPath = connection.clientKeyPath
        pgBossVersion = connection.pgBossVersion
    }

    func toConnection(id: UUID) -> Connection {
        Connection(
            id: id,
            name: name,
            host: host,
            port: Int(port) ?? 5432,
            database: database,
            username: username,
            password: password,
            sslMode: sslMode,
            authMethod: authMethod,
            caCertificatePath: caCertificatePath,
            clientCertificatePath: clientCertificatePath,
            clientKeyPath: clientKeyPath,
            pgBossVersion: pgBossVersion
        )
    }
}

// MARK: - Form View

struct ConnectionFormView: View {
    @Environment(\.dismiss) private var dismiss

    let existingConnection: Connection?
    let onSave: (Connection) -> Bool

    @State private var formData = ConnectionFormData()
    @State private var isSaving = false
    @State private var testStatus: TestStatus = .idle
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var showingTestProgress = false
    @State private var testTask: Task<Void, Never>?

    private enum TestStatus: Equatable {
        case idle
        case testing
        case success
        case failure(String)
    }

    private var isEditing: Bool {
        existingConnection != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Connection Details") {
                    TextField("Name", text: $formData.name)
                    TextField("Host", text: $formData.host)
                    TextField("Port", text: $formData.port)
                    TextField("Database", text: $formData.database)
                    Picker("pg-boss Version", selection: $formData.pgBossVersion) {
                        ForEach(PgBossVersion.allCases, id: \.self) { version in
                            Text(version.displayName).tag(version)
                        }
                    }
                }

                Section("Authentication") {
                    TextField("Username", text: $formData.username)
                    SecureField("Password", text: $formData.password)
                    Picker("Method", selection: $formData.authMethod) {
                        ForEach(Connection.AuthMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .help("Auto tries SCRAM-SHA-256 first, falls back to MD5 for legacy servers")
                }

                Section("SSL / TLS") {
                    Picker("SSL Mode", selection: $formData.sslMode) {
                        ForEach(Connection.SSLMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    if formData.sslMode == .verifyCA {
                        CertificateField(label: "CA Certificate", path: $formData.caCertificatePath)
                        CertificateField(label: "Client Certificate (optional)", path: $formData.clientCertificatePath)
                        CertificateField(label: "Client Key (optional)", path: $formData.clientKeyPath)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .disabled(isSaving || testStatus == .testing)

                Spacer()

                testStatusView

                Button("Test Connection") {
                    testConnection()
                }
                .disabled(!formData.isValid || testStatus == .testing)

                Button("Save") {
                    saveConnection()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!formData.isValid || isSaving || testStatus == .testing)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 450)
        .overlay {
            if showingTestProgress {
                ZStack {
                    DesignTokens.Colors.overlayBackground
                        .ignoresSafeArea()

                    VStack(spacing: DesignTokens.Spacing.large) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Testing connection...")
                        Button("Cancel") {
                            cancelTest()
                        }
                        .controlSize(.small)
                    }
                    .padding(DesignTokens.Spacing.xxLarge)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                }
            }
        }
        .alert(
            testStatus == .success ? "Connection Successful" : "Connection Failed",
            isPresented: $showingTestResult
        ) {
            Button("OK") { }
        } message: {
            Text(testResultMessage)
        }
        .onAppear {
            if let connection = existingConnection {
                formData = ConnectionFormData(from: connection)
            }
        }
    }

    @ViewBuilder
    private var testStatusView: some View {
        switch testStatus {
        case .idle, .failure:
            EmptyView()
        case .testing:
            ProgressView()
                .controlSize(.small)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DesignTokens.Colors.success)
        }
    }

    private func testConnection() {
        testStatus = .testing
        showingTestProgress = true
        let connection = formData.toConnection(id: existingConnection?.id ?? UUID())

        testTask = Task {
            let result = await DatabaseService.testConnection(connection)
            await MainActor.run {
                showingTestProgress = false

                if case .failure(let error) = result, error == "Cancelled" {
                    testStatus = .idle
                    return
                }

                switch result {
                case .success:
                    testStatus = .success
                    testResultMessage = "Successfully connected to \(formData.database) on \(formData.host):\(formData.port)"
                case .failure(let error):
                    testStatus = .failure(error)
                    testResultMessage = error
                }
                showingTestResult = true
            }
        }
    }

    private func cancelTest() {
        testTask?.cancel()
        testTask = nil
        showingTestProgress = false
        testStatus = .idle
    }

    private func saveConnection() {
        isSaving = true
        let connection = formData.toConnection(id: existingConnection?.id ?? UUID())
        let success = onSave(connection)
        isSaving = false
        if success {
            dismiss()
        }
    }
}

// MARK: - Certificate Field

private struct CertificateField: View {
    let label: String
    @Binding var path: String

    var body: some View {
        HStack {
            TextField(label, text: $path)
                .textFieldStyle(.roundedBorder)
            Button("Browse...") {
                selectCertificateFile()
            }
        }
    }

    private func selectCertificateFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.x509Certificate, .data]
        panel.message = "Select a certificate or key file"

        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
        }
    }
}

// MARK: - Previews

#Preview("Add New") {
    ConnectionFormView(existingConnection: nil) { _ in true }
}

#Preview("Edit Existing") {
    ConnectionFormView(existingConnection: MockData.connections[0]) { _ in true }
}
