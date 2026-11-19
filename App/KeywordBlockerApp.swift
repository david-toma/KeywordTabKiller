import SwiftUI

@main
struct KeywordBlockerApp: App {
    @StateObject private var store = KeywordStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onChange(of: scenePhase) { phase in
                    if phase == .active { store.reload() }
                }
        }
    }
}
