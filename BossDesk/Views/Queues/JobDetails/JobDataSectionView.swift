//
//  JobDataSectionView.swift
//  BossDesk
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

struct JobDataSectionView: View {
    let title: String
    let json: String

    @State private var copied = false

    private var highlightedJSON: AttributedString {
        syntaxHighlightJSON(json)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                SectionHeader(title)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(prettyPrintJSON(json), forType: .string)
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            VStack(alignment: .leading) {
                Text(highlightedJSON)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(DesignTokens.Spacing.medium)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .stroke(Color(nsColor: .tertiaryLabelColor), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        }
    }

    private func prettyPrintJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return jsonString
        }
        return prettyString
    }

    private func syntaxHighlightJSON(_ jsonString: String) -> AttributedString {
        let prettyJSON = prettyPrintJSON(jsonString)
        var result = AttributedString(prettyJSON)

        // Helper to apply color to regex matches
        func applyColor(_ pattern: String, color: Color, captureGroup: Int = 0) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
            let nsString = prettyJSON as NSString
            let matches = regex.matches(in: prettyJSON, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let range = captureGroup < match.numberOfRanges ? match.range(at: captureGroup) : match.range
                if range.location != NSNotFound,
                   let swiftRange = Range(range, in: prettyJSON),
                   let attrRange = Range(swiftRange, in: result) {
                    result[attrRange].foregroundColor = color
                }
            }
        }

        // Colorize brackets, braces, colons, commas
        applyColor("[\\[\\]{}:,]", color: DesignTokens.Colors.JSON.bracket)

        // Colorize numbers (integers and decimals, including negative)
        applyColor("(?<=[:\\s,\\[])\\s*(-?\\d+\\.?\\d*)(?=[,\\s\\]\\}]|$)", color: DesignTokens.Colors.JSON.number, captureGroup: 1)

        // Colorize booleans and null
        applyColor("\\b(true|false|null)\\b", color: DesignTokens.Colors.JSON.boolean)

        // Colorize string values (strings after colons)
        applyColor(":\\s*(\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\")", color: DesignTokens.Colors.JSON.string, captureGroup: 1)

        // Colorize keys (strings before colons) - do this last to override
        applyColor("(\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\")\\s*:", color: DesignTokens.Colors.JSON.key, captureGroup: 1)

        return result
    }
}

#Preview {
    JobDataSectionView(
        title: "INPUT DATA",
        json: "{\"to\": \"user@example.com\", \"subject\": \"Welcome!\"}"
    )
    .padding()
    .frame(width: 500)
}
