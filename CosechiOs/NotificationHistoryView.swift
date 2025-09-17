// NotificationHistoryView.swift
import SwiftUI
import CoreData

struct NotificationHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: NotificationLog.entity(),
                  sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)])
    private var logs: FetchedResults<NotificationLog>
    
    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    Text("history_no_notifications")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(logs, id: \.id) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.title ?? "")
                                    .font(.headline)
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
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("history_title")
        }
    }
}
