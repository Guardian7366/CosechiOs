// NotificationHistoryView.swift
import SwiftUI
import CoreData

struct NotificationHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var theme: AeroTheme

    @FetchRequest(
        entity: NotificationLog.entity(),
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
    )
    private var logs: FetchedResults<NotificationLog>
    
    var body: some View {
        FrutigerAeroBackground {
            List {
                if logs.isEmpty {
                    Text("history_no_notifications")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(logs, id: \.id) { log in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(log.title ?? "")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if let d = log.date {
                                        Text(d, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text(log.body ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if let t = log.type {
                                    Text(t.capitalized)
                                        .font(.caption2)
                                        .foregroundColor(theme.accent)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("history_title")
        }
    }
}
