//
//  DesignTokens.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-29.
//

import SwiftUI

enum DesignTokens {
    // MARK: - Spacing
    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        static let xxLarge: CGFloat = 20
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
    }

    // MARK: - Opacity
    enum Opacity {
        static let backgroundTint: Double = 0.15
        static let overlay: Double = 0.3
    }

    // MARK: - Table Column Widths
    enum TableColumn {
        static let idMin: CGFloat = 70
        static let idIdeal: CGFloat = 80
        static let stateMin: CGFloat = 80
        static let stateIdeal: CGFloat = 100
        static let numberMin: CGFloat = 40
        static let numberIdeal: CGFloat = 50
        static let dateMin: CGFloat = 100
        static let dateIdeal: CGFloat = 130
        static let paginationInfo: CGFloat = 100
    }

    // MARK: - Row Widths (for JobRowView)
    enum RowWidth {
        static let jobId: CGFloat = 80
        static let state: CGFloat = 100
        static let number: CGFloat = 50
        static let date: CGFloat = 130
    }

    // MARK: - Semantic Colors
    enum Colors {
        static let success = Color.green
        static let warning = Color.orange
        static var overlayBackground: Color {
            Color.black.opacity(Opacity.overlay)
        }

        // MARK: - JSON Syntax Highlighting
        enum JSON {
            static let key = Color.blue
            static let string = Color(red: 0.0, green: 0.6, blue: 0.5)  // Teal/green
            static let number = Color.purple
            static let boolean = Color.orange
            static let bracket = Color.gray
        }
    }

    // MARK: - Divider
    enum Divider {
        static let height: CGFloat = 20
    }

    // MARK: - Date Formatting
    enum DateFormat {
        static let shortDateTime: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm:ss"
            return formatter
        }()
    }

    // MARK: - Sidebar Specific
    enum Sidebar {
        static let rowVerticalPadding: CGFloat = 8
        static let rowHorizontalPadding: CGFloat = 4
        static let badgeRowSpacing: CGFloat = 6
        static let selectionIndicatorWidth: CGFloat = 3
        static let selectionIndicatorCornerRadius: CGFloat = 1.5
        static let badgeSpacing: CGFloat = 4
        static let badgeVerticalSpacing: CGFloat = 4
        static let queueNameSize: CGFloat = 14
        static let totalCountSize: CGFloat = 13
        static let scheduleNameSize: CGFloat = 14
        static let scheduleMetaSize: CGFloat = 11
    }

    // MARK: - Selection Colors
    enum Selection {
        static func background(isSelected: Bool) -> Color {
            isSelected ? Color.accentColor.opacity(0.12) : Color.clear
        }

        static func indicatorColor(isSelected: Bool) -> Color {
            isSelected ? Color.accentColor : Color.clear
        }
    }

    // MARK: - Typography
    enum Typography {
        static let queueNameWeight: Font.Weight = .semibold
        static let scheduleNameWeight: Font.Weight = .medium
        static let totalCountWeight: Font.Weight = .regular
        static let metaTextWeight: Font.Weight = .regular
    }
}
