import SwiftUI

@main
struct WaterBalloonARApp: App {
    var body: some Scene {
        WindowGroup {
            WaterBalloonGameView()
                .preferredColorScheme(.dark)
        }
    }
}
