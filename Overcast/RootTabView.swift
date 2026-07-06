import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            OvercastHomeView()
                .tabItem {
                    Label("Log", systemImage: "cloud.sun.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(OCTheme.slateDeep)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(OCTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(OvercastStore())
        .environmentObject(PurchaseManager())
}
