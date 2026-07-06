import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: OvercastStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("overcast_daily_reminder") private var dailyReminder: Bool = false
    @State private var activeSheet: OvercastSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Daily evening log reminder", isOn: $dailyReminder)
                        .accessibilityIdentifier("dailyReminderToggle")
                        .onChange(of: dailyReminder) { _, newValue in
                            ReminderScheduler.setDailyReminder(enabled: newValue)
                        }
                }

                Section("Overcast Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(OCTheme.sunbeam)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(OCTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/overcast-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(OCTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all logged entries?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

enum ReminderScheduler {
    static func setDailyReminder(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        let identifier = "overcast_daily_reminder"
        if enabled {
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                let content = UNMutableNotificationContent()
                content.title = "Overcast"
                content.body = "How was today's weather and mood? Log it before you forget."
                content.sound = .default
                var comps = DateComponents()
                comps.hour = 20
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request)
            }
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(OvercastStore())
        .environmentObject(PurchaseManager())
}
