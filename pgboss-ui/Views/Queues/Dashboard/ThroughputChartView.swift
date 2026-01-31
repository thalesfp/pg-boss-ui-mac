//
//  ThroughputChartView.swift
//  pgboss-ui
//
//  Created by thales on 2026-01-30.
//

import SwiftUI
import Charts

struct ThroughputChartView: View {
    let data: ThroughputData
    let timeRange: TimeRange
    let isLoading: Bool

    @State private var selectedDate: Date?

    private var dataRangeDays: Int? {
        guard let minDate = data.points.min(by: { $0.timestamp < $1.timestamp })?.timestamp,
              let maxDate = data.points.max(by: { $0.timestamp < $1.timestamp })?.timestamp else {
            return nil
        }
        let days = Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0
        return max(days, 1)
    }

    private var xAxisStride: (unit: Calendar.Component, count: Int)? {
        switch timeRange {
        case .oneHour, .threeHours, .twentyFourHours:
            return nil
        case .sevenDays:
            return (xAxisUnit, 1)
        case .thirtyDays:
            return (xAxisUnit, 2)
        case .all:
            guard let days = dataRangeDays else {
                return (.day, 7)
            }

            if days <= 10 {
                return (.day, 1)
            }
            if days <= 45 {
                return (.day, 3)
            }
            if days <= 120 {
                return (.weekOfYear, 1)
            }
            if days <= 365 {
                return (.month, 1)
            }

            return (.month, 2)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Throughput")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if data.points.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("No completed jobs in this time range")
                )
                .frame(height: 200)
            } else {
                Chart(data.points) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Count", point.count),
                        series: .value("Status", point.category)
                    )
                    .foregroundStyle(by: .value("Status", point.category))
                    .interpolationMethod(.catmullRom)
                    .symbol(Circle())

                    if let selectedDate,
                       isSameBucket(point.timestamp, selectedDate) {
                        RuleMark(x: .value("Selected", selectedDate))
                            .foregroundStyle(Color.primary.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartForegroundStyleScale([
                    "Completed": Color.green,
                    "Failed": Color.red
                ])
                .chartXAxis {
                    if let stride = xAxisStride {
                        AxisMarks(values: .stride(by: stride.unit, count: stride.count)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: xAxisFormat)
                        }
                    } else {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: xAxisFormat)
                        }
                    }
                }
                .chartLegend(.visible)
                .chartXSelection(value: $selectedDate)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    selectedDate = proxy.value(atX: location.x, as: Date.self)
                                case .ended:
                                    selectedDate = nil
                                }
                            }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let selectedDate,
                       let points = pointsForSelectedDate(selectedDate) {
                        tooltipView(for: selectedDate, points: points)
                            .padding(DesignTokens.Spacing.small)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(DesignTokens.Spacing.large)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }

    private var xAxisUnit: Calendar.Component {
        switch timeRange {
        case .oneHour, .threeHours: return .minute
        case .twentyFourHours: return .hour
        default: return .day
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch timeRange {
        case .oneHour, .threeHours, .twentyFourHours:
            return .dateTime.hour().minute()
        case .all:
            if let stride = xAxisStride, stride.unit == .month {
                return .dateTime.month().year()
            }
            return .dateTime.month().day()
        default:
            return .dateTime.month().day()
        }
    }

    private func isSameBucket(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        switch timeRange {
        case .oneHour, .threeHours:
            return calendar.isDate(date1, equalTo: date2, toGranularity: .minute)
        case .twentyFourHours:
            return calendar.isDate(date1, equalTo: date2, toGranularity: .hour)
        default:
            return calendar.isDate(date1, equalTo: date2, toGranularity: .day)
        }
    }

    private func pointsForSelectedDate(_ date: Date) -> [ThroughputDataPoint]? {
        let matching = data.points.filter { isSameBucket($0.timestamp, date) }
        return matching.isEmpty ? nil : matching
    }

    @ViewBuilder
    private func tooltipView(for date: Date, points: [ThroughputDataPoint]) -> some View {
        let completed = points.first { $0.category == "Completed" }?.count ?? 0
        let failed = points.first { $0.category == "Failed" }?.count ?? 0

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
            Text(date, format: tooltipDateFormat)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: DesignTokens.Spacing.small) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Completed: \(completed)")
                    .font(.caption)
            }

            HStack(spacing: DesignTokens.Spacing.small) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Failed: \(failed)")
                    .font(.caption)
            }
        }
        .padding(DesignTokens.Spacing.small)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        .shadow(radius: 2)
    }

    private var tooltipDateFormat: Date.FormatStyle {
        switch timeRange {
        case .oneHour, .threeHours:
            return .dateTime.hour().minute()
        case .twentyFourHours:
            return .dateTime.month().day().hour().minute()
        default:
            return .dateTime.month().day()
        }
    }
}

#Preview("With Data") {
    let now = Date()
    let points: [ThroughputDataPoint] = (0..<12).flatMap { i -> [ThroughputDataPoint] in
        let timestamp = now.addingTimeInterval(-Double(11 - i) * 3600)
        return [
            ThroughputDataPoint(timestamp: timestamp, category: "Completed", count: Int.random(in: 50...200)),
            ThroughputDataPoint(timestamp: timestamp, category: "Failed", count: Int.random(in: 0...10))
        ]
    }

    ThroughputChartView(
        data: ThroughputData(points: points),
        timeRange: .twentyFourHours,
        isLoading: false
    )
    .padding()
    .frame(width: 600)
}

#Preview("Empty State") {
    ThroughputChartView(
        data: .empty,
        timeRange: .oneHour,
        isLoading: false
    )
    .padding()
    .frame(width: 600)
}

#Preview("Loading") {
    ThroughputChartView(
        data: .empty,
        timeRange: .twentyFourHours,
        isLoading: true
    )
    .padding()
    .frame(width: 600)
}
