# Layr — Water Balloon AR Lab

A standalone **native iPhone AR prototype**. No GPS, location permission, map, backend, or geospatial anchors.

## Experience

- Point your phone at a real floor or textured wall while ARKit detects horizontal and vertical planes.
- Tap the blue drop button to throw a small, gravity-driven water balloon from the camera.
- It splashes on collision with a detected plane or a physics block.
- Aim at a detected **floor** and tap **BLOCKS** to create a 3 × 3 stack of nine rigid-body blocks; knock them down with balloons.
- **RESET** removes balloons and blocks. You can keep throwing from wherever you walk.
- Splashes are deliberately short-lived particles, **not full fluid simulation**, to keep the GPU/CPU load modest.

## Build on an iPhone

1. On a Mac, install [Xcode](https://developer.apple.com/xcode/) and [XcodeGen](https://github.com/yonaskolb/XcodeGen).
2. From this directory run `xcodegen generate` to create `WaterBalloonAR.xcodeproj`.
3. Open the generated project in Xcode, choose your Apple developer team for signing, connect a physical ARKit-capable iPhone running iOS 16+, and Run.
4. Grant camera permission. Walk around slowly until ARKit finds a floor or wall. Test throws and the blocks.

**An iPhone is required**: the iOS simulator cannot run world-tracked camera AR. This is not an iPhone Safari/Quick Look experience; it is native ARKit + SceneKit.

## Technical notes and limitations

- Surface collision uses ARKit plane anchors converted to invisible static SceneKit physics bodies. An undetected wall or floor will not register impact. Large featureless walls can take longer to detect.
- Physics balls and blocks use SceneKit rigid-body dynamics; splashes are a lightweight particle illusion rather than computed water deformation.
- There is no persistent world map across sessions; relaunching starts a new scan.
- Water effects are visual only; there are no wet decals or physically accurate fluid droplets.
- This prototype was written and source-reviewed here, but **has not been compiled with Xcode or tested on a physical iPhone**. Adjust API compatibility and signing as needed in Xcode.
- This is isolated under `ios/WaterBalloonAR`; it does not modify the current Layr web app.
