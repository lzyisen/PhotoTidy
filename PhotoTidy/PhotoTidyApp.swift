import SwiftUI

@main
struct PhotoTidyApp: App {
    @StateObject private var session = ReviewSession()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(session)
        }
    }
}
