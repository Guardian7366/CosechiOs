// StatisticsView.swift
import SwiftUI
import CoreData
import Charts
import UIKit

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @FetchRequest(entity: TaskEntity.entity(), sortDescriptors: [])
    private var allTasks: FetchedResults<TaskEntity>

    @FetchRequest(entity: ProgressLog.entity(), sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    private var allProgressLogs: FetchedResults<ProgressLog>

    @FetchRequest(entity: NotificationLog.entity(), sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)])
    private var allNotifLogs: FetchedResults<NotificationLog>

    @FetchRequest(entity: UserCollection.entity(), sortDescriptors: [])
    private var allUserCollections: FetchedResults<UserCollection>

    @State private var selectedRange: RangeOption = .last7
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    enum RangeOption: Int, CaseIterable, Identifiable {
        case last7 = 7
        case last30 = 30
        case last90 = 90
        case all = 0

        var id: Int { rawValue }
        var titleKey: String {
            switch self {
            case .last7: return "statistics_range_7"
            case .last30: return "statistics_range_30"
            case .last90: return "statistics_range_90"
            case .all: return "statistics_range_all"
            }
        }
    }

    private var userTasks: [TaskEntity] {
        guard let uid = appState.currentUserID else { return [] }
        return allTasks.filter { $0.user?.userID == uid }
    }
    private var userLogs: [ProgressLog] {
        guard let uid = appState.currentUserID else { return [] }
        return allProgressLogs.filter { $0.user?.userID == uid }
    }
    private var userNotifs: [NotificationLog] {
        guard let uid = appState.currentUserID else { return [] }
        return Array(allNotifLogs).filter { $0.user?.userID == uid }
    }
    private var userCollectionsCount: Int {
        guard let uid = appState.currentUserID else { return 0 }
        return allUserCollections.filter { $0.user?.userID == uid }.count
    }

    private func dateThreshold() -> Date? {
        if selectedRange == .all { return nil }
        return Calendar.current.date(byAdding: .day, value: -selectedRange.rawValue, to: Date())
    }

    private var logsInRange: [ProgressLog] {
        if let th = dateThreshold() {
            return userLogs.filter { ($0.date ?? Date.distantPast) >= th }
        } else { return userLogs }
    }
    private var tasksInRange: [TaskEntity] {
        if let th = dateThreshold() {
            return userTasks.filter { ($0.createdAt ?? Date.distantPast) >= th }
        } else { return userTasks }
    }

    var body: some View {
        FrutigerAeroBackground {
            ScrollView {
                VStack(spacing: 20) {
                    // 📌 Header
                    AeroHeader(
                        LocalizationHelper.shared.localized("statistics_title"),
                        subtitle: LocalizationHelper.shared.localized("statistics_subtitle")
                    )
                    .padding(.horizontal)

                    // 📌 Filtros + Export
                    GlassCard {
                        HStack {
                            Picker("", selection: $selectedRange) {
                                ForEach(RangeOption.allCases) { r in
                                    Text(LocalizationHelper.shared.localized(r.titleKey)).tag(r)
                                }
                            }
                            .pickerStyle(.segmented)

                            Spacer()

                            Button {
                                exportCSV()
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                Text(LocalizationHelper.shared.localized("statistics_export_csv"))
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal)

                    // 📌 Summary Cards
                    HStack(spacing: 12) {
                        summaryCard(color: .green, titleKey: "statistics_summary_total_tasks", valueText: "\(userTasks.count)")
                        summaryCard(color: .blue, titleKey: "statistics_summary_completed_pct", valueText: completedPercentage)
                        summaryCard(color: .teal, titleKey: "statistics_summary_my_crops", valueText: "\(userCollectionsCount)")
                    }
                    .padding(.horizontal)

                    // 📊 Tasks
                    section("statistics_tasks") {
                        if userTasks.isEmpty {
                            placeholderText("statistics_no_tasks")
                        } else {
                            HStack {
                                PieChartView(completed: completedCount, pending: pendingCount, overdue: overdueCount)
                                    .frame(width: 160, height: 160)

                                VStack(alignment: .leading, spacing: 8) {
                                    metricRow(color: .green, value: completedCount, key: "statistics_metrics_completed")
                                    metricRow(color: .blue, value: pendingCount, key: "statistics_metrics_pending")
                                    metricRow(color: .red, value: overdueCount, key: "statistics_metrics_overdue")
                                }
                                .padding(.leading)
                                Spacer()
                            }
                        }
                    }

                    // 📈 Progress Logs
                    section("statistics_progress") {
                        if logsInRange.isEmpty {
                            placeholderText("statistics_no_progress_logs")
                        } else {
                            LogsLineChart(logs: logsInRange, days: selectedRange == .all ? 30 : selectedRange.rawValue)
                                .frame(height: 220)
                        }
                    }

                    // 🌱 Top Crops
                    section("statistics_top_crops") {
                        let top = topCrops.prefix(6)
                        if top.isEmpty {
                            placeholderText("statistics_no_top_crops")
                        } else {
                            GlassCard {
                                Chart {
                                    ForEach(Array(top.enumerated()), id: \.offset) { _, item in
                                        BarMark(
                                            x: .value("Count", item.count),
                                            y: .value("Crop", item.name)
                                        )
                                        .annotation(position: .trailing) {
                                            Text("\(item.count)").font(.caption2)
                                        }
                                    }
                                }
                                .frame(height: min(240, CGFloat(top.count * 40)))
                            }
                        }
                    }

                    // 🔔 Notifications
                    section("statistics_notifications") {
                        if actionCounts.isEmpty {
                            placeholderText("statistics_no_notifications")
                        } else {
                            GlassCard {
                                Chart {
                                    ForEach(actionCounts.keys.sorted(), id: \.self) { action in
                                        BarMark(
                                            x: .value("Count", actionCounts[action] ?? 0),
                                            y: .value("Action", action)
                                        )
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle(LocalizationHelper.shared.localized("statistics_title"))
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: shareItems)
            }
        }
    }

    // MARK: - UI Helpers
    private func summaryCard(color: Color, titleKey: String, valueText: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizationHelper.shared.localized(titleKey))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valueText)
                    .font(.title2)
                    .bold()
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func placeholderText(_ key: String) -> some View {
        Text(LocalizationHelper.shared.localized(key))
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
    }

    private func metricRow(color: Color, value: Int, key: String) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(LocalizationHelper.shared.localized(key))
                .font(.subheadline)
            Spacer()
            Text("\(value)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Computed values
    private var completedCount: Int {
        userTasks.filter { $0.status == "completed" }.count
    }
    private var pendingCount: Int {
        userTasks.filter { $0.status == "pending" }.count
    }
    private var overdueCount: Int {
        let now = Date()
        return userTasks.filter { ($0.status ?? "") != "completed" && ($0.dueDate ?? now) < now }.count
    }
    private var completedPercentage: String {
        let total = max(userTasks.count, 1)
        let pct = Int((Double(completedCount) / Double(total)) * 100.0)
        return "\(pct)%"
    }
    private var actionCounts: [String: Int] {
        var dict: [String: Int] = [:]
        for log in userNotifs {
            if let type = log.type, type.hasPrefix("action:") {
                let key = type.replacingOccurrences(of: "action:", with: "")
                dict[key, default: 0] += 1
            }
        }
        return dict
    }
    private var topCrops: [(name: String, count: Int, crop: Crop?)] {
        var map: [String: (Int, Crop?)] = [:]
        for log in userLogs {
            let name = log.crop?.name ?? NSLocalizedString("crop_default", comment: "")
            map[name, default: (0, log.crop)] = (map[name, default: (0, nil)].0 + 1, map[name, default: (0, nil)].1 ?? log.crop)
        }
        return map.map { (name, pair) in (name, pair.0, pair.1) }
            .sorted { $0.1 > $1.1 }
    }

    // MARK: - CSV Export
    private func exportCSV() {
        var csv = "Metric,Value\n"
        csv += "Total Tasks,\(userTasks.count)\n"
        csv += "Completed,\(completedCount)\n"
        csv += "Pending,\(pendingCount)\n"
        csv += "Overdue,\(overdueCount)\n"
        csv += "CompletedPct,\(completedPercentage)\n"
        csv += "CropsInCollection,\(userCollectionsCount)\n\n"

        csv += "TopCrops,Count\n"
        for item in topCrops.prefix(20) {
            csv += "\(item.name),\(item.count)\n"
        }

        csv += "\nProgressLogDate,Crop,Note\n"
        let formatter = ISO8601DateFormatter()
        for log in logsInRange {
            let date = formatter.string(from: log.date ?? Date())
            let crop = log.crop?.name ?? ""
            let note = (log.note ?? "").replacingOccurrences(of: "\n", with: " ")
            csv += "\(date),\(crop),\"\(note)\"\n"
        }

        if let data = csv.data(using: .utf8) {
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("cosechi_stats_\(Int(Date().timeIntervalSince1970)).csv")
            do {
                try data.write(to: tmpURL)
                shareItems = [tmpURL]
                showShareSheet = true
            } catch {
                UIPasteboard.general.string = csv
                shareItems = [csv]
                showShareSheet = true
            }
        } else {
            UIPasteboard.general.string = csv
            shareItems = [csv]
            showShareSheet = true
        }
    }

    @ViewBuilder
    private func section(_ key: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationHelper.shared.localized(key))
                .font(.headline)
                .padding(.horizontal)
            content()
        }
    }
}

// MARK: - Charts
private struct PieChartView: View {
    let completed: Int
    let pending: Int
    let overdue: Int

    var body: some View {
        Chart {
            if completed > 0 {
                SectorMark(angle: .value("Completed", completed), innerRadius: .ratio(0.5))
                    .foregroundStyle(.green)
            }
            if pending > 0 {
                SectorMark(angle: .value("Pending", pending), innerRadius: .ratio(0.5))
                    .foregroundStyle(.blue)
            }
            if overdue > 0 {
                SectorMark(angle: .value("Overdue", overdue), innerRadius: .ratio(0.5))
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct LogsLineChart: View {
    let logs: [ProgressLog]
    let days: Int

    private var dailyCounts: [(Date, Int)] {
        let cal = Calendar.current
        let start: Date = days <= 0 ? cal.date(byAdding: .day, value: -30, to: Date()) ?? Date() : cal.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var dict: [Date: Int] = [:]
        for log in logs {
            let d = cal.startOfDay(for: log.date ?? Date())
            if d < start { continue }
            dict[d, default: 0] += 1
        }
        var arr: [(Date, Int)] = []
        var cur = start
        let today = cal.startOfDay(for: Date())
        while cur <= today {
            arr.append((cur, dict[cur] ?? 0))
            cur = cal.date(byAdding: .day, value: 1, to: cur) ?? today.addingTimeInterval(86400)
        }
        return arr
    }

    var body: some View {
        Chart {
            ForEach(dailyCounts, id: \.0) { item in
                LineMark(x: .value("Date", item.0), y: .value("Count", item.1))
                PointMark(x: .value("Date", item.0), y: .value("Count", item.1))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, dailyCounts.count / 6))) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
    }
}

// MARK: - ActivityView for Share
private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
