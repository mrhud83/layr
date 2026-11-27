import SwiftUI
import ARKit
import SceneKit

struct WaterBalloonGameView: View {
    @StateObject private var game = BalloonGameController()

    var body: some View {
        ZStack {
            BalloonARView(game: game)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("LAYR / WATER LAB").font(.system(size: 12, weight: .semibold, design: .monospaced))
                        Text(game.status).font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("\(game.hits) HITS")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .padding(18)
                .background(.black.opacity(0.28))

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                HStack(spacing: 12) {
                    Button("BLOCKS") { game.placeBlocks() }
                        .buttonStyle(LabButtonStyle())
                    Button("RESET") { game.reset() }
                        .buttonStyle(LabButtonStyle())
                    Spacer(minLength: 6)
                    Button { game.throwBalloon() } label: {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 25))
                            .frame(width: 78, height: 78)
                            .background(Color(red: 0.1, green: 0.72, blue: 0.95))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Throw water balloon")
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct LabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 18)
            .frame(height: 46)
            .background(.black.opacity(configuration.isPressed ? 0.6 : 0.38))
            .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

struct BalloonARView: UIViewRepresentable {
    @ObservedObject var game: BalloonGameController

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.delegate = game
        view.scene.physicsWorld.contactDelegate = game
        view.scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        view.automaticallyUpdatesLighting = true
        view.autoenablesDefaultLighting = true
        view.debugOptions = []
        game.attach(view)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        view.session.run(configuration)
        return view
    }

    func updateUIView(_ view: ARSCNView, context: Context) {}

    static func dismantleUIView(_ view: ARSCNView, coordinator: ()) {
        view.session.pause()
    }
}
