import Foundation
import Combine
import ARKit
import SceneKit
import UIKit

@MainActor
final class BalloonGameController: NSObject, ObservableObject {
    @Published private(set) var status = "LOOK AROUND TO FIND FLOORS AND WALLS"
    @Published private(set) var hits = 0

    private weak var view: ARSCNView?
    private var planes: [UUID: SCNNode] = [:]
    private var projectiles: [SCNNode] = []
    private var blocks: [SCNNode] = []
    private var activeBalloons = Set<ObjectIdentifier>()

    private enum Mask {
        static let balloon = 1 << 0
        static let surface = 1 << 1
        static let block = 1 << 2
    }

    func attach(_ view: ARSCNView) {
        self.view = view
    }

    func throwBalloon() {
        guard let view, let frame = view.session.currentFrame else {
            status = "WAIT FOR CAMERA TRACKING"
            return
        }
        guard frame.camera.trackingState.isNormal else {
            status = "MOVE PHONE SLOWLY TO RESUME TRACKING"
            return
        }

        let camera = frame.camera.transform
        let forward = SIMD3<Float>(-camera.columns.2.x, -camera.columns.2.y, -camera.columns.2.z)
        let start = SIMD3<Float>(camera.columns.3.x, camera.columns.3.y, camera.columns.3.z) + forward * 0.24
        let radius: CGFloat = 0.075
        let balloon = SCNNode(geometry: SCNSphere(radius: radius))
        balloon.name = "water-balloon"
        balloon.geometry?.firstMaterial?.diffuse.contents = UIColor(
            red: 0.12, green: 0.78, blue: 0.98, alpha: 0.82
        )
        balloon.geometry?.firstMaterial?.lightingModel = .physicallyBased
        balloon.geometry?.firstMaterial?.roughness.contents = 0.18
        balloon.geometry?.firstMaterial?.metalness.contents = 0.02
        balloon.simdPosition = start

        let body = SCNPhysicsBody(type: .dynamic,
                                  shape: SCNPhysicsShape(geometry: SCNSphere(radius: radius),
                                                         options: nil))
        body.mass = 0.16
        body.isAffectedByGravity = true
        body.categoryBitMask = Mask.balloon
        body.collisionBitMask = Mask.surface | Mask.block
        body.contactTestBitMask = Mask.surface | Mask.block
        body.damping = 0.06
        body.restitution = 0
        balloon.physicsBody = body
        view.scene.rootNode.addChildNode(balloon)

        // Forward throw with a slight lift, without any GPS or map dependence.
        balloon.physicsBody?.velocity = SCNVector3(
            forward.x * 6.0, forward.y * 6.0 + 1.0, forward.z * 6.0
        )
        projectiles.append(balloon)
        activeBalloons.insert(ObjectIdentifier(balloon))
        status = "BALLOON AWAY"
        if projectiles.count > 24, let oldest = projectiles.first {
            expire(oldest)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) { [weak self, weak balloon] in
            guard let self, let balloon else { return }
            self.expire(balloon)
        }
    }

    func placeBlocks() {
        guard let view else { return }
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        let results = view.raycastQuery(from: center,
                                        allowing: .existingPlaneGeometry,
                                        alignment: .horizontal)
        guard let query = results,
              let hit = view.session.raycast(query).first else {
            status = "AIM AT A DETECTED FLOOR, THEN TAP BLOCKS"
            return
        }
        clearBlocks()
        let matrix = hit.worldTransform
        let origin = SIMD3<Float>(matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z)
        let size: Float = 0.18
        for level in 0..<3 {
            for column in 0..<3 {
                let block = SCNNode(geometry: SCNBox(width: CGFloat(size),
                                                     height: CGFloat(size),
                                                     length: CGFloat(size),
                                                     chamferRadius: 0.008))
                block.name = "stack-block"
                block.geometry?.firstMaterial?.diffuse.contents =
                    UIColor(red: 0.94, green: CGFloat(0.76 + Double(level) * 0.04),
                            blue: 0.50, alpha: 1)
                block.geometry?.firstMaterial?.roughness.contents = 0.7
                block.simdPosition = origin + SIMD3<Float>(
                    (Float(column) - 1) * (size + 0.008),
                    Float(level) * (size + 0.004) + size / 2 + 0.014,
                    0
                )
                let body = SCNPhysicsBody(type: .dynamic, shape: nil)
                body.mass = 0.13
                body.friction = 0.85
                body.restitution = 0.03
                body.categoryBitMask = Mask.block
                body.collisionBitMask = Mask.surface | Mask.block | Mask.balloon
                body.contactTestBitMask = Mask.balloon
                block.physicsBody = body
                view.scene.rootNode.addChildNode(block)
                blocks.append(block)
            }
        }
        status = "THROW AT THE STACK"
    }

    func reset() {
        for balloon in projectiles { balloon.removeFromParentNode() }
        projectiles.removeAll()
        activeBalloons.removeAll()
        clearBlocks()
        hits = 0
        status = "READY — THROW OR PLACE BLOCKS"
    }

    private func clearBlocks() {
        for block in blocks { block.removeFromParentNode() }
        blocks.removeAll()
    }

    private func expire(_ node: SCNNode) {
        activeBalloons.remove(ObjectIdentifier(node))
        projectiles.removeAll { $0 === node }
        node.removeFromParentNode()
    }

    private func splash(at point: SCNVector3) {
        guard let view else { return }
        let node = SCNNode()
        node.position = point
        let particles = SCNParticleSystem()
        particles.birthRate = 450
        particles.emissionDuration = 0.10
        particles.loops = false
        particles.particleLifeSpan = 0.48
        particles.particleLifeSpanVariation = 0.22
        particles.particleSize = 0.025
        particles.particleSizeVariation = 0.014
        particles.particleVelocity = 2.2
        particles.particleVelocityVariation = 1.0
        particles.spreadingAngle = 180
        particles.acceleration = SCNVector3(0, -5, 0)
        particles.particleColor = UIColor(red: 0.14, green: 0.75, blue: 1, alpha: 0.9)
        particles.emitterShape = SCNSphere(radius: 0.035)
        particles.blendMode = .alpha
        node.addParticleSystem(particles)
        view.scene.rootNode.addChildNode(node)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            node.removeFromParentNode()
        }
    }
}

extension BalloonGameController: ARSCNViewDelegate {
    nonisolated func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let plane = anchor as? ARPlaneAnchor else { return }
        Task { @MainActor [weak self] in self?.configurePlane(node, anchor: plane) }
    }

    nonisolated func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = anchor as? ARPlaneAnchor else { return }
        Task { @MainActor [weak self] in self?.configurePlane(node, anchor: plane) }
    }

    nonisolated func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        Task { @MainActor [weak self] in self?.planes.removeValue(forKey: anchor.identifier)?.removeFromParentNode() }
    }

    private func configurePlane(_ anchorNode: SCNNode, anchor: ARPlaneAnchor) {
        let horizontal = anchor.alignment == .horizontal
        let width = max(0.08, CGFloat(anchor.extent.x))
        let height = max(0.08, CGFloat(horizontal ? anchor.extent.z : anchor.extent.y))
        let box = SCNBox(width: width,
                         height: horizontal ? 0.018 : height,
                         length: horizontal ? height : 0.018,
                         chamferRadius: 0)
        let planeNode: SCNNode
        if let existing = planes[anchor.identifier] {
            planeNode = existing
            planeNode.geometry = box
        } else {
            planeNode = SCNNode(geometry: box)
            planeNode.name = "detected-surface"
            planes[anchor.identifier] = planeNode
            anchorNode.addChildNode(planeNode)
        }
        planeNode.position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
        box.firstMaterial?.diffuse.contents = UIColor.clear
        box.firstMaterial?.writesToDepthBuffer = false
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
        planeNode.physicsBody?.categoryBitMask = Mask.surface
        planeNode.physicsBody?.collisionBitMask = Mask.balloon | Mask.block
        planeNode.physicsBody?.contactTestBitMask = Mask.balloon
        if status.hasPrefix("LOOK AROUND") {
            status = "SURFACE FOUND — READY TO THROW"
        }
    }
}

extension BalloonGameController: SCNPhysicsContactDelegate {
    nonisolated func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let a = contact.nodeA
        let b = contact.nodeB
        let point = contact.contactPoint
        Task { @MainActor [weak self] in
            guard let self else { return }
            let balloon = a.name == "water-balloon" ? a : (b.name == "water-balloon" ? b : nil)
            guard let balloon, self.activeBalloons.contains(ObjectIdentifier(balloon)) else { return }
            let other = a === balloon ? b : a
            guard other.name == "detected-surface" || other.name == "stack-block" else { return }
            self.activeBalloons.remove(ObjectIdentifier(balloon))
            if other.name == "stack-block" { self.hits += 1; self.status = "DIRECT HIT" }
            else { self.status = "SPLASH" }
            self.splash(at: point)
            self.expire(balloon)
        }
    }
}
