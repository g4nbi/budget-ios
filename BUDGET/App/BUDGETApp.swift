import SwiftUI
import SwiftData

@main
struct BUDGETApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try AppContainer.make()
        } catch {
            fatalError("SwiftData container gagal dibuat: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .tint(Color(red: 0.24, green: 0.36, blue: 0.32))
        }
        .modelContainer(container)
    }
}
