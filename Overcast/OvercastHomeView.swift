import SwiftUI

struct OvercastHomeView: View {
    @EnvironmentObject private var store: OvercastStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: OvercastSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                OCTheme.backdrop.ignoresSafeArea()

                if store.entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            correlationCard
                                .padding(.top, 8)

                            ForEach(store.sortedEntries) { entry in
                                EntryRow(entry: entry) {
                                    activeSheet = .edit(entry)
                                } onDelete: {
                                    store.deleteEntry(entry.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Overcast")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddEntry(isPro: purchases.isPro) {
                            activeSheet = .add
                        } else {
                            activeSheet = .paywall
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("addEntryButton")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    EntryFormView(existing: nil)
                case .edit(let entry):
                    EntryFormView(existing: entry)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 64))
                .foregroundStyle(OCTheme.slate)
            Text("Log today's weather and mood")
                .font(OCTheme.headlineFont)
                .foregroundStyle(OCTheme.ink)
            Text("Over time, Overcast shows whether YOUR mood really tracks the weather.")
                .font(.subheadline)
                .foregroundStyle(OCTheme.inkFaded)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Log First Entry") {
                activeSheet = .add
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(OCTheme.slateDeep)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .accessibilityIdentifier("logFirstEntryButton")
        }
    }

    @ViewBuilder
    private var correlationCard: some View {
        let stats = store.correlationStats
        if !stats.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Weather-Mood Pattern")
                    .font(OCTheme.headlineFont)
                    .foregroundStyle(OCTheme.ink)
                ForEach(stats) { stat in
                    HStack {
                        Image(systemName: stat.weather.symbolName)
                            .foregroundStyle(OCTheme.skyColor(forMood: Int(stat.averageMood.rounded())))
                            .frame(width: 24)
                        Text(stat.weather.rawValue)
                            .foregroundStyle(OCTheme.ink)
                        Spacer()
                        Text(String(format: "%.1f avg", stat.averageMood))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(OCTheme.inkFaded)
                        Text("(\(stat.entryCount))")
                            .font(.caption2)
                            .foregroundStyle(OCTheme.inkFaded)
                    }
                }
            }
            .padding(16)
            .background(OCTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("correlationCard")
        }
    }
}

struct EntryRow: View {
    let entry: MoodEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(OCTheme.skyColor(forMood: entry.mood))
                    .frame(width: 48, height: 48)
                Image(systemName: entry.weather.symbolName)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OCTheme.ink)
                Text(entry.weather.rawValue + " · Mood \(entry.mood)/5")
                    .font(.caption)
                    .foregroundStyle(OCTheme.inkFaded)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(OCTheme.inkFaded)
                        .lineLimit(2)
                }
            }

            Spacer()

            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive) { showDeleteConfirm = true }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(OCTheme.slate)
                    .frame(width: 32, height: 32)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("entryMenu_\(entry.id)")
            .accessibilityAddTraits(.isButton)
            .contentShape(Rectangle())
        }
        .padding(14)
        .background(OCTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}
